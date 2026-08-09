import 'package:cake_wallet/exchange/trade.dart';

abstract class ExchangeTradeState {}

class ExchangeTradeStateInitial extends ExchangeTradeState {}

class TradeIsCreating extends ExchangeTradeState {}

class TradeIsCreatedSuccessfully extends ExchangeTradeState {
  TradeIsCreatedSuccessfully({required this.trade});

  final Trade trade;
}

class TradeIsCreatedFailure extends ExchangeTradeState {
  TradeIsCreatedFailure({required this.title, required this.error});

  final String title;
  final String error;
}

/// Orden de intercambio propio enviada al Cerebro, esperando aprobación del admin.
class TradeIsErleoPending extends ExchangeTradeState {
  TradeIsErleoPending({
    required this.orderId,
    this.estReceive,
    this.estNetToAmount,
    this.commissionPercent,
  });

  final String orderId;

  /// Monto estimado que la app calculó antes de comisión.
  final double? estReceive;

  /// Neto estimado tras descontar la comisión % del admin.
  final double? estNetToAmount;

  /// % de comisión que cobra el admin.
  final double? commissionPercent;
}

/// El Cerebro aprobó la orden: el admin está ejecutando el envío manual.
class TradeIsErleoApproved extends ExchangeTradeState {
  TradeIsErleoApproved({required this.orderId, this.netToAmount, this.commissionUsd, this.commissionPercent});

  final String orderId;
  final double? netToAmount;
  final double? commissionUsd;
  final double? commissionPercent;
}

/// El Cerebro confirmó el envío: intercambio completado por el admin.
class TradeIsErleoCompleted extends ExchangeTradeState {
  TradeIsErleoCompleted({required this.orderId, this.netToAmount});

  final String orderId;
  final double? netToAmount;
}

/// El Cerebro rechazó la orden: la app mostrará el mensaje oficial del mínimo.
class TradeIsErleoRejected extends ExchangeTradeState {
  TradeIsErleoRejected({required this.orderId, this.reason});

  final String orderId;
  final String? reason;
}

/// Fallo al comunicarse con el Cerebro (offline, no configurado, etc).
class TradeIsErleoError extends ExchangeTradeState {
  TradeIsErleoError({required this.error});

  final String error;
}
