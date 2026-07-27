import 'package:flutter/material.dart';

class DetailsListStatusItem {
  DetailsListStatusItem({
    required this.title,
    required this.value,
    this.status,
  });

  final String title;
  final String value;
  final String? status;
}

class TradeDetailsStatusItem extends StatelessWidget {
  const TradeDetailsStatusItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
