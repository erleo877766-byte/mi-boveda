import '../limits.dart';

abstract class ExchangeProvider {
  final String name;
  const ExchangeProvider(this.name);

  Future<Limits> fetchLimits(String from, String to) async => const Limits();
}
