import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';

class StandartListItem extends TransactionDetailsListItem {
  StandartListItem({
    required String super.title,
    required String super.value,
    super.key,
  });

  @override
  String get id => '';

  @override
  String get createdAt => '';

  @override
  String get pair => '';

  @override
  void Function(BuildContext) get onTap => (_) {};
}
