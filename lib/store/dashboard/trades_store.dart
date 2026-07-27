import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:mobx/mobx.dart';

part 'trades_store.g.dart';

class TradesStore = TradesStoreBase with _$TradesStore;

abstract class TradesStoreBase with Store {
  TradesStoreBase()
      : trades = [];

  @observable
  List<TradeListItem> trades;
}
