import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:flutter/material.dart';

class TradeDetailsListCardItem {
  TradeDetailsListCardItem({
    required this.id,
    required this.createdAt,
    required this.pair,
    required this.onTap,
  });

  final String id;
  final String createdAt;
  final String pair;
  final void Function(BuildContext) onTap;
}

class TradeDetailsStandardListCard extends StatelessWidget {
  const TradeDetailsStandardListCard({
    Key? key,
    required this.id,
    required this.create,
    required this.pair,
    required this.currentTheme,
    required this.onTap,
  }) : super(key: key);

  final String id;
  final String create;
  final String pair;
  final MaterialThemeBase currentTheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
