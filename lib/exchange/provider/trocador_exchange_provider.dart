import 'exchange_provider.dart';

class TrocadorProviderInfo {
  final String name;
  final String rating;
  TrocadorProviderInfo({required this.name, required this.rating});
}

class TrocadorExchangeProvider extends ExchangeProvider {
  const TrocadorExchangeProvider() : super('Trocador');
  static const List<String> availableProviders = <String>[];

  Future<List<TrocadorProviderInfo>> fetchProviders() async => [];
}
