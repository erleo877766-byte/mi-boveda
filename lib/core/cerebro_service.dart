import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/core/cerebro_node_sync.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class CerebroConfig {
  CerebroConfig({
    required this.name,
    required this.globalEnabled,
    required this.commissionSlowUsd,
    required this.commissionMediumUsd,
    required this.commissionFastUsd,
    required this.commissionPercent,
    required this.commissionBySpeed,
    required this.adminCommissionExemption,
    required this.minAppVersion,
    required this.coins,
    required this.customTokens,
    required this.nodes,
    required this.announcements,
    required this.erleoExchangeEnabled,
    required this.downloads,
  });

  final String name;
  final bool globalEnabled;
  final double commissionSlowUsd;
  final double commissionMediumUsd;
  final double commissionFastUsd;
  final double commissionPercent;
  final Map<String, double> commissionBySpeed;
  final bool adminCommissionExemption;
  final String minAppVersion;
  final Map<String, Map<String, dynamic>> coins;
  final List<Map<String, dynamic>> customTokens;
  final List<CerebroNode> nodes;
  final List<Map<String, dynamic>> announcements;
  final bool erleoExchangeEnabled;
  final Map<String, dynamic> downloads;

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
      commissionMediumUsd: (json['commissionMediumUsd'] as num?)?.toDouble() ?? 0.25,
      commissionFastUsd: (json['commissionFastUsd'] as num?)?.toDouble() ?? 0.75,
      commissionPercent: (json['commissionPercent'] as num?)?.toDouble() ?? 1.0,
      commissionBySpeed: _parseCommissionBySpeed(json['commissionBySpeed']),
      adminCommissionExemption: json['adminCommissionExemption'] as bool? ?? true,
      minAppVersion: json['minAppVersion']?.toString() ?? '',
      coins: coins,
      customTokens: json['customTokens'] is List
          ? (json['customTokens'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[],
      nodes: json['nodes'] is List
          ? (json['nodes'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => CerebroNode.fromJson(e))
              .toList()
          : <CerebroNode>[],
      announcements: json['announcements'] is List
          ? (json['announcements'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[],
      erleoExchangeEnabled: json['erleoExchangeEnabled'] as bool? ?? false,
      downloads: json['downloads'] is Map
          ? Map<String, dynamic>.from(json['downloads'] as Map)
          : <String, dynamic>{},
    );
  }
  static Map<String, double> _parseCommissionBySpeed(dynamic raw) {
    final out = <String, double>{};
    if (raw is Map) {
      for (final key in ['global', 'slow', 'medium', 'fast']) {
        final v = raw[key];
        if (v is num) out[key] = v.toDouble();
      }
    }
    return out;
  }
}

class CerebroService extends ChangeNotifier {
  CerebroService(this._prefs, this._secureStorage);

  /// ⚙️ CONFIGURACIÓN PRIVADA DEL CEREBRO
  /// URL y API key por defecto del Cerebro en la nube (Render). Se usan cuando
  /// el usuario no configuró nada: la app conecta sola, sin campos visibles.
  static const String kCerebroServerUrl = 'https://miboveda-cerebro.onrender.com';
  static const String kCerebroApiKey = '20877766';

  final SharedPreferences _prefs;
  final SecureStorage _secureStorage;
  Timer? _timer;

  CerebroConfig? config;
  bool connected = false;
  String? error;
  DateTime? lastSync;

  String get serverUrl => _prefs.getString(PreferencesKey.cerebroServerUrl) ?? kCerebroServerUrl;

  String _apiKey = '';

  /// La API key se guarda en flutter_secure_storage (nunca en SharedPreferences).
  String get apiKey => _apiKey;

  // Token de dispositivo: reemplaza la API key estática en requests.
  // Se registra una vez con el servidor y se renueva cada 90 días.
  String _deviceToken = '';
  String get deviceToken => _deviceToken;

  Future<void> loadApiKey() async {
    _apiKey = await _secureStorage.read(key: PreferencesKey.cerebroApiKey) ?? kCerebroApiKey;
    _deviceToken = await _secureStorage.read(key: 'cerebro_device_token') ?? '';
  }

  Future<void> setApiKey(String value) async {
    _apiKey = value;
    await _secureStorage.write(key: PreferencesKey.cerebroApiKey, value: value);
  }

  Future<void> removeApiKey() async {
    _apiKey = '';
    await _secureStorage.delete(key: PreferencesKey.cerebroApiKey);
  }

  bool get isConfigured => serverUrl.isNotEmpty;

  /// ¿El servidor permite intercambios propios por debajo del mínimo?
  bool get erleoExchangeEnabled {
    if (connected && config != null) return config!.erleoExchangeEnabled;
    final cached = _cachedConfig;
    return cached?.erleoExchangeEnabled ?? false;
  }

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

  // ============================================================
  // Actualización de la app (versión disponible + enlaces)
  // ============================================================
  Map<String, dynamic> get _downloads {
    if (connected && config != null) return config!.downloads;
    final cached = _cachedConfig;
    return cached?.downloads ?? const {};
  }

  String? get latestVersion {
    final v = (_downloads['version'] as String?)?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  String? get apkUrl {
    final v = (_downloads['apkUrl'] as String?)?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  String? get apkMirrorUrl {
    final v = (_downloads['apkMirrorUrl'] as String?)?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  String? get exeUrl {
    final v = (_downloads['exeUrl'] as String?)?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  String? get exeMirrorUrl {
    final v = (_downloads['exeMirrorUrl'] as String?)?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => poll());
    loadApiKey().then((_) {
      _ensureDeviceToken();
      poll();
    });
  }

  /// Registra este dispositivo con el servidor si no tiene token.
  Future<void> _ensureDeviceToken() async {
    if (_deviceToken.isNotEmpty || _apiKey.isEmpty) return;
    try {
      final base = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
      final uri = Uri.parse('${base}api/v1/auth/device');
      String deviceName = 'unknown';
      try {
        if (Platform.isAndroid) {
          final info = await DeviceInfoPlugin().androidInfo;
          deviceName = '${info.manufacturer} ${info.model}';
        } else if (Platform.isIOS) {
          final info = await DeviceInfoPlugin().iosInfo;
          deviceName = '${info.name} ${info.model}';
        } else if (Platform.isWindows) {
          deviceName = 'Windows Desktop';
        }
      } catch (_) {}
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey,
            },
            body: jsonEncode({
              'deviceName': deviceName,
              'deviceFingerprint': await _getDeviceFingerprint(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 201) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _deviceToken = json['token'] as String? ?? '';
        if (_deviceToken.isNotEmpty) {
          await _secureStorage.write(key: 'cerebro_device_token', value: _deviceToken);
          printV('Cerebro: device token registrado');
        }
      }
    } catch (e) {
      printV('Cerebro: device registration failed: $e');
    }
  }

  Future<String> _getDeviceFingerprint() async {
    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        return info.fingerprint;
      } else if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        return info.identifierForVendor ?? '';
      }
    } catch (_) {}
    return '';
  }

  /// Headers de autenticación: usa device token si está disponible,
  /// sino usa la API key estática (backward compatible).
  Map<String, String> get _authHeaders => {
        if (_deviceToken.isNotEmpty)
          'x-device-token': _deviceToken
        else if (_apiKey.isNotEmpty)
          'x-api-key': _apiKey,
      };

  Future<void> poll() async {
    if (!isConfigured) {
      connected = false;
      error = null;
      return;
    }
    try {
      final base = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
      final uri = Uri.parse('${base}api/v1/config');
      final res = await http.get(uri, headers: _authHeaders).timeout(const Duration(seconds: 20));
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
      unawaited(_checkNotifications());
    } catch (e) {
      connected = false;
      error = e is FormatException
          ? 'Formato de respuesta inválido'
          : e is TypeError
              ? 'Error al interpretar la configuración del servidor'
              : e.toString();
      notifyListeners();
    }
  }

  /// Fuerza una sincronización inmediata con el servidor, ignorando el timer.
  /// Devuelve true si quedó conectado y con la configuración disponible.
  Future<bool> refreshNow() async {
    await poll();
    return connected && config != null;
  }

  String feeAddressFor(String symbol) => config?.coins[symbol]?['feeAddress'] as String? ?? '';

  /// Se invoca con cada notificación nueva que llega del Cerebro.
  void Function(String title, String body)? onNotification;

  Future<void> _checkNotifications() async {
    if (!isConfigured) return;
    try {
      final lastId = _prefs.getInt(PreferencesKey.cerebroLastNotificationId) ?? 0;
      final base = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
      final uri = Uri.parse('${base}api/v1/notifications?after=$lastId');
      final res = await http.get(uri, headers: _authHeaders).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final list =
          (json['notifications'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
      if (list.isEmpty) return;
      var newestId = lastId;
      for (final item in list) {
        final id = (item['id'] as num?)?.toInt() ?? 0;
        if (id > newestId) newestId = id;
        final title = (item['title'] as String?)?.trim() ?? 'Mi Bóveda';
        final body = (item['body'] as String?)?.trim() ?? '';
        onNotification?.call(title, body);
      }
      await _prefs.setInt(PreferencesKey.cerebroLastNotificationId, newestId);
    } catch (e) {
      printV('CerebroNotifications check failed: $e');
    }
  }

  // ============================================================
  // Intercambios propios (Erleo): ordenes por debajo del mínimo
  // ============================================================

  /// Envía una orden de intercambio pequeño al Cerebro.
  /// Devuelve el id de la orden creada. Lanza excepción si falla.
  Future<String> submitErleoOrder({
    required String fromSymbol,
    required String fromNetwork,
    required double fromAmount,
    required String toSymbol,
    required String toNetwork,
    required String toAddress,
    required String toExtraId,
    required String speed,
    required double estReceive,
    String userLabel = '',
  }) async {
    final base = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
    final uri = Uri.parse('${base}api/v1/orders');
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            ..._authHeaders,
          },
          body: jsonEncode({
            'fromSymbol': fromSymbol,
            'fromNetwork': fromNetwork,
            'fromAmount': fromAmount,
            'toSymbol': toSymbol,
            'toNetwork': toNetwork,
            'toAddress': toAddress,
            'toExtraId': toExtraId,
            'speed': speed,
            'estReceive': estReceive,
            'userLabel': userLabel,
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Cerebro: HTTP ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) throw Exception('Cerebro: orden sin id');
    return id;
  }

  /// Verifica en el Cerebro si hay liquidez suficiente para un intercambio.
  /// Devuelve un mapa con { sufficient, available, required, enabled, error? }.
  Future<Map<String, dynamic>> checkCerebroLiquidity({
    required String toSymbol,
    required double toAmount,
    String toNetwork = '',
  }) async {
    final base = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
    final uri = Uri.parse('${base}api/v1/orders/check-liquidity');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json', ..._authHeaders},
          body: jsonEncode({
            'toSymbol': toSymbol,
            'toAmount': toAmount,
            'toNetwork': toNetwork,
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Cerebro: liquidez HTTP ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Consulta el estado de una orden Erleo. Devuelve un mapa con el JSON
  /// completo o lanza excepción.
  Future<Map<String, dynamic>> fetchErleoOrder(String orderId) async {
    final base = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
    final uri = Uri.parse('${base}api/v1/orders/$orderId');
    final res = await http.get(uri, headers: _authHeaders).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('Cerebro: HTTP ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// ¿El servidor soporta el flujo de órdenes por debajo del mínimo?
  bool get canSubmitErleoOrders => isConfigured && apiKey.isNotEmpty;

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

  /// Tokens EVM/TRC20 personalizados que el admin registró en el Cerebro.
  /// La app los agrega automáticamente a la billetera de la red que corresponda.
  List<Map<String, dynamic>> get customTokens {
    final source = (connected && config != null) ? config! : _cachedConfig;
    return source?.customTokens ?? const [];
  }

  // ============================================================
  // Bloqueo de monedas durante un intercambio propio (Erleo)
  // ============================================================
  // Mientras una orden está pendiente (sin confirmar por el admin), la moneda
  // origen queda bloqueada para que el usuario no la gaste dos veces. Se
  // desbloquea al confirmar (approved/completed) o al cancelar/fallar.
  final Map<String, double> _lockedBySymbol = {};

  double lockedAmountFor(String symbol) => _lockedBySymbol[symbol.toUpperCase()] ?? 0;

  bool hasLockedCoins() => _lockedBySymbol.isNotEmpty;

  void lockCoin(String symbol, double amount) {
    final key = symbol.toUpperCase();
    if (amount <= 0) return;
    _lockedBySymbol[key] = (lockedAmountFor(key) + amount);
    notifyListeners();
  }

  void unlockCoin(String symbol, double amount) {
    final key = symbol.toUpperCase();
    final remaining = (_lockedBySymbol[key] ?? 0) - amount;
    if (remaining <= 0.000000001) {
      _lockedBySymbol.remove(key);
    } else {
      _lockedBySymbol[key] = remaining;
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> get activeAnnouncements {
    final source = (connected && config != null) ? config! : _cachedConfig;
    return source?.announcements ?? const [];
  }

  ({double slowUsd, double mediumUsd, double fastUsd, double percent, String address})?
      commissionInfoFor(String symbol) {
    final source = (connected && config != null) ? config! : _cachedConfig;
    if (source == null) return null;

    final coin = source.coins[symbol];
    if (coin == null) return null;
    if (!(coin['enabled'] as bool? ?? true)) return null;

    final address = ((coin['feeAddress'] as String?) ?? '').trim();
    if (address.isEmpty) return null;

    return (
      slowUsd: source.commissionSlowUsd,
      mediumUsd: source.commissionMediumUsd,
      fastUsd: source.commissionFastUsd,
      percent: source.commissionPercent,
      address: address,
    );
  }

  /// Porcentaje de comisión que cobra el admin por cada intercambio.
  double get commissionPercent {
    final source = (connected && config != null) ? config! : _cachedConfig;
    return source?.commissionPercent ?? 1.0;
  }

  /// Porcentaje de comisión del reparto Lento/Normal/Rápido (del Cerebro).
  /// clave: 'slow' | 'medium' | 'fast'. Fallback al reparto 50/75/100 del global.
  double commissionPercentFor(String speed) {
    final source = (connected && config != null) ? config! : _cachedConfig;
    if (source != null && source.commissionBySpeed.containsKey(speed)) {
      return source.commissionBySpeed[speed]!;
    }
    final global = source?.commissionPercent ?? 1.0;
    switch (speed) {
      case 'slow':
        return global * 0.5;
      case 'fast':
        return global * 1.0;
      default:
        return global * 0.75;
    }
  }

  /// Comisión fija (USD) para la velocidad lenta.
  double get commissionSlowUsd {
    final source = (connected && config != null) ? config! : _cachedConfig;
    return source?.commissionSlowUsd ?? 0.10;
  }

  /// Comisión fija (USD) para la velocidad normal.
  double get commissionMediumUsd {
    final source = (connected && config != null) ? config! : _cachedConfig;
    return source?.commissionMediumUsd ?? 0.25;
  }

  /// Comisión fija (USD) para la velocidad rápida.
  double get commissionFastUsd {
    final source = (connected && config != null) ? config! : _cachedConfig;
    return source?.commissionFastUsd ?? 0.75;
  }

  /// Neto estimado a recibir tras descontar la comisión % del admin.
  double erleoNetEstimate(double estReceive) {
    final pct = commissionPercent;
    if (pct <= 0) return estReceive;
    return estReceive * (1 - pct / 100);
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
