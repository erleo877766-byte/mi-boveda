import 'dart:async';

import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'exchange_trade_view_model.g.dart';

class ExchangeTradeViewModel = ExchangeTradeViewModelBase with _$ExchangeTradeViewModel;

abstract class ExchangeTradeViewModelBase with Store {
  ExchangeTradeViewModelBase();

  @observable
  Trade trade = Trade(
    id: '',
    provider: throw UnimplementedError(),
    from: CryptoCurrency.btc,
    to: CryptoCurrency.btc,
    amount: 0,
    createdAt: DateTime.now(),
  );

  @observable
  bool isSendable = true;

  late final _SendViewModelStub sendViewModel = _SendViewModelStub();

  Timer? timer;

  PaymentURI? get paymentUri => null;

  String get sendAmountFiatFormatted => '';

  String get pendingTransactionFeeFiatAmountFormatted => '';

  String getReceiveAmountFiatFormatted(String amount) => '';

  Future<void> confirmSending() async {}
}

class _SendViewModelStub {
  ExecutionState get state => ExecutedSuccessfullyState();
  WalletBase get wallet => throw UnimplementedError();
  dynamic get hardwareWalletViewModel => null;
  WalletType get walletType => throw UnimplementedError();
  dynamic get pendingTransaction => null;
  Future<void> commitTransaction(BuildContext context) async {}
}
