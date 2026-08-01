import 'dart:convert';

import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CerebroNode {
  CerebroNode({
    required this.name,
    required this.uri,
    required this.symbol,
    required this.useSsl,
    required this.trusted,
    required this.isOfficial,
    required this.isDefault,
    required this.autoSwitch,
  });

  final String name;
  final String uri;
  final String symbol;
  final bool useSsl;
  final bool trusted;
  final bool isOfficial;
  final bool isDefault;
  final bool autoSwitch;

  factory CerebroNode.fromJson(Map<String, dynamic> json) => CerebroNode(
        name: json['name'] as String? ?? '',
        uri: json['uri'] as String? ?? '',
        symbol: json['symbol'] as String? ?? '',
        useSsl: json['useSsl'] as bool? ?? true,
        trusted: json['trusted'] as bool? ?? false,
        isOfficial: json['isOfficial'] as bool? ?? false,
        isDefault: json['isDefault'] as bool? ?? false,
        autoSwitch: json['autoSwitch'] as bool? ?? false,
      );
}

WalletType? cerebroSymbolToWalletType(String symbol) {
  switch (symbol) {
    case 'XMR':
      return WalletType.monero;
    case 'BTC':
      return WalletType.bitcoin;
    case 'LTC':
      return WalletType.litecoin;
    case 'XHV':
      return WalletType.haven;
    case 'ETH':
      return WalletType.ethereum;
    case 'BCH':
      return WalletType.bitcoinCash;
    case 'XNO':
      return WalletType.nano;
    case 'BAN':
      return WalletType.banano;
    case 'POL':
      return WalletType.polygon;
    case 'SOL':
      return WalletType.solana;
    case 'TRX':
      return WalletType.tron;
    case 'WOW':
      return WalletType.wownero;
    case 'ZANO':
      return WalletType.zano;
    case 'DCR':
      return WalletType.decred;
    case 'DOGE':
      return WalletType.dogecoin;
    case 'BASE':
      return WalletType.base;
    case 'ARB':
      return WalletType.arbitrum;
    case 'ZEC':
      return WalletType.zcash;
    case 'BNB':
      return WalletType.bsc;
    default:
      return null;
  }
}

String? walletTypeToCerebroSymbol(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return 'XMR';
    case WalletType.bitcoin:
      return 'BTC';
    case WalletType.litecoin:
      return 'LTC';
    case WalletType.haven:
      return 'XHV';
    case WalletType.ethereum:
      return 'ETH';
    case WalletType.bitcoinCash:
      return 'BCH';
    case WalletType.nano:
      return 'XNO';
    case WalletType.banano:
      return 'BAN';
    case WalletType.polygon:
      return 'POL';
    case WalletType.solana:
      return 'SOL';
    case WalletType.tron:
      return 'TRX';
    case WalletType.wownero:
      return 'WOW';
    case WalletType.zano:
      return 'ZANO';
    case WalletType.decred:
      return 'DCR';
    case WalletType.dogecoin:
      return 'DOGE';
    case WalletType.base:
      return 'BASE';
    case WalletType.arbitrum:
      return 'ARB';
    case WalletType.zcash:
      return 'ZEC';
    case WalletType.bsc:
      return 'BNB';
    default:
      return null;
  }
}

Future<void> syncBuiltinNodesFromCerebro(List<CerebroNode> nodes) async {
  final byType = <WalletType, List<CerebroNode>>{};
  for (final node in nodes) {
    final type = cerebroSymbolToWalletType(node.symbol);
    if (type == null) continue;
    byType.putIfAbsent(type, () => []).add(node);
  }

  for (final entry in byType.entries) {
    final type = entry.key;
    final desired = entry.value;
    final desiredByUri = {for (final n in desired) n.uri: n};

    final existing = await Node.getAllForWalletType(type);

    for (final dbNode in existing) {
      if (!dbNode.isBuiltin) continue;
      final match = desiredByUri[dbNode.uriRaw];
      if (match == null) {
        await dbNode.delete();
      } else {
        dbNode.label = match.name.isEmpty ? null : match.name;
        dbNode.useSSL = match.useSsl;
        dbNode.trusted = match.trusted;
        dbNode.isOfficial = match.isOfficial;
        dbNode.isDefault = match.isDefault;
        dbNode.isEnabledForAutoSwitching = match.autoSwitch;
        dbNode.isBuiltin = true;
        await dbNode.save();
      }
    }

    final existingUris = existing.map((e) => e.uriRaw).toSet();
    for (final node in desired) {
      if (existingUris.contains(node.uri)) continue;
      await Node(
        label: node.name.isEmpty ? null : node.name,
        uri: node.uri,
        type: type,
        useSSL: node.useSsl,
        trusted: node.trusted,
        isOfficial: node.isOfficial,
        isDefault: node.isDefault,
        isBuiltin: true,
        isEnabledForAutoSwitching: node.autoSwitch,
      ).save();
    }
  }
}

Future<List<CerebroNode>?> cerebroNodesFromCache() async {
  final prefs = await SharedPreferences.getInstance();
  final url = prefs.getString(PreferencesKey.cerebroServerUrl) ?? '';
  final raw = prefs.getString(PreferencesKey.cerebroLastConfig);
  if (url.isEmpty || raw == null || raw.isEmpty) return null;
  try {
    final config = jsonDecode(raw) as Map<String, dynamic>;
    final nodesRaw = config['nodes'] as List? ?? [];
    return nodesRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => CerebroNode.fromJson(e))
        .toList();
  } catch (_) {
    return null;
  }
}

Future<void> persistCerebroConfig(String jsonBody) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(PreferencesKey.cerebroLastConfig, jsonBody);
  await prefs.setString(PreferencesKey.cerebroLastSync, DateTime.now().toIso8601String());
}
