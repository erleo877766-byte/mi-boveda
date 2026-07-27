import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';

part 'trade_filter_store.g.dart';

class TradeFilterStore = TradeFilterStoreBase with _$TradeFilterStore;

abstract class TradeFilterStoreBase with Store {
  TradeFilterStoreBase()
      : displayChangeNow = true,
        displaySideShift = true,
        displaySimpleSwap = true,
        displayTrocador = true,
        displayExolix = true,
        displayChainflip = true,
        displayThorChain = true,
        displayLetsExchange = true,
        displayStealthEx = true,
        displayXOSwap = true,
        displaySwapTrade = true,
        displaySwapXyz = true,
        displayNearIntents = true;

  @observable
  bool displayChangeNow;

  @observable
  bool displaySideShift;

  @observable
  bool displaySimpleSwap;

  @observable
  bool displayTrocador;

  @observable
  bool displayExolix;

  @observable
  bool displayChainflip;

  @observable
  bool displayThorChain;

  @observable
  bool displayLetsExchange;

  @observable
  bool displayStealthEx;

  @observable
  bool displayXOSwap;

  @observable
  bool displaySwapTrade;

  @observable
  bool displaySwapXyz;

  @observable
  bool displayNearIntents;

  @computed
  bool get displayAllTrades =>
      displayChangeNow &&
      displaySideShift &&
      displaySimpleSwap &&
      displayTrocador &&
      displayExolix &&
      displayChainflip &&
      displayThorChain &&
      displayLetsExchange &&
      displayStealthEx &&
      displayXOSwap &&
      displaySwapTrade &&
      displaySwapXyz &&
      displayNearIntents;

  @computed
  int get enabledProvidersCount {
    int count = 0;
    if (displayChangeNow) count++;
    if (displaySideShift) count++;
    if (displaySimpleSwap) count++;
    if (displayTrocador) count++;
    if (displayExolix) count++;
    if (displayChainflip) count++;
    if (displayThorChain) count++;
    if (displayLetsExchange) count++;
    if (displayStealthEx) count++;
    if (displayXOSwap) count++;
    if (displaySwapTrade) count++;
    if (displaySwapXyz) count++;
    if (displayNearIntents) count++;
    return count;
  }

  @action
  void toggleDisplayExchange(ExchangeProviderDescription provider) {
    switch (provider) {
      case ExchangeProviderDescription.changeNow:
        displayChangeNow = !displayChangeNow;
        break;
      case ExchangeProviderDescription.sideShift:
        displaySideShift = !displaySideShift;
        break;
      case ExchangeProviderDescription.simpleSwap:
        displaySimpleSwap = !displaySimpleSwap;
        break;
      case ExchangeProviderDescription.trocador:
        displayTrocador = !displayTrocador;
        break;
      case ExchangeProviderDescription.exolix:
        displayExolix = !displayExolix;
        break;
      case ExchangeProviderDescription.chainflip:
        displayChainflip = !displayChainflip;
        break;
      case ExchangeProviderDescription.thorChain:
        displayThorChain = !displayThorChain;
        break;
      case ExchangeProviderDescription.letsExchange:
        displayLetsExchange = !displayLetsExchange;
        break;
      case ExchangeProviderDescription.stealthEx:
        displayStealthEx = !displayStealthEx;
        break;
      case ExchangeProviderDescription.xoSwap:
        displayXOSwap = !displayXOSwap;
        break;
      case ExchangeProviderDescription.swapTrade:
        displaySwapTrade = !displaySwapTrade;
        break;
      case ExchangeProviderDescription.swapsXyz:
        displaySwapXyz = !displaySwapXyz;
        break;
      case ExchangeProviderDescription.nearIntents:
        displayNearIntents = !displayNearIntents;
        break;
      case ExchangeProviderDescription.all:
        final newValue = !displayAllTrades;
        displayChangeNow = newValue;
        displaySideShift = newValue;
        displaySimpleSwap = newValue;
        displayTrocador = newValue;
        displayExolix = newValue;
        displayChainflip = newValue;
        displayThorChain = newValue;
        displayLetsExchange = newValue;
        displayStealthEx = newValue;
        displayXOSwap = newValue;
        displaySwapTrade = newValue;
        displaySwapXyz = newValue;
        displayNearIntents = newValue;
        break;
      default:
        break;
    }
  }

  List<ActionListItem> filtered({required List<TradeListItem> trades, required WalletBase wallet}) {
    return trades;
  }
}
