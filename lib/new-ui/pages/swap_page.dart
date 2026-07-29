import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class SwapPage extends BasePage {
  SwapPage();

  static const initialIsEmptyOnDesktop = false;

  @override
  String get title => S.current.swap;

  @override
  Widget body(BuildContext context) {
    return Center(child: Text('Swap is not available', style: TextStyle(fontSize: 18)));
  }
}

class NewSwapPage extends StatefulWidget {
  NewSwapPage();

  @override
  State<NewSwapPage> createState() => _NewSwapPageState();
}

class _NewSwapPageState extends State<NewSwapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).swap)),
      body: Center(child: Text('Swap is not available', style: TextStyle(fontSize: 18))),
    );
  }
}
