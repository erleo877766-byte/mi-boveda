import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'dart:convert';

const _binanceApiAuthority = 'api.binance.com';
const _binanceApiPath = '/api/v3/ticker/price';
const _coingeckoApiAuthority = 'api.coingecko.com';
const _coingeckoApiPath = '/api/v3/simple/price';

/// Tickers que NO tienen par en Binance; se consultan vía CoinGecko público.
const Map<String, String> _tickerToCoingeckoId = {
  'XHV': 'haven',
  'ZANO': 'zano',
  'WOW': 'wownero',
  'BAN': 'banano',
  'WETH': 'weth',
  'STETH': 'staked-ether',
  'FLIP': 'chainflip',
};

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

/// Último precio USD conocido por ticker. Evita devolver 0.0 cuando el par
/// no existe en Binance (XHV, ZANO, WOW, BAN, WETH, STETH, FLIP) o cuando la
/// red falla: se devuelve el último valor guardado en vez de un cero.
final Map<String, double> _lastKnownPrice = {};

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

    if (response.statusCode == 200) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final priceStr = responseJSON['price'] as String?;
      final usdPrice = double.tryParse(priceStr ?? '');
      if (usdPrice != null && usdPrice > 0) {
        _lastKnownPrice[ticker] = usdPrice;
        return _convertFiat(usdPrice, fiat);
      }
    }
  } catch (e) {
    printV('FiatConversionService: $e');
  }

  // Monedas sin par en Binance (XHV, ZANO, WOW, BAN, WETH, STETH, FLIP):
  // consultar CoinGecko público antes de recurrir al caché.
  final coingeckoId = _tickerToCoingeckoId[ticker];
  if (coingeckoId != null) {
    try {
      final cgUri = Uri.https(
        _coingeckoApiAuthority,
        _coingeckoApiPath,
        {'ids': coingeckoId, 'vs_currencies': 'usd'},
      );
      final cgResponse = await ProxyWrapper()
          .get(clearnetUri: cgUri, onionUri: cgUri)
          .timeout(Duration(seconds: 15));

      if (cgResponse.statusCode == 200) {
        final cgJson = json.decode(cgResponse.body) as Map<String, dynamic>;
        final coinData = cgJson[coingeckoId] as Map<String, dynamic>?;
        final usdPrice = double.tryParse(coinData?['usd']?.toString() ?? '');
        if (usdPrice != null && usdPrice > 0) {
          _lastKnownPrice[ticker] = usdPrice;
          return _convertFiat(usdPrice, fiat);
        }
      }
    } catch (e) {
      printV('FiatConversionService coingecko: $e');
    }
  }

  // No se obtuvo precio actual (par inexistente o fallo de red):
  // usar el último valor guardado en vez de devolver 0.0.
  final cached = _lastKnownPrice[ticker];
  if (cached != null && cached > 0) {
    return _convertFiat(cached, fiat);
  }

  printV('FiatConversionService: no price found for $ticker, no cached value');
  return 0.0;
}

Future<double> _convertFiat(double usdPrice, String fiat) async {
  if (fiat == 'USD') {
    return usdPrice;
  }

  try {
    // Conversión de fiat usando el par FIATUSDT de Binance (p.ej. EURUSDT)
    final fiatSymbol = '${fiat}USDT';
    final fiatUri = Uri.https(_binanceApiAuthority, _binanceApiPath, {'symbol': fiatSymbol});
    final fiatResponse = await ProxyWrapper()
        .get(clearnetUri: fiatUri, onionUri: fiatUri)
        .timeout(Duration(seconds: 15));

    if (fiatResponse.statusCode != 200) {
      return usdPrice;
    }

    final fiatJson = json.decode(fiatResponse.body) as Map<String, dynamic>;
    final fiatUsd = double.tryParse((fiatJson['price'] as String?) ?? '');
    if (fiatUsd == null || fiatUsd <= 0) {
      return usdPrice;
    }

    return usdPrice / fiatUsd;
  } catch (_) {
    return usdPrice;
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
