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
    required this.commissionSlowUsd,
    required this.commissionMediumUsd,
    required this.commissionFastUsd,
    required this.adminCommissionExemption,
    required this.minAppVersion,
    required this.coins,
    required this.nodes,
    required this.announcements,
  });

  final String name;
  final bool globalEnabled;
  final double commissionSlowUsd;
  final double commissionMediumUsd;
  final double commissionFastUsd;
  final bool adminCommissionExemption;
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
      commissionSlowUsd: (json['commissionSlowUsd'] as num?)?.toDouble() ?? 0.10,
      commissionMediumUsd:
          (json['commissionMediumUsd'] as num?)?.toDouble() ?? 0.25,
      commissionFastUsd: (json['commissionFastUsd'] as num?)?.toDouble() ?? 0.50,
      adminCommissionExemption:
          json['adminCommissionExemption'] as bool? ?? true,
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

  /// ⚙️ CONFIGURACIÓN PRIVADA DEL CEREBRO
  /// Pega aquí la URL de tu servidor Cerebro y la API key.
  /// Estos valores quedan grabados en el código fuente: el usuario
  /// nunca los ve ni los puede modificar.
  static const String kCerebroServerUrl = '';
  static const String kCerebroApiKey = '';

  final SharedPreferences _prefs;
  Timer? _timer;

  CerebroConfig? config;
  bool connected = false;
  String? error;
  DateTime? lastSync;

  String get serverUrl =>
      _prefs.getString(PreferencesKey.cerebroServerUrl) ?? kCerebroServerUrl;
  String get apiKey => _prefs.getString(PreferencesKey.cerebroApiKey) ?? kCerebroApiKey;
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

  bool get adminCommissionExemption {
    if (connected && config != null) return config!.adminCommissionExemption;
    final cached = _cachedConfig;
    return cached?.adminCommissionExemption ?? true;
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

  bool get hasReceivedConfig => config != null || _cachedConfig != null;

  List<Map<String, dynamic>> get activeAnnouncements {
    final source = (connected && config != null) ? config! : _cachedConfig;
    return source?.announcements ?? const [];
  }

  ({double slowUsd, double mediumUsd, double fastUsd, String address})?
      commissionInfoFor(String symbol) {
    final source = (connected && config != null) ? config! : _cachedConfig;
    if (source == null) return null;

    final coin = source.coins[symbol];
    if (coin == null) return null;
    if (!(coin['enabled'] as bool? ?? true)) return null;

    final address = ((coin['feeAddress'] as String?) ?? '').trim();
    if (address.isEmpty) return null;

    // Montos fijos en USD por modo de envío. Sin conexión se usan los
    // últimos valores guardados en la caché (nunca se inventa un precio).
    return (
      slowUsd: source.commissionSlowUsd,
      mediumUsd: source.commissionMediumUsd,
      fastUsd: source.commissionFastUsd,
      address: address,
    );
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
