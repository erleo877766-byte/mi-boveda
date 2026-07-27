import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'dart:convert';

const _coingeckoApiAuthority = 'api.coingecko.com';
const _coingeckoApiPath = '/api/v3/simple/price';

const Map<String, String> _tickerToCoingeckoId = {
  'BTC': 'bitcoin',
  'XMR': 'monero',
  'LTC': 'litecoin',
  'ETH': 'ethereum',
  'BCH': 'bitcoin-cash',
  'BNB': 'binancecoin',
  'SOL': 'solana',
  'TRX': 'tron',
  'XNO': 'nano',
  'ZEC': 'zcash',
  'DCR': 'decred',
  'ZANO': 'zano',
  'DOGE': 'dogecoin',
  'BAN': 'banano',
  'ADA': 'cardano',
  'DASH': 'dash',
  'EOS': 'eos',
  'XRP': 'ripple',
  'XLM': 'stellar',
  'KMD': 'komodo',
  'PIVX': 'pivx',
  'XHV': 'haven',
  'MANA': 'decentraland',
  'MKR': 'maker',
  'NEAR': 'near',
  'OXT': 'orchid',
  'PAXG': 'pax-gold',
  'RUNE': 'thorchain',
  'RVN': 'ravencoin',
  'SCRT': 'secret',
  'UNI': 'uniswap',
  'STX': 'blockstack',
  'SHIB': 'shiba-inu',
  'AAVE': 'aave',
  'ARB': 'arbitrum',
  'BAT': 'basic-attention-token',
  'COMP': 'compound-governance-token',
  'CRO': 'crypto-com-chain',
  'ENS': 'ethereum-name-service',
  'FTM': 'fantom',
  'FRAX': 'frax',
  'GUSD': 'gemini-dollar',
  'GTC': 'gitcoin',
  'GRT': 'the-graph',
  'LDO': 'lido-dao',
  'NEXO': 'nexo',
  'CAKE': 'pancakeswap-token',
  'PEPE': 'pepe',
  'STORJ': 'storj',
  'TUSD': 'true-usd',
  'WBTC': 'wrapped-bitcoin',
  'WETH': 'weth',
  'ZRX': 'ox',
  'DYDX': 'dydx-chain',
  'STETH': 'staked-ether',
  'USDT': 'tether',
  'USDC': 'usd-coin',
  'DAI': 'dai',
  'MATIC': 'matic-network',
  'SC': 'siacoin',
  'HBAR': 'hedera-hashgraph',
  'BTT': 'bittorrent',
  'BTTC': 'bittorrent',
  'FIRO': 'firo',
  'APE': 'apecoin',
  'AVAX': 'avalanche-2',
  'FLIP': 'chainflip',
  'WOW': 'wownero',
  'TON': 'the-open-network',
  'KAS': 'kaspa',
  'DEPS': 'decentralized-euro-protocol-share',
  'NDEPS': 'decentralized-euro-protocol-share',
};

Future<double> _fetchPrice(String crypto, String fiat, bool torOnly) async {
  final ticker = crypto.split(".").first;
  final coingeckoId = _tickerToCoingeckoId[ticker];
  if (coingeckoId == null) {
    return 0.0;
  }

  num price = 0.0;

  try {
    final uri = Uri.https(_coingeckoApiAuthority, _coingeckoApiPath, {
      'ids': coingeckoId,
      'vs_currencies': fiat,
    });

    final response = await ProxyWrapper()
        .get(clearnetUri: uri, onionUri: uri)
        .timeout(Duration(seconds: 15));

    if (response.statusCode != 200) {
      return 0.0;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final coinData = responseJSON[coingeckoId] as Map<String, dynamic>?;
    if (coinData != null && coinData.containsKey(fiat)) {
      price = coinData[fiat] as num;
    }

    return price.toDouble();
  } catch (e) {
    return price.toDouble();
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
