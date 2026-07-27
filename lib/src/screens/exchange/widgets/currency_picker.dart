import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';

class CurrencyPicker extends StatelessWidget {
  const CurrencyPicker({
    Key? key,
    this.selectedAtIndex = -1,
    required this.items,
    this.title,
    required this.hintText,
    required this.onItemSelected,
  }) : super(key: key);

  final int selectedAtIndex;
  final List<Currency> items;
  final String? title;
  final String hintText;
  final Function(Currency) onItemSelected;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
