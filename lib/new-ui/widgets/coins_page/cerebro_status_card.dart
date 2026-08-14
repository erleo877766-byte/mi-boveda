import 'package:cake_wallet/core/cerebro_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:flutter/material.dart';

/// Estado del Cerebro y comisiones de red por velocidad, para mostrar junto
/// al saldo total en la pantalla de monedas.
class CerebroStatusCard extends StatelessWidget {
  const CerebroStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cerebro = getIt.get<CerebroService>();
    return ListenableBuilder(
      listenable: cerebro,
      builder: (context, _) {
        if (!cerebro.isConfigured && !cerebro.hasReceivedConfig) {
          return const SizedBox.shrink();
        }

        final scheme = Theme.of(context).colorScheme;
        final status = cerebro.syncStatus;
        final (color, label) = switch (status) {
          'online' => (
              const Color(0xFF2ECC71),
              cerebro.erleoExchangeEnabled
                  ? 'Cerebro conectado · Erleo ACTIVO'
                  : 'Cerebro conectado · Erleo detenido',
            ),
          'error' => (const Color(0xFFE74C3C), 'Cerebro sin conexión'),
          _ => (const Color(0xFFF1C40F), 'Conectando al Cerebro…'),
        };

        final percent = cerebro.commissionPercent;
        final pctText = percent == percent.roundToDouble()
            ? percent.toInt().toString()
            : percent.toString();

        return Container(
          margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (status != 'online')
                    GestureDetector(
                      onTap: () => cerebro.poll(),
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 14, color: scheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Reintentar',
                            style: TextStyle(fontSize: 12, color: scheme.primary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Comisiones de red (por velocidad)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SpeedPill(
                    emoji: '🐢',
                    label: 'Lento',
                    price: '\$${cerebro.commissionSlowUsd.toStringAsFixed(2)}',
                    color: const Color(0xFF00C853),
                  ),
                  const SizedBox(width: 8),
                  _SpeedPill(
                    emoji: '🚶',
                    label: 'Normal',
                    price: '\$${cerebro.commissionMediumUsd.toStringAsFixed(2)}',
                    color: const Color(0xFFFFAB00),
                  ),
                  const SizedBox(width: 8),
                  _SpeedPill(
                    emoji: '⚡',
                    label: 'Rápido',
                    price: '\$${cerebro.commissionFastUsd.toStringAsFixed(2)}',
                    color: const Color(0xFFFF5252),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$pctText% adicional por intercambio administrado',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpeedPill extends StatelessWidget {
  const _SpeedPill({
    required this.emoji,
    required this.label,
    required this.price,
    required this.color,
  });

  final String emoji;
  final String label;
  final String price;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
