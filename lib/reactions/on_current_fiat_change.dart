import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/services/fiat_refresh_service.dart';

FiatRefreshService? _fiatRefreshService;

void startCurrentFiatChangeReaction(
    AppStore appStore, SettingsStore settingsStore, FiatConversionStore fiatConversionStore) {
  if (_fiatRefreshService == null) {
    _fiatRefreshService = FiatRefreshService(
      settingsStore: settingsStore,
      fiatConversionStore: fiatConversionStore,
    );
    _fiatRefreshService?.startAutomaticPriceRefresh();
  }
}
