import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:mobx/mobx.dart';

part 'orders_store.g.dart';

class OrdersStore = OrdersStoreBase with _$OrdersStore;

abstract class OrdersStoreBase with Store {
  OrdersStoreBase()
      : orders = [];

  @observable
  List<OrderListItem> orders;
}
