import 'dart:io';

import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility to completely remove partial/incomplete wallet data.
///
/// RULE: If wallet creation or restore fails for ANY reason (crash,
/// validation error, missing native lib, power loss…), every byte
/// of data that was persisted during that attempt must be removed
/// before the user can try again.  No "Corrupted seeds" dialog.
/// No half-saved wallet.  Clean slate, always.
class WalletCleanup {
  /// Remove every trace of a wallet that was being created/restored.
  ///
  /// Safe to call at any point – it tolerates missing entries.
  /// After this call the app should behave exactly as if the
  /// wallet had never been started.
  static Future<void> removePartialWallet({
    required String walletName,
    required WalletType walletType,
    String? password,
  }) async {
    try {
      // 1. Delete on-disk wallet files (keys, cache, etc.)
      await _deleteWalletFiles(walletName, walletType);

      // 2. Delete WalletInfo row from SQLite
      await _deleteWalletInfo(walletName, walletType);

      // 3. Delete password from secure storage
      if (password != null) {
        await _deleteWalletPassword(walletName);
      }

      // 4. Clear current wallet references from SharedPreferences
      await _clearCurrentWalletPrefs();

      // 5. Clear Monero update flag if any
      await _clearMoneroUpdateFlag(walletName);
    } catch (e) {
      debugPrint('[WalletCleanup] removePartialWallet error (non-fatal): $e');
    }
  }

  /// Remove ALL wallets that are not fully usable.
  ///
  /// Called on startup when we detect the "current wallet" points
  /// to data that cannot be loaded.
  static Future<void> removeAllCorruptedWallets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletName = prefs.getString(PreferencesKey.currentWalletName);
      final walletTypeInt = prefs.getInt(PreferencesKey.currentWalletType) ?? 0;

      if (walletName != null && walletName.isNotEmpty) {
        final walletType = deserializeFromInt(walletTypeInt);
        await removePartialWallet(
          walletName: walletName,
          walletType: walletType,
        );
      }

      // Also clean any orphaned wallet directories
      await _cleanOrphanedWalletDirs();
    } catch (e) {
      debugPrint('[WalletCleanup] removeAllCorruptedWallets error (non-fatal): $e');
    }
  }

  /// Remove a wallet password from secure storage.
  static Future<void> _deleteWalletPassword(String walletName) async {
    try {
      final keyService = getIt.get<KeyService>();
      await keyService.deleteWalletPassword(walletName: walletName);
    } catch (e) {
      debugPrint('[WalletCleanup] _deleteWalletPassword error: $e');
    }
  }

  /// Delete the wallet's on-disk files (keys, cache, etc.).
  static Future<void> _deleteWalletFiles(String walletName, WalletType walletType) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final walletDir = Directory('${appDir.path}/wallets/${_walletTypeDir(walletType)}/$walletName');
      if (await walletDir.exists()) {
        await walletDir.delete(recursive: true);
        debugPrint('[WalletCleanup] Deleted wallet dir: ${walletDir.path}');
      }
    } catch (e) {
      debugPrint('[WalletCleanup] _deleteWalletFiles error: $e');
    }
  }

  /// Delete the WalletInfo row from SQLite.
  static Future<void> _deleteWalletInfo(String walletName, WalletType walletType) async {
    try {
      final walletInfo = await WalletInfo.get(walletName, walletType);
      if (walletInfo != null) {
        await WalletInfo.delete(walletInfo);
        debugPrint('[WalletCleanup] Deleted WalletInfo for: $walletName');
      }
    } catch (e) {
      debugPrint('[WalletCleanup] _deleteWalletInfo error: $e');
    }
  }

  /// Clear current_wallet_name / current_wallet_type from SharedPreferences.
  static Future<void> _clearCurrentWalletPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PreferencesKey.currentWalletName);
      await prefs.remove(PreferencesKey.currentWalletType);
      debugPrint('[WalletCleanup] Cleared current wallet prefs');
    } catch (e) {
      debugPrint('[WalletCleanup] _clearCurrentWalletPrefs error: $e');
    }
  }

  /// Remove the monero_wallet_update_v1 flag for the given wallet.
  static Future<void> _clearMoneroUpdateFlag(String walletName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PreferencesKey.moneroWalletUpdateV1Key(walletName));
    } catch (e) {
      debugPrint('[WalletCleanup] _clearMoneroUpdateFlag error: $e');
    }
  }

  /// Delete any wallet directories that don't have a matching WalletInfo in SQLite.
  static Future<void> _cleanOrphanedWalletDirs() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final walletsDir = Directory('${appDir.path}/wallets');
      if (!await walletsDir.exists()) return;

      final walletInfos = await WalletInfo.getAll();
      final knownPaths = walletInfos.map((w) => w.dirPath).toSet();

      await for (final coinDir in walletsDir.list()) {
        if (coinDir is Directory) {
          await for (final walletDir in coinDir.list()) {
            if (walletDir is Directory && !knownPaths.contains(walletDir.path)) {
              debugPrint('[WalletCleanup] Removing orphaned wallet dir: ${walletDir.path}');
              await walletDir.delete(recursive: true);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[WalletCleanup] _cleanOrphanedWalletDirs error: $e');
    }
  }

  static String _walletTypeDir(WalletType type) {
    switch (type) {
      case WalletType.bitcoin:
        return 'bitcoin';
      case WalletType.litecoin:
        return 'litecoin';
      case WalletType.monero:
        return 'monero';
      case WalletType.wownero:
        return 'wownero';
      case WalletType.ethereum:
        return 'ethereum';
      case WalletType.bitcoinCash:
        return 'bitcoincash';
      case WalletType.dogecoin:
        return 'dogecoin';
      case WalletType.solana:
        return 'solana';
      case WalletType.tron:
        return 'tron';
      case WalletType.nano:
        return 'nano';
      case WalletType.polygon:
        return 'polygon';
      case WalletType.zcash:
        return 'zcash';
      case WalletType.bsc:
        return 'bsc';
      case WalletType.base:
        return 'base';
      case WalletType.arbitrum:
        return 'arbitrum';
      case WalletType.haven:
        return 'haven';
      case WalletType.zano:
        return 'zano';
      case WalletType.decred:
        return 'decred';
      case WalletType.banano:
        return 'banano';
      case WalletType.none:
        return 'none';
    }
  }
}
