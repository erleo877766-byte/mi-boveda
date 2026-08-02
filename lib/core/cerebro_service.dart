import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/core/cerebro_node_sync.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CerebroConfig {
  CerebroConfig({
    required this.name,
    required this.globalEnabled,
    required this.fallbackFeePercent,
    required this.minCommissionPercent,
    required this.minAppVersion,
    required this.coins,
    required this.nodes,
    required this.announcements,
  });

  final String name;
  final bool globalEnabled;
  final double fallbackFeePercent;
  final double minCommissionPercent;
  final String minAppVersion;
  final Map<String, Map<String, dynamic>> coins;
  final List<CerebroNode> nodes;
  final List<Map<String, dynamic>> announcements;

  factory CerebroConfig.fromJson(Map<String, dynamic> json) {
    final coinsRaw = json['coins'] as Map<String, dynamic>? ?? const {};
    final coins = <String, Map<String, dynamic>>{};
    coinsRaw.forEach((key, value) {
      coins[key] = Map<String, dynamic>.from(value as Map);
    });
    return CerebroConfig(
      name: json['name'] as String? ?? 'Mi Bóveda Cerebro',
      globalEnabled: json['globalEnabled'] as bool? ?? true,
      fallbackFeePercent: (json['fallbackFeePercent'] as num?)?.toDouble() ?? 0.5,
      minCommissionPercent:
          (json['minCommissionPercent'] as num?)?.toDouble() ?? 0.5,
      minAppVersion: json['minAppVersion'] as String? ?? '',
      coins: coins,
      nodes: (json['nodes'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => CerebroNode.fromJson(e))
          .toList(),
      announcements: (json['announcements'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }
}

class CerebroService extends ChangeNotifier {
  CerebroService(this._prefs);

  final SharedPreferences _prefs;
  Timer? _timer;

  CerebroConfig? config;
  bool connected = false;
  String? error;
  DateTime? lastSync;

  String get serverUrl => _prefs.getString(PreferencesKey.cerebroServerUrl) ?? '';
  String get apiKey => _prefs.getString(PreferencesKey.cerebroApiKey) ?? '';
  bool get isConfigured => serverUrl.isNotEmpty;

  bool get killSwitchActive {
    if (connected && config != null && !config!.globalEnabled) return true;
    final cached = _cachedConfig;
    return cached != null && !cached.globalEnabled;
  }

  String get syncStatus => connected ? 'online' : (error != null ? 'error' : 'off');

  String get minAppVersion {
    if (connected && config != null && config!.minAppVersion.isNotEmpty) {
      return config!.minAppVersion;
    }
    final cached = _cachedConfig;
    if (cached != null && cached.minAppVersion.isNotEmpty) {
      return cached.minAppVersion;
    }
    return '';
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => poll());
    poll();
  }

  Future<void> poll() async {
    if (!isConfigured) {
      connected = false;
      error = null;
      return;
    }
    try {
      final base = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
      final uri = Uri.parse('${base}api/v1/config');
      final res = await http.get(uri, headers: {
        if (apiKey.isNotEmpty) 'x-api-key': apiKey,
      }).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        connected = false;
        error = 'HTTP ${res.statusCode}';
        notifyListeners();
        return;
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      config = CerebroConfig.fromJson(json);
      connected = true;
      error = null;
      lastSync = DateTime.now();
      await persistCerebroConfig(res.body);
      await syncBuiltinNodesFromCerebro(config!.nodes);
      notifyListeners();
    } catch (e) {
      connected = false;
      error = e.toString();
      notifyListeners();
    }
  }

  double? feePercentFor(String symbol) {
    final coin = config?.coins[symbol];
    if (coin == null) return null;
    return (coin['feePercent'] as num?)?.toDouble() ?? 0;
  }

  String feeAddressFor(String symbol) =>
      config?.coins[symbol]?['feeAddress'] as String? ?? '';

  bool isCoinEnabled(String symbol) {
    if (connected && config != null) {
      return config!.coins[symbol]?['enabled'] as bool? ?? true;
    }
    final cached = _cachedConfig;
    if (cached != null) {
      return cached.coins[symbol]?['enabled'] as bool? ?? true;
    }
    return true;
  }

  bool coinHasCommission(String symbol) {
    if (!connected || config == null || !config!.globalEnabled) return false;
    final percent = feePercentFor(symbol);
    final address = feeAddressFor(symbol);
    return percent != null && percent > 0 && address.isNotEmpty;
  }

  List<Map<String, dynamic>> get activeAnnouncements {
    final source = (connected && config != null) ? config! : _cachedConfig;
    return source?.announcements ?? const [];
  }

  ({double percent, String address})? _commissionFor(Map<String, dynamic>? coin) {
    if (coin == null) return null;
    final percent = (coin['feePercent'] as num?)?.toDouble() ?? 0;
    final address = coin['feeAddress'] as String? ?? '';
    if (percent <= 0 || address.isEmpty) return null;
    return (percent: percent, address: address);
  }

  ({double percent, String address})? commissionInfoFor(String symbol) {
    if (connected && config != null) {
      return _commissionFor(config!.coins[symbol]);
    }
    if (!isConfigured) return null;
    final cached = _cachedConfig;
    if (cached != null) {
      return _commissionFor(cached.coins[symbol]);
    }
    return null;
  }

  CerebroConfig? get _cachedConfig {
    final raw = _prefs.getString(PreferencesKey.cerebroLastConfig);
    if (raw == null || raw.isEmpty) return null;
    try {
      return CerebroConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
