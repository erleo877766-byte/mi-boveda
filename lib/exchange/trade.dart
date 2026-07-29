import 'package:cw_core/crypto_currency.dart';
import 'package:hive/hive.dart';
import 'exchange_provider_description.dart';
import 'trade_state.dart';

class Trade extends HiveObject {
  static const tradeTypeId = 0;

  final String id;
  final ExchangeProviderDescription provider;
  final CryptoCurrency from;
  final CryptoCurrency to;
  final double amount;
  final double fee;
  String txId;
  final DateTime createdAt;
  TradeState state;
  int stateRaw;
  final String payinAddress;
  final String payoutAddress;
  final String? walletId;

  Trade({
    required this.id,
    required this.provider,
    required this.from,
    required this.to,
    required this.amount,
    this.fee = 0,
    this.txId = '',
    required this.createdAt,
    this.state = TradeState.pending,
    this.stateRaw = 0,
    this.payinAddress = '',
    this.payoutAddress = '',
    this.walletId,
  });

  static const boxName = 'Trades';
  static const boxKey = 0;

  String amountFormatted() => amount.toStringAsFixed(8);
  String receiveAmountFormatted() => (amount - fee).toStringAsFixed(8);

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider.raw,
    'from': from.title,
    'to': to.title,
    'amount': amount,
    'fee': fee,
    'txId': txId,
    'createdAt': createdAt.toIso8601String(),
    'state': state.index,
    'payinAddress': payinAddress,
    'payoutAddress': payoutAddress,
    'walletId': walletId,
  };
}
