import 'package:cake_wallet/core/cerebro_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:flutter/material.dart';

/// Indicador de estado de la conexión con el Cerebro.
/// Muestra un punto verde/rojo/amarillo según si la billetera pudo
/// sincronizar la configuración del servidor (incluido el toggle Erleo).
class CerebroConnectionStatus extends StatelessWidget {
  const CerebroConnectionStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final cerebro = getIt.get<CerebroService>();
    return ListenableBuilder(
      listenable: cerebro,
      builder: (context, _) {
        final status = cerebro.syncStatus;
        final (color, label) = switch (status) {
          'online' => (
              const Color(0xFF2ECC71),
              'Cerebro conectado${cerebro.erleoExchangeEnabled ? ' · Erleo ACTIVO' : ' · Erleo detenido'}',
            ),
          'error' => (
              const Color(0xFFE74C3C),
              'Cerebro sin conexión${cerebro.error != null ? ': ${cerebro.error}' : ''}',
            ),
          _ => (
              const Color(0xFFF1C40F),
              'Conectando al Cerebro…',
            ),
        };

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
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
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (status != 'online')
                GestureDetector(
                  onTap: () => cerebro.poll(),
                  child: Row(
                    children: [
                      const Icon(Icons.refresh_rounded,
                          size: 14, color: Color(0xFFD4AF37)),
                      const SizedBox(width: 4),
                      Text('Reintentar',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
