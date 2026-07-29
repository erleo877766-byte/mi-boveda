import 'exchange_provider.dart';

class ThorChainExchangeProvider extends ExchangeProvider {
  const ThorChainExchangeProvider() : super('ThorChain');

  static Future<Map<String, String>> lookupAddressByName(String query) async => {};
}
