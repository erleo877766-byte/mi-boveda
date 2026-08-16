import "package:cake_wallet/core/cerebro_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

/// Aviso de "Nueva versión disponible" gestionado desde el panel del Cerebro.
/// Se muestra solo si la versión instalada es menor que la publicada y hay un
/// enlace de descarga para la plataforma actual (APK en móvil, EXE en Windows).
class CerebroUpdateBanner extends StatelessWidget {
  const CerebroUpdateBanner({super.key});

  /// Interpreta versiones "X.Y.Z" tolerando sufijos (build, beta, etc.).
  static int? _parse(String version) {
    try {
      final parts = version.split("+").first.split("-").first.split(".");
      if (parts.length < 3) {
        return null;
      }
      return int.parse(parts[0]) * 100000 +
          int.parse(parts[1]) * 1000 +
          int.parse(parts[2]);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cerebro = getIt.get<CerebroService>();
    final settings = getIt.get<SettingsStore>();
    return ListenableBuilder(
      listenable: cerebro,
      builder: (context, _) {
        final latest = cerebro.latestVersion;
        if (latest == null) {
          return const SizedBox.shrink();
        }

        final installed = _parse(settings.appVersion);
        final available = _parse(latest);
        if (installed == null || available == null) {
          return const SizedBox.shrink();
        }

        final isDesktop = !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.windows ||
                defaultTargetPlatform == TargetPlatform.linux ||
                defaultTargetPlatform == TargetPlatform.macOS);
        final primary = isDesktop ? cerebro.exeUrl : cerebro.apkUrl;
        final mirror = isDesktop ? cerebro.exeMirrorUrl : cerebro.apkMirrorUrl;
        if (primary == null && mirror == null) {
          return const SizedBox.shrink();
        }
        if (available <= installed) {
          return const SizedBox.shrink();
        }

        final scheme = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.system_update_alt_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Nueva versión disponible (v$latest)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Descarga la última versión para tener todas las correcciones y novedades.",
                style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (primary != null)
                    Expanded(
                      child: _Button(
                        label: "Descargar",
                        onTap: () => launchUrl(
                          Uri.parse(primary),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ),
                  if (primary != null && mirror != null) const SizedBox(width: 8),
                  if (mirror != null)
                    Expanded(
                      child: _Button(
                        label: "Espejo",
                        onTap: () => launchUrl(
                          Uri.parse(mirror),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        backgroundColor: scheme.primary.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
