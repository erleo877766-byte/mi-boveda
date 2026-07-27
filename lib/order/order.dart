import 'package:hive/hive.dart';
import 'order_provider_description.dart';

class Order extends HiveObject {
  static const orderTypeId = 0;

  static const boxName = 'Orders';
  static const boxKey = 0;

  final String id;
  final OrderProviderDescription orderProvider;
  final String orderSource;
  final String address;
  final double amount;
  final DateTime createdAt;
  final OrderState state;
  final String? walletId;

  Order({
    required this.id,
    required this.orderProvider,
    this.orderSource = '',
    required this.address,
    required this.amount,
    required this.createdAt,
    this.state = OrderState.completed,
    this.walletId,
  });
}

enum OrderState { pending, completed, failed }
