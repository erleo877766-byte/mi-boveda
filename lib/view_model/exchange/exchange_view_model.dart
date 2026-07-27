import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/exchange/limits_state.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/limits.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'exchange_view_model.g.dart';

class ExchangeViewModel = ExchangeViewModelBase with _$ExchangeViewModel;

abstract class ExchangeViewModelBase with Store {
  ExchangeViewModelBase();

  @observable
  CryptoCurrency depositCurrency = CryptoCurrency.xmr;

  @observable
  CryptoCurrency receiveCurrency = CryptoCurrency.xmr;

  @observable
  WalletBase? wallet;

  @observable
  String depositAmount = '';

  @observable
  String receiveAmount = '';

  @observable
  String depositAddress = '';

  @observable
  String receiveAddress = '';

  @observable
  String receiveAddressExtraId = '';

  @observable
  String? receiveAddressDisplayName;

  @observable
  bool isFixedRateMode = false;

  @observable
  bool isSendAllEnabled = false;

  @observable
  bool isSendFromExternal = false;

  @observable
  bool isReceiveAmountEntered = false;

  @observable
  bool isReceiveAmountEditable = false;

  @observable
  bool isDepositAddressEnabled = true;

  @observable
  ExchangeTradeState tradeState = TradeIsCreating();

  @observable
  double bestRate = 0.0;

  @observable
  BestRateProviderInfo? bestRateProvider;

  @observable
  dynamic forcedProvider;

  @observable
  double forcedProviderRate = 0.0;

  @observable
  dynamic providerDisplay;

  @observable
  List<dynamic> providerList = [];

  @observable
  List<dynamic> selectedProviders = [];

  @observable
  SyncStatus status = SyncedSyncStatus();

  @observable
  Limits limits = Limits(min: 0, max: 0);

  @observable
  LimitsState limitsState = LimitsIsLoading();

  @observable
  bool useDepositBaseUnit = false;

  @observable
  bool useReceiveBaseUnit = false;

  @observable
  bool hasAllAmount = false;

  @observable
  bool forceDecentralizedExchanges = false;

  @observable
  bool tradeStarted = false;

  @observable
  bool hasDepositAmount = false;

  @observable
  String depositAmountCanonical = '';

  @observable
  String receiveAmountFiatFormatted = '';

  @observable
  FiatCurrency fiat = FiatCurrency.usd;

  List<Currency> depositCurrencies = [];
  List<Currency> receiveCurrencies = [];

  AmountParsingProxy get amountParsingProxy => AmountParsingProxy();

  BestRateSync get bestRateSync => BestRateSync();

  UnspentCoinsListViewModel? get unspentCoinsListViewModel => null;

  void changeDepositCurrency({required CryptoCurrency currency}) {}
  void changeReceiveCurrency({required CryptoCurrency currency}) {}
  void changeDepositAmount({required String amount}) {}
  void changeReceiveAmount({required String amount}) {}
  void enableFixedRateMode() {}
  void enableSendAllAmount() {}
  void reverseSwapDirection() {}
  void createTrade() {}
  void reset() {}
  bool shouldDisplayTOTP() => false;
  void calculateBestRate() {}
  void setCanonicalReceiveAmount(String amount) {}
  void setDepositAmountFromFiat({required String fiatAmount}) {}
  void setReceiveAmountFromFiat({required String fiatAmount}) {}
  bool useSameWalletAddress(CryptoCurrency currency) => false;
  Future<void> fetchFiatPrice(CryptoCurrency currency) async {}
  void loadLimits() {}
  void dispose() {}
  void showFiatCurrencyPicker(BuildContext context) {}
  void setForcedProvider(dynamic provider) {}
  void toggleForceDecentralizedExchanges() {}
  void dismissDecentralizedExchangesPrompt() {}
}

class BestRateProviderInfo {
  final dynamic description;
  final String title;
  BestRateProviderInfo({required this.description, required this.title});
}

class BestRateSync {
  void cancel() {}
}

class AmountParsingProxy {
  String asDisplayStringWithSymbol(dynamic amount) => '';
  String getCryptoSymbol(CryptoCurrency currency) => currency.title;
  FiatCurrency get fiat => FiatCurrency.usd;
}

class FiatCurrency {
  final String title;
  final String name;
  const FiatCurrency._(this.title, this.name);
  static const usd = FiatCurrency._('USD', 'usd');
}

class TradeIsCreating implements ExchangeTradeState {}
