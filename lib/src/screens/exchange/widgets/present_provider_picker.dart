import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:flutter/material.dart';

class PresentProviderPicker extends StatelessWidget {
  const PresentProviderPicker({Key? key, required this.exchangeViewModel})
      : super(key: key);

  final ExchangeViewModel exchangeViewModel;

  void presentProviderPicker(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
