import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'dart:convert';

const _binanceApiAuthority = 'api.binance.com';
const _binanceApiPath = '/api/v3/ticker/price';

/// Símbolos de Binance que NO siguen el patrón TICKER + 'USDT'.
/// Todo lo demás se construye automáticamente como '${ticker}USDT'.
const Map<String, String> _tickerToBinanceSymbol = {
  'MATIC': 'POLUSDT',
  'BTT': 'BTTUSDT',
  'BTTC': 'BTTCUSDT',
  'XNO': 'XNOUSDT',
  'WBTC': 'WBTCUSDT',
  'WETH': 'WETHUSDT',
  'STETH': 'STETHUSDT',
  'ARB': 'ARBUSDT',
  'FLIP': 'FLIPUSDT',
  'TON': 'TONUSDT',
};

Future<double> _fetchPrice(String crypto, String fiat, bool torOnly) async {
  final ticker = crypto.split(".").first;

  // El par USDT/USDT no existe; el precio de una stablecoin es ~1
  if (ticker == 'USDT') return 1.0;

  final symbol = _tickerToBinanceSymbol[ticker] ?? '${ticker}USDT';

  try {
    final uri = Uri.https(_binanceApiAuthority, _binanceApiPath, {'symbol': symbol});

    final response = await ProxyWrapper()
        .get(clearnetUri: uri, onionUri: uri)
        .timeout(Duration(seconds: 15));

    if (response.statusCode != 200) {
      return 0.0;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final priceStr = responseJSON['price'] as String?;
    final usdPrice = double.tryParse(priceStr ?? '');
    if (usdPrice == null || usdPrice <= 0) {
      return 0.0;
    }

    if (fiat == 'USD') {
      return usdPrice;
    }

    // Conversión de fiat usando el par FIATUSDT de Binance (p.ej. EURUSDT)
    final fiatSymbol = '${fiat}USDT';
    final fiatUri = Uri.https(_binanceApiAuthority, _binanceApiPath, {'symbol': fiatSymbol});
    final fiatResponse = await ProxyWrapper()
        .get(clearnetUri: fiatUri, onionUri: fiatUri)
        .timeout(Duration(seconds: 15));

    if (fiatResponse.statusCode != 200) {
      return 0.0;
    }

    final fiatJson = json.decode(fiatResponse.body) as Map<String, dynamic>;
    final fiatUsd = double.tryParse((fiatJson['price'] as String?) ?? '');
    if (fiatUsd == null || fiatUsd <= 0) {
      return 0.0;
    }

    return usdPrice / fiatUsd;
  } catch (e) {
    printV('FiatConversionService: $e');
    return 0.0;
  }
}

/// Override specific [CryptoCurrency] to fix its price to the price of another
/// e.g. nDEPS should have the same price as DEPS, but only DEPS is tracked
CryptoCurrency _overrideCryptoCurrency(CryptoCurrency crypto) {
  if (crypto.title == CryptoCurrency.ndeps.title) return CryptoCurrency.deps;
  return crypto;
}

class FiatConversionService {
  static Future<double> fetchPrice({
    required CryptoCurrency crypto,
    required FiatCurrency fiat,
    required bool torOnly,
  }) async =>
      await _fetchPrice(_overrideCryptoCurrency(crypto).toString(), fiat.toString(), torOnly);
}
