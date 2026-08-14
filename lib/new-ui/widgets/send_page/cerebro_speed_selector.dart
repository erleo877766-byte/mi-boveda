import 'package:cake_wallet/core/cerebro_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:flutter/material.dart';

/// Selector de velocidad del Cerebro con tarjetas que se marcan con su color.
class CerebroSpeedSelector extends StatelessWidget {
  const CerebroSpeedSelector({required this.value, required this.onChanged, super.key});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cerebro = getIt.get<CerebroService>();
    return ListenableBuilder(
      listenable: cerebro,
      builder: (context, _) {
        final speeds = [
          (
            key: 'slow',
            emoji: '🐢',
            label: 'Lento',
            usd: cerebro.commissionSlowUsd,
            color: const Color(0xFF00C853),
          ),
          (
            key: 'medium',
            emoji: '🚶',
            label: 'Normal',
            usd: cerebro.commissionMediumUsd,
            color: const Color(0xFFFFAB00),
          ),
          (
            key: 'fast',
            emoji: '⚡',
            label: 'Rápido',
            usd: cerebro.commissionFastUsd,
            color: const Color(0xFFFF5252),
          ),
        ];
        return Row(
          children: [
            for (final s in speeds)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SpeedCard(
                    selected: value == s.key,
                    emoji: s.emoji,
                    label: s.label,
                    price: '\$${s.usd.toStringAsFixed(2)}',
                    color: s.color,
                    onTap: () => onChanged(s.key),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SpeedCard extends StatelessWidget {
  const _SpeedCard({
    required this.selected,
    required this.emoji,
    required this.label,
    required this.price,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final String emoji;
  final String label;
  final String price;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : scheme.surfaceContainerHighest,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? color : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color.withValues(alpha: 0.2) : scheme.surfaceContainerHighest,
                border: Border.all(
                  color: selected ? color : scheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: selected ? Icon(Icons.check_rounded, size: 9, color: color) : null,
            ),
          ],
        ),
      ),
    );
  }
}
