abstract class ExchangeTradeState {
  const ExchangeTradeState();
}

class TradeStateCreated extends ExchangeTradeState {
  const TradeStateCreated();
}

class TradeStateWaitingPayment extends ExchangeTradeState {
  const TradeStateWaitingPayment();
}

class TradeStatePaymentSent extends ExchangeTradeState {
  const TradeStatePaymentSent();
}

class TradeStateComplete extends ExchangeTradeState {
  const TradeStateComplete();
}

class TradeStateFailed extends ExchangeTradeState {
  final String error;
  const TradeStateFailed(this.error);
}
