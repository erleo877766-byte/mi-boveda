import 'package:cake_wallet/di.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/utils/wallet_cleanup.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';

Future<void> loadCurrentWallet({String? password}) async {
  final appStore = getIt.get<AppStore>();
  final prefs = getIt.get<SharedPreferences>();
  final name = prefs.getString(PreferencesKey.currentWalletName);
  final typeRaw = prefs.getInt(PreferencesKey.currentWalletType) ?? 0;

  if (name == null || name.isEmpty) {
    // SECURITY: No wallet name saved — this is a clean install or the
    // previous attempt was cleaned up.  Nothing to load.
    throw Exception('No current wallet — clean start required');
  }

  final type = deserializeFromInt(typeRaw);
  final walletLoadingService = getIt.get<WalletLoadingService>();

  try {
    final wallet = await walletLoadingService.load(type, name, password: password);
    await appStore.changeCurrentWallet(wallet);
  } catch (e) {
    // SECURITY: Wallet load failed (corrupted, missing, bad native lib…).
    // Clean up ALL data for this wallet and re-throw so the caller
    // can navigate back to the welcome screen.
    debugPrint('[loadCurrentWallet] Load failed for "$name" ($type): $e');
    await WalletCleanup.removeAllCorruptedWallets();
    rethrow;
  }
}
