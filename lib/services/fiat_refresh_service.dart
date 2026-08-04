import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mantiene los precios de mercado (CoinGecko) siempre frescos y nunca en cero.
///
/// - Al abrir la app carga los últimos precios guardados (sin esperar a la red).
/// - Cada 60 segundos busca precios nuevos para la moneda de la billetera y
///   para sus tokens, con respaldo si falla la conexión (usa la última caché).
/// - Persiste los precios obtenidos para que sin internet se sigan mostrando
///   los últimos valores en vez de un 0.
class FiatRefreshService {
  FiatRefreshService({
    required this.appStore,
    required this.settingsStore,
    required this.fiatConversionStore,
    required this.prefs,
  });

  final AppStore appStore;
  final SettingsStore settingsStore;
  final FiatConversionStore fiatConversionStore;
  final SharedPreferences prefs;

  Timer? _priceRefreshTimer;
  bool _isRefreshing = false;
  static const Duration _refreshInterval = Duration(seconds: 60);
  static const int _maxCachedCurrencies = 200;

  void startAutomaticPriceRefresh() {
    if (_priceRefreshTimer != null) return;

    _loadCachedPrices();
    _refreshPrices();
    _priceRefreshTimer = Timer.periodic(_refreshInterval, (_) => _refreshPrices());
  }

  Future<void> _refreshPrices() async {
    if (_isRefreshing) return;
    if (settingsStore.fiatApiMode == FiatApiMode.disabled) return;

    final wallet = appStore.wallet;
    if (wallet == null) return;

    _isRefreshing = true;
    try {
      final fiat = settingsStore.fiatCurrency;
      final torOnly = settingsStore.fiatApiMode == FiatApiMode.torOnly;

      await _updatePrice(wallet.currency, fiat, torOnly);

      Iterable<CryptoCurrency>? currencies;
      if (isEVMCompatibleChain(wallet.type)) {
        currencies = evm!.getERC20Currencies(wallet).where((element) => element.enabled);
      }
      if (wallet.type == WalletType.solana) {
        currencies =
            solana!.getSPLTokenCurrencies(wallet).where((element) => element.enabled);
      }
      if (wallet.type == WalletType.tron) {
        currencies =
            tron!.getTronTokenCurrencies(wallet).where((element) => element.enabled);
      }

      if (currencies != null) {
        for (final currency in currencies) {
          if (currency.isPotentialScam) continue;
          await _updatePrice(currency, fiat, torOnly);
        }
      }

      _persistPrices();
    } catch (e) {
      printV('[FiatRefreshService] $e');
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _updatePrice(
      CryptoCurrency currency, FiatCurrency fiat, bool torOnly) async {
    final key = currency == CryptoCurrency.btcln ? CryptoCurrency.btc : currency;
    try {
      final price =
          await FiatConversionService.fetchPrice(crypto: key, fiat: fiat, torOnly: torOnly);
      if (price > 0) {
        fiatConversionStore.prices[currency] = price;
      }
    } catch (e) {
      // Sin conexión: se conserva el último precio guardado en caché.
      if (!fiatConversionStore.prices.containsKey(currency)) {
        final cached = _cachedPriceFor(currency);
        if (cached != null) {
          fiatConversionStore.prices[currency] = cached;
        }
      }
    }
  }

  void _loadCachedPrices() {
    try {
      final raw = prefs.getString(PreferencesKey.lastFiatPrices);
      if (raw == null || raw.isEmpty) return;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.forEach((ticker, value) {
        final currency = _currencyFromTicker(ticker);
        if (currency == null) return;
        final price = (value as num?)?.toDouble();
        if (price != null && price > 0) {
          fiatConversionStore.prices[currency] = price;
        }
      });
    } catch (e) {
      printV('[FiatRefreshService] load cached prices: $e');
    }
  }

  void _persistPrices() {
    try {
      final map = <String, double>{};
      var count = 0;
      fiatConversionStore.prices.forEach((currency, price) {
        if (count >= _maxCachedCurrencies) return;
        map[currency.toString()] = price;
        count++;
      });
      if (map.isEmpty) return;
      prefs.setString(PreferencesKey.lastFiatPrices, jsonEncode(map));
    } catch (e) {
      printV('[FiatRefreshService] persist prices: $e');
    }
  }

  double? _cachedPriceFor(CryptoCurrency currency) {
    try {
      final raw = prefs.getString(PreferencesKey.lastFiatPrices);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final value = map[currency.toString()];
      if (value is num && value.toDouble() > 0) return value.toDouble();
      return null;
    } catch (_) {
      return null;
    }
  }

  CryptoCurrency? _currencyFromTicker(String ticker) {
    try {
      return CryptoCurrency.fromString(ticker);
    } catch (_) {
      return null;
    }
  }

  void forceRefresh() {
    _refreshPrices();
  }

  void dispose() {
    _priceRefreshTimer?.cancel();
    _priceRefreshTimer = null;
  }
}
