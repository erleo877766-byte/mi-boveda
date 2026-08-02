import 'package:cake_wallet/core/cerebro_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/version_comparator.dart';
import 'package:flutter/material.dart';

class CerebroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cerebro = getIt.get<CerebroService>();
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: cerebro,
      builder: (context, _) {
      final announcements = cerebro.activeAnnouncements;
      final killSwitch = cerebro.killSwitchActive;
      final Widget? content;
      Color background;

      final minVersion = cerebro.minAppVersion;
      var isOutdated = false;
      if (minVersion.isNotEmpty) {
        try {
          isOutdated = VersionComparator.isVersion1Greater(
              v1: minVersion, v2: getIt.get<SettingsStore>().appVersion);
        } catch (_) {}
      }
      if (isOutdated) {
        content = Row(
          children: [
            const Icon(Icons.system_update_alt_rounded, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Actualización requerida: esta app (${getIt.get<SettingsStore>().appVersion}) '
                'es anterior a la versión mínima ($minVersion). Actualiza para continuar con normalidad.',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
        background = theme.colorScheme.errorContainer;
      } else if (killSwitch) {
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
      } else if (announcements.isNotEmpty) {
        content = Row(
          children: [
            const Icon(Icons.campaign_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < announcements.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    Text(
                        announcements[i]['title'] as String? ?? '',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(announcements[i]['body'] as String? ?? '',
                        style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        );
        background = theme.colorScheme.tertiaryContainer;
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
      } else {
        content = null;
        background = Colors.transparent;
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
