import 'dart:async';
import 'package:cake_wallet/reactions/on_current_fiat_api_mode_change.dart';
import 'package:cake_wallet/reactions/on_current_node_change.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/reactions/on_authentication_state_change.dart';
import 'package:cake_wallet/reactions/on_current_fiat_change.dart';
import 'package:cake_wallet/reactions/on_current_wallet_change.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/core/node_switching_service.dart';
import 'package:cake_wallet/core/cerebro_service.dart';
import 'package:cake_wallet/core/cerebro_notifications.dart';
import 'package:cake_wallet/services/fiat_refresh_service.dart';
import 'package:cake_wallet/utils/feature_flag.dart';

Future<void> bootstrapOffline() async {
  final authenticationStore = getIt.get<AuthenticationStore>();

  final currentWalletName =
      getIt.get<SharedPreferences>().getString(PreferencesKey.currentWalletName);
  if (currentWalletName != null) {
    authenticationStore.installed();
  }
}

void bootstrapOnline(GlobalKey<NavigatorState> navigatorKey, {required bool loadWallet}) {
  final appStore = getIt.get<AppStore>();
  final authenticationStore = getIt.get<AuthenticationStore>();
  final settingsStore = getIt.get<SettingsStore>();
  final fiatConversionStore = getIt.get<FiatConversionStore>();

  if (loadWallet) {
    startAuthenticationStateChange(authenticationStore, navigatorKey);
  }

  startCurrentWalletChangeReaction(appStore, settingsStore, fiatConversionStore);
  startCurrentFiatChangeReaction(appStore, settingsStore, fiatConversionStore);
  startCurrentFiatApiModeChangeReaction(appStore, settingsStore, fiatConversionStore);
  startOnCurrentNodeChangeReaction(appStore);

  final fiatRefreshService = FiatRefreshService(
    appStore: appStore,
    settingsStore: settingsStore,
    fiatConversionStore: fiatConversionStore,
    prefs: getIt.get<SharedPreferences>(),
  );
  fiatRefreshService.startAutomaticPriceRefresh();

  if (FeatureFlag.isAutomaticNodeSwitchingEnabled) {
    getIt.get<NodeSwitchingService>().startHealthCheckTimer();
  }

  final cerebroService = getIt.get<CerebroService>();
  cerebroService.onNotification =
      (title, body) => unawaited(CerebroNotifications.show(title, body));
  unawaited(_requestCerebroNotificationPermission());
  cerebroService.start();
}

Future<void> _requestCerebroNotificationPermission() async {
  try {
    final prefs = getIt.get<SharedPreferences>();
    if (prefs.getBool(PreferencesKey.cerebroNotificationsEnabled) == null) {
      await prefs.setBool(PreferencesKey.cerebroNotificationsEnabled, true);
      await CerebroNotifications.requestPermission();
    }
  } catch (_) {}
}
