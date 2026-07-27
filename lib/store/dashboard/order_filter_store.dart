import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';

part 'order_filter_store.g.dart';

class OrderFilterStore = OrderFilterStoreBase with _$OrderFilterStore;

abstract class OrderFilterStoreBase with Store {
  OrderFilterStoreBase()
      : displayCakePay = true;

  @observable
  bool displayCakePay;

  @action
  void toggleDisplayCakePay() {
    displayCakePay = !displayCakePay;
  }

  List<ActionListItem> filtered({required List<ActionListItem> orders, required WalletBase wallet}) {
    return orders;
  }
}
