import 'package:hive/hive.dart';

class ExchangeProviderDescription extends HiveObject {
  static const exchangeProviderDescriptionTypeId = 0;

  static final all = ExchangeProviderDescription._('All', 0);
  static final changeNow = ExchangeProviderDescription._('ChangeNow', 1);
  static final morphToken = ExchangeProviderDescription._('MorphToken', 2);
  static final xmrto = ExchangeProviderDescription._('XMR.to', 3);
  static final simpleSwap = ExchangeProviderDescription._('SimpleSwap', 4);
  static final sideShift = ExchangeProviderDescription._('SideShift', 5);
  static final trocador = ExchangeProviderDescription._('Trocador', 6);
  static final exolix = ExchangeProviderDescription._('Exolix', 7);
  static final thorChain = ExchangeProviderDescription._('ThorChain', 8);
  static final swapTrade = ExchangeProviderDescription._('SwapTrade', 9);
  static final letsExchange = ExchangeProviderDescription._('LetsExchange', 10);
  static final stealthEx = ExchangeProviderDescription._('StealthEx', 11);
  static final chainflip = ExchangeProviderDescription._('Chainflip', 12);
  static final xoSwap = ExchangeProviderDescription._('XoSwap', 13);
  static final swapsXyz = ExchangeProviderDescription._('SwapsXyz', 14);
  static final nearIntents = ExchangeProviderDescription._('NearIntents', 15);
  static final jupiter = ExchangeProviderDescription._('Jupiter', 16);

  static final values = [all, changeNow, morphToken, xmrto, simpleSwap, sideShift, trocador, exolix, thorChain, swapTrade, letsExchange, stealthEx, chainflip, xoSwap, swapsXyz, nearIntents, jupiter];

  final String title;
  final int raw;

  ExchangeProviderDescription._(this.title, this.raw);

  static ExchangeProviderDescription fromRaw(int raw) =>
      values.firstWhere((e) => e.raw == raw, orElse: () => all);
}
