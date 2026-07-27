import 'package:hive/hive.dart';

class ExchangeProviderDescription extends HiveObject {
  static const exchangeProviderDescriptionTypeId = 0;

  static const all = ExchangeProviderDescription._('All', 0);
  static const changeNow = ExchangeProviderDescription._('ChangeNow', 1);
  static const morphToken = ExchangeProviderDescription._('MorphToken', 2);
  static const xmrto = ExchangeProviderDescription._('XMR.to', 3);
  static const simpleSwap = ExchangeProviderDescription._('SimpleSwap', 4);
  static const sideShift = ExchangeProviderDescription._('SideShift', 5);
  static const trocador = ExchangeProviderDescription._('Trocador', 6);
  static const exolix = ExchangeProviderDescription._('Exolix', 7);
  static const thorChain = ExchangeProviderDescription._('ThorChain', 8);
  static const swapTrade = ExchangeProviderDescription._('SwapTrade', 9);
  static const letsExchange = ExchangeProviderDescription._('LetsExchange', 10);
  static const stealthEx = ExchangeProviderDescription._('StealthEx', 11);
  static const chainflip = ExchangeProviderDescription._('Chainflip', 12);
  static const xoSwap = ExchangeProviderDescription._('XoSwap', 13);
  static const swapsXyz = ExchangeProviderDescription._('SwapsXyz', 14);
  static const nearIntents = ExchangeProviderDescription._('NearIntents', 15);
  static const jupiter = ExchangeProviderDescription._('Jupiter', 16);

  static const values = [all, changeNow, morphToken, xmrto, simpleSwap, sideShift, trocador, exolix, thorChain, swapTrade, letsExchange, stealthEx, chainflip, xoSwap, swapsXyz, nearIntents, jupiter];

  final String title;
  final int raw;

  const ExchangeProviderDescription._(this.title, this.raw);

  static ExchangeProviderDescription fromRaw(int raw) =>
      values.firstWhere((e) => e.raw == raw, orElse: () => all);
}
