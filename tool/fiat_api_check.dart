import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http; // very_insecure_http_do_not_use
import './print_verbose_dummy.dart';

// 1. Configuration
const _coingeckoApiAuthority = 'api.coingecko.com';
const _coingeckoApiPath = '/api/v3/simple/price';

const Map<String, String> _tickerToCoingeckoId = {
  'btc': 'bitcoin',
  'xmr': 'monero',
  'ltc': 'litecoin',
  'eth': 'ethereum',
  'bch': 'bitcoin-cash',
  'bnb': 'binancecoin',
  'sol': 'solana',
  'trx': 'tron',
  'xno': 'nano',
  'zec': 'zcash',
  'dcr': 'decred',
  'zano': 'zano',
  'doge': 'dogecoin',
  'banano': 'banano',
  'ada': 'cardano',
  'dash': 'dash',
  'xrp': 'ripple',
  'xlm': 'stellar',
  'shib': 'shiba-inu',
  'pol': 'matic-network',
  'arb': 'arbitrum',
  'usdt': 'tether',
  'usdc': 'usd-coin',
  'dai': 'dai',
  'kas': 'kaspa',
  'ton': 'the-open-network',
  'avax': 'avalanche-2',
  'link': 'chainlink',
  'uni': 'uniswap',
  'near': 'near',
  'atom': 'cosmos',
  'stx': 'blockstack',
  'pepe': 'pepe',
  'wow': 'wownero',
};

// 2. Define Lists
const List<String> cryptoCurrencies = [
  'btc',
  'ltc',
  'xmr',
  'bch',
  'doge',
  'eth',
  'pol',
  'sol',
  'xno',
  'trx',
  'dcr',
  'zano',
  'wow',
  'arb',
  'usdt',
  'pepe',
  'zec',
  'bnb',
  'xrp',
  'ada',
  'avax',
  'shib',
  'ton',
  'dot',
  'link',
  'uni',
  'near',
  'atom',
  'xlm',
  'stx',
  'kas',
  'dai',
];

const List<String> fiatCurrencies = [
  'usd',
  'eur',
  'aud',
  'gbp',
  'jpy',
  'cad',
  'chf',
  'cny',
  'inr',
  'brl',
  'zar',
  'mxn',
  'krw',
  'hkd',
  'sgd',
  'nzd',
  'sek',
  'try'
];

void main() {
  // --- A. Setup the Output File ---
  final logFile = File('fiat-check-output.txt');
  // Write a header to start fresh (overwrite old file)
  logFile.writeAsStringSync('--- Starting Verified Price Check at ${DateTime.now()} ---\n');

  // --- B. Run App in a Zone to Capture Prints ---
  runZoned(
    () async {
      print('--- Starting Verified Price Check ---');

      final Map<String, List<String>> workingPairs = {};
      final Map<String, List<String>> failedPairs = {};
      final client = http.Client();

      try {
        for (final crypto in cryptoCurrencies) {
          workingPairs[crypto] = [];
          failedPairs[crypto] = [];

          for (final fiat in fiatCurrencies) {
            // Map ticker to CoinGecko ID
            final coingeckoId = _tickerToCoingeckoId[crypto];
            if (coingeckoId == null) {
              final logMsg = "⚠️ ${crypto.toUpperCase()}: No CoinGecko ID mapping";
              print(logMsg);
              failedPairs[crypto]!.add(fiat);
              continue;
            }

            final uri = Uri.https(_coingeckoApiAuthority, _coingeckoApiPath, {
              'ids': coingeckoId,
              'vs_currencies': fiat,
            });
            bool isSuccess = false;
            String logPrefix = "❌";
            String logMessage = "";

            try {
              final response = await client.get(uri);

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body) as Map<String, dynamic>;
                final coinData = data[coingeckoId] as Map<String, dynamic>?;

                if (coinData != null && coinData.containsKey(fiat)) {
                  isSuccess = true;
                  logPrefix = "✅";
                  final price = coinData[fiat];
                  logMessage = "${crypto.toUpperCase()}/${fiat.toUpperCase()} = $price";
                } else {
                  isSuccess = false;
                  logPrefix = "❌";
                  logMessage =
                      "${crypto.toUpperCase()}/${fiat.toUpperCase()} returned empty results.";
                }
              } else {
                logMessage =
                    "${crypto.toUpperCase()}/${fiat.toUpperCase()} HTTP ${response.statusCode}";
              }
            } catch (e) {
              logMessage = "${crypto.toUpperCase()}/${fiat.toUpperCase()} Error: $e";
            }

            // Print immediate status (Captured by Zone)
            print('$logPrefix $logMessage');

            // Aggregate
            if (isSuccess) {
              workingPairs[crypto]!.add(fiat);
            } else {
              failedPairs[crypto]!.add(fiat);
            }

            // 50ms delay to prevent rate limiting
            await Future.delayed(Duration(milliseconds: 50));
          }
        }
      } finally {
        client.close();
      }

      // --- FINAL SUMMARY ---
      print('\n\n=== SUMMARY ===\n');

      // Print Successful
      workingPairs.forEach((crypto, fiats) {
        if (fiats.isNotEmpty) {
          print('✅ ${crypto.toUpperCase()}: ${fiats.join(", ")}');
        }
      });

      print('\n--------------------------------------------------\n');

      // Print Failed
      failedPairs.forEach((crypto, fiats) {
        if (fiats.isNotEmpty) {
          print('❌ ${crypto.toUpperCase()}: ${fiats.join(", ")}');
        }
      });

      print('\n=== DONE ===');
    },

    // --- C. The Interceptor ---
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        // 1. Print to Standard Console
        parent.print(zone, line);

        // 2. Append to Text File
        // We use Sync to ensure data isn't lost if the script crashes
        logFile.writeAsStringSync('$line\n', mode: FileMode.append);
      },
    ),
  );
}
