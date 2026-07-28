abstract class TradeState {
  const TradeState();
  
  static const pending = _TradeStatePending();
  static const complete = _TradeStateComplete();
  static const completed = _TradeStateComplete();
  static const finished = _TradeStateComplete();
  static const success = _TradeStateComplete();
  static const settled = _TradeStateComplete();
  static const traded = _TradeStateComplete();
  static const failed = _TradeStateFailed();
  static const sending = _TradeStateSending();

  int get index;
  int get raw => index;
}

class _TradeStatePending extends TradeState {
  const _TradeStatePending();
  @override
  int get index => 0;
}

class _TradeStateComplete extends TradeState {
  const _TradeStateComplete();
  @override
  int get index => 1;
}

class _TradeStateFailed extends TradeState {
  const _TradeStateFailed();
  @override
  int get index => 2;
}

class _TradeStateSending extends TradeState {
  const _TradeStateSending();
  @override
  int get index => 3;
}
