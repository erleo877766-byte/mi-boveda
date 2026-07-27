import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:flutter/material.dart';

class TrackTradeListItem extends ActionListItem {
  TrackTradeListItem({
    required this.title,
    required this.value,
    required this.onTap,
  }) : super(key: UniqueKey());

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  DateTime get date => DateTime.now();
}
