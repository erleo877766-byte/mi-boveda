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

part 'exchange_view_model.g.dart';

class ExchangeViewModel extends ExchangeViewModelBase {
  ExchangeViewModel();
}

abstract class ExchangeViewModelBase {
  ExchangeViewModelBase();

  CryptoCurrency depositCurrency = CryptoCurrency.xmr;
  CryptoCurrency receiveCurrency = CryptoCurrency.xmr;
  WalletBase? wallet;
  String depositAmount = '';
  String receiveAmount = '';
  String depositAddress = '';
  String receiveAddress = '';
  String receiveAddressExtraId = '';
  String? receiveAddressDisplayName;
  bool isFixedRateMode = false;
  bool isSendAllEnabled = false;
  bool isSendFromExternal = false;
  bool isReceiveAmountEntered = false;
  bool isReceiveAmountEditable = false;
  bool isDepositAddressEnabled = true;
  ExchangeTradeState tradeState = TradeIsCreating();
  double bestRate = 0.0;
  BestRateProviderInfo? bestRateProvider;
  dynamic forcedProvider;
  double forcedProviderRate = 0.0;
  dynamic providerDisplay;
  List<dynamic> providerList = [];
  List<dynamic> selectedProviders = [];
  SyncStatus status = SyncedSyncStatus();
  Limits limits = Limits(min: 0, max: 0);
  LimitsState limitsState = LimitsIsLoading();
  bool useDepositBaseUnit = false;
  bool useReceiveBaseUnit = false;
  bool hasAllAmount = false;
  bool forceDecentralizedExchanges = false;
  bool tradeStarted = false;
  bool hasDepositAmount = false;
  String depositAmountCanonical = '';
  String receiveAmountFiatFormatted = '';
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
