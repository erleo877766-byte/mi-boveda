import 'dart:io';

import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _completedKey = 'miboveda_permissions_completed';

class PermissionsGate extends StatefulWidget {
  const PermissionsGate({required this.child, super.key});

  final Widget child;

  @override
  State<PermissionsGate> createState() => _PermissionsGateState();
}

class _PermissionsGateState extends State<PermissionsGate> {
  bool _completed = false;
  bool _loading = true;
  final List<_PermissionItem> _items = <_PermissionItem>[];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyCompleted = prefs.getBool(_completedKey) ?? false;

    if (!alreadyCompleted && (Platform.isAndroid || Platform.isIOS)) {
      _items.add(_PermissionItem(
        permission: Permission.notification,
        label: 'Notificaciones',
        icon: Icons.notifications_active_outlined,
        description: 'Para avisarte cuando una operación cambie de estado',
      ));
      _items.add(_PermissionItem(
        permission: Permission.location,
        label: 'Ubicación',
        icon: Icons.location_on_outlined,
        description: 'Necesaria para ciertas funciones de la billetera',
      ));
      if (Platform.isAndroid) {
        _items.add(_PermissionItem(
          permission: Permission.sms,
          label: 'Mensajes',
          icon: Icons.sms_outlined,
          description: 'Para leer códigos de verificación de tus operaciones',
        ));
      }

      for (final item in _items) {
        item.status = await item.permission.status;
      }
    }

    if (mounted) {
      setState(() {
        _completed = alreadyCompleted;
        _loading = false;
      });
    }
  }

  bool get _allGranted => _items.isNotEmpty && _items.every((e) => e.status.isGranted);

  Future<void> _request(_PermissionItem item) async {
    final status = await item.permission.request();
    if (!mounted) return;
    setState(() => item.status = status);
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    if (!mounted) return;
    setState(() => _completed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return widget.child;

    if (_completed) return widget.child;

    if (!Platform.isAndroid && !Platform.isIOS) return widget.child;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    height: 84,
                    width: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary,
                    ),
                    child: Icon(Icons.lock_outline, size: 40, color: scheme.onPrimary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bienvenido a Mi Bóveda',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Antes de continuar, otorga los siguientes permisos. Son obligatorios para que la billetera funcione correctamente.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 28),
                  for (final item in _items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PermissionTile(
                        item: item,
                        onRequest: () => _request(item),
                      ),
                    ),
                  const SizedBox(height: 8),
                  NewPrimaryButton(
                    text: 'Continuar',
                    color: scheme.primary,
                    textColor: scheme.onPrimary,
                    disabled: !_allGranted,
                    onPressed: _finish,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _allGranted
                        ? 'Todos los permisos otorgados'
                        : 'Todos los permisos son obligatorios para continuar',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _allGranted ? Colors.greenAccent : theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionItem {
  _PermissionItem({
    required this.permission,
    required this.label,
    required this.icon,
    required this.description,
  });

  final Permission permission;
  final String label;
  final IconData icon;
  final String description;
  PermissionStatus status = PermissionStatus.denied;
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.item, required this.onRequest});

  final _PermissionItem item;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = item.status;

    final (String statusText, Color statusColor) = status.isGranted
        ? ('Otorgado', Colors.greenAccent)
        : status.isPermanentlyDenied
            ? ('Denegado (ir a ajustes)', theme.colorScheme.error)
            : status.isDenied
                ? ('Denegado', theme.colorScheme.error)
                : ('Pendiente', theme.hintColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status.isGranted
              ? Colors.greenAccent.withValues(alpha: 0.6)
              : theme.dividerColor,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(item.icon, size: 30, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  status.isGranted ? statusText : item.description,
                  style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (status.isGranted)
            const Icon(Icons.check_circle, color: Colors.greenAccent)
          else if (status.isPermanentlyDenied)
            _ActionButton(label: 'Ajustes', onPressed: openAppSettings)
          else
            _ActionButton(label: 'Permitir', onPressed: onRequest),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(color: theme.colorScheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label),
    );
  }
}
