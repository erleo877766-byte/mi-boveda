import 'package:cake_wallet/core/cerebro_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class CerebroSettingsPage extends StatefulWidget {
  const CerebroSettingsPage({super.key});

  @override
  State<CerebroSettingsPage> createState() => _CerebroSettingsPageState();
}

class _CerebroSettingsPageState extends State<CerebroSettingsPage> {
  late final TextEditingController _urlController;
  late final TextEditingController _apiKeyController;
  final cerebro = getIt.get<CerebroService>();
  late final SettingsStore settingsStore;

  @override
  void initState() {
    super.initState();
    settingsStore = getIt.get<SettingsStore>();
    _urlController = TextEditingController(text: settingsStore.cerebroServerUrl);
    _apiKeyController = TextEditingController(text: settingsStore.cerebroApiKey);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await settingsStore.setCerebroServerUrl(_urlController.text.trim());
    await settingsStore.setCerebroApiKey(_apiKeyController.text.trim());
    await _testConnection();
  }

  Future<void> _testConnection() async {
    await cerebro.poll();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (cerebro.connected) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            'Conectado al Cerebro (${cerebro.config?.nodes.length ?? 0} nodos sincronizados).'),
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(
            'Sin conexión. Revisa que el Cerebro esté encendido y que la URL y la API key sean correctas.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cerebro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Observer(builder: (_) {
            final Color statusColor;
            final String statusText;
            if (!cerebro.isConfigured) {
              statusColor = Colors.grey;
              statusText = 'No configurado';
            } else if (cerebro.connected) {
              statusColor = Colors.green;
              statusText = 'Conectado';
            } else {
              statusColor = Colors.red;
              statusText = 'Sin conexión';
            }
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, color: statusColor, size: 12),
                        const SizedBox(width: 8),
                        Text('Estado: $statusText', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    if (cerebro.lastSync != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Última sincronización: ${cerebro.lastSync}',
                            style: theme.textTheme.bodySmall),
                      ),
                    if (cerebro.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Error: ${cerebro.error}', style: theme.textTheme.bodySmall),
                      ),
                    if (cerebro.config != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                            'Monedas: ${cerebro.config!.coins.length} · Nodos: ${cerebro.config!.nodes.length} · '
                            'Kill-switch: ${cerebro.config!.globalEnabled ? "OFF" : "ON"}',
                            style: theme.textTheme.bodySmall),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL del Cerebro',
              hintText: 'http://192.168.1.10:8787',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'API key (opcional)',
              hintText: 'x-api-key del Cerebro',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar y probar conexión'),
          ),
          const SizedBox(height: 8),
          Text(
            'Cómo conectar: en el Cerebro (en tu PC) abre Panel → verás la dirección como '
            '"http://192.168.x.x:8787" y la clave API en Ajustes. Pon aquí la misma dirección '
            'y la misma clave API (si la dejaste vacía en el Cerebro, deja este campo vacío).',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Los nodos del Cerebro se sincronizan automáticamente en cada refresco '
            '(cada 30 segundos y al arrancar la app). Los avisos y el kill-switch se aplican '
            'de inmediato y también se usan los últimos valores guardados sin conexión.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
