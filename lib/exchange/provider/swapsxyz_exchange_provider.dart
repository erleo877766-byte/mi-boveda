import 'exchange_provider.dart';

class SwapsXyzExchangeProvider extends ExchangeProvider {
  const SwapsXyzExchangeProvider() : super('SwapsXyz');

  static Future<bool> registerAltVmTx({
    required String txId,
    required String txHash,
    required int chainId,
    required String vmId,
  }) async => true;
}
