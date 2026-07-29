import 'exchange_provider.dart';

class JupiterExchangeProvider extends ExchangeProvider {
  const JupiterExchangeProvider() : super('Jupiter');

  Future<Map<String, dynamic>> executeSwap({
    required String signedTransaction,
    required String requestId,
  }) async => {};
}
