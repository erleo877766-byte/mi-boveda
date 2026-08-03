import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';

class FiatRefreshService {
  final SettingsStore settingsStore;
  final FiatConversionStore fiatConversionStore;

  Timer? _priceRefreshTimer;
  bool _isRefreshing = false;
  final Duration _refreshInterval = const Duration(seconds: 60);

  FiatRefreshService({
    required this.settingsStore,
    required this.fiatConversionStore,
  });

  void startAutomaticPriceRefresh() {
    if (_priceRefreshTimer != null) return;

    _priceRefreshRefreshNow();
    _priceRefreshTimer = Timer.periodic(_refreshInterval, (_) => _priceRefreshRefreshNow());
  }

  void _priceRefreshRefreshNow() async {
    if (_isRefreshing) return;

    try {
      _isRefreshing = true;

      if (settingsStore.fiatApiMode == FiatApiMode.disabled) return;

      final fiatCurrency = settingsStore.fiatCurrency;
      final cryptoCurrency = settingsStore.wallet?.currency;
      if (cryptoCurrency == null) return;

      final torOnly = settingsStore.fiatApiMode == FiatApiMode.torOnly;

      double price;
      try {
        price = await FiatConversionService.fetchPrice(
          crypto: cryptoCurrency,
          fiat: fiatCurrency,
          torOnly: torOnly,
        );
        fiatConversionStore.prices[cryptoCurrency] = price;
      } catch (e) {
        if (fiatConversionStore.prices[cryptoCurrency] == null) {
          fiatConversionStore.prices[cryptoCurrency] = 0.0;
        }
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void dispose() {
    _priceRefreshTimer?.cancel();
    _priceRefreshTimer = null;
  }

  void forceRefresh() {
    _priceRefreshRefreshNow();
  }
}
