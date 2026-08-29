import 'package:flutter/widgets.dart';

abstract class TransactionDetailsListItem {
  TransactionDetailsListItem({required this.title, required this.value, this.key});

  final String title;
  final String value;
  final Key? key;

  String get status => '';
  String get id => '';
  String get createdAt => '';
  String get pair => '';
  dynamic get onTap => null;
}
