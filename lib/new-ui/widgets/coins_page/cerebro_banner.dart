import 'package:cake_wallet/core/cerebro_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class CerebroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cerebro = getIt.get<CerebroService>();
    final theme = Theme.of(context);
    return Observer(builder: (_) {
      final announcements = cerebro.activeAnnouncements;
      final killSwitch = cerebro.killSwitchActive;
      final Widget? content;
      Color background;
      IconData icon;

      if (killSwitch) {
        content = Row(
          children: [
            const Icon(Icons.block, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cerebro desactivado: los envíos están bloqueados hasta que se reactive.',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
        background = theme.colorScheme.errorContainer;
        icon = Icons.block;
      } else if (announcements.isNotEmpty) {
        final announcement = announcements.first;
        final title = announcement['title'] as String? ?? '';
        final body = announcement['body'] as String? ?? '';
        content = Row(
          children: [
            const Icon(Icons.campaign_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(title,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (body.isNotEmpty)
                    Text(body, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        );
        background = theme.colorScheme.tertiaryContainer;
        icon = Icons.campaign_outlined;
      } else if (cerebro.isConfigured && !cerebro.connected) {
        content = Row(
          children: [
            const Icon(Icons.cloud_off, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sin conexión con el Cerebro. Se usan los ajustes guardados.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        );
        background = theme.colorScheme.surfaceContainerHighest;
        icon = Icons.cloud_off;
      } else {
        content = null;
        background = Colors.transparent;
        icon = Icons.cloud_done;
      }

      if (content == null) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: content,
        ),
      );
    });
  }
}
