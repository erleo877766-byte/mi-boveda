import 'dart:async';

import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cake_wallet/utils/wallet_cleanup.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletLoadingService {
  WalletLoadingService(
    this.sharedPreferences,
    this.keyService,
    this.walletServiceFactory,
  );

  final SharedPreferences sharedPreferences;
  final KeyService keyService;
  final WalletService Function(WalletType type) walletServiceFactory;

  Future<void> renameWallet(WalletType type, String name, String newName,
      {String? password}) async {
    try {
      final walletService = walletServiceFactory.call(type);
      final walletPassword = password ?? (await keyService.getWalletPassword(walletName: name));

      // Save the current wallet's password to the new wallet name's key
      await keyService.saveWalletPassword(walletName: newName, password: walletPassword);

      await walletService.rename(name, walletPassword, newName);
      // Delete previous wallet name from keyService to keep only new wallet's name
      // otherwise keeps duplicate (old and new names)
      await keyService.deleteWalletPassword(walletName: name);

      // set shared preferences flag based on previous wallet name
      if (type == WalletType.monero) {
        final oldNameKey = PreferencesKey.moneroWalletUpdateV1Key(name);
        final isPasswordUpdated = sharedPreferences.getBool(oldNameKey) ?? false;
        final newNameKey = PreferencesKey.moneroWalletUpdateV1Key(newName);
        await sharedPreferences.setBool(newNameKey, isPasswordUpdated);
      }
    } catch (error, stack) {
      await ExceptionHandler.resetLastPopupDate();
      await ExceptionHandler.onError(FlutterErrorDetails(exception: error, stack: stack));
    }
  }

  Future<WalletBase> load(WalletType type, String name,
      {String? password, bool isBackground = false}) async {
    try {
      if (!isBackground) {
        await sharedPreferences.setString(
            PreferencesKey.backgroundSyncLastTrigger(name), DateTime.now().toIso8601String());
      }
      final walletService = walletServiceFactory.call(type);
      final walletPassword = password ?? (await keyService.getWalletPassword(walletName: name));
      final wallet = await walletService.openWallet(name, walletPassword);

      if (type == WalletType.monero) {
        await updateMoneroWalletPassword(wallet);
      }

      return wallet;
    } catch (error, stack) {
      debugPrint('[WalletLoading] Wallet open failed: $error');

      // SECURITY: The wallet is corrupted or missing.  Remove ALL data
      // for this wallet and notify the app to go back to the clean start.
      // Never show "Corrupted seeds" — just clean up and start over.
      try {
        await WalletCleanup.removePartialWallet(
          walletName: name,
          walletType: type,
          password: password,
        );
      } catch (_) {}

      rethrow;
    }
  }

  Future<void> updateMoneroWalletPassword(WalletBase wallet) async {
    final key = PreferencesKey.moneroWalletUpdateV1Key(wallet.name);
    var isPasswordUpdated = sharedPreferences.getBool(key) ?? false;

    if (isPasswordUpdated) {
      return;
    }

    final password = generateWalletPassword();
    // Save new generated password with backup key for case where
    // wallet will change password, but it will fail to update in secure storage
    final bakWalletName = '#__${wallet.name}_bak__#';
    await keyService.saveWalletPassword(walletName: bakWalletName, password: password);
    await wallet.changePassword(password);
    await keyService.saveWalletPassword(walletName: wallet.name, password: password);
    isPasswordUpdated = true;
    await sharedPreferences.setBool(key, isPasswordUpdated);
  }

  Future<bool> requireHardwareWalletConnection(WalletType type, String name) async {
    final walletService = walletServiceFactory.call(type);
    return await walletService.requireHardwareWalletConnection(name);
  }
}
