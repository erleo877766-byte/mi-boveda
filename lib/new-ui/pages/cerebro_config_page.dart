import 'package:cake_wallet/core/cerebro_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:flutter/material.dart';

class CerebroConfigPage extends StatefulWidget {
  const CerebroConfigPage({super.key});

  @override
  State<CerebroConfigPage> createState() => _CerebroConfigPageState();
}

class _CerebroConfigPageState extends State<CerebroConfigPage> {
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _saving = false;
  bool _testing = false;
  String? _status;
  String? _statusError;

  CerebroService get _cerebro => getIt.get<CerebroService>();
  SettingsStore get _settingsStore => getIt.get<SettingsStore>();

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    _urlController.text = _settingsStore.cerebroServerUrl;
    _apiKeyController.text = await _settingsStore.cerebroApiKey;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _status = null;
      _statusError = null;
    });
    final url = _urlController.text.trim().replaceAll(RegExp(r'/+$'), '');
    final key = _apiKeyController.text.trim();
    await _settingsStore.setCerebroServerUrl(url);
    await _settingsStore.setCerebroApiKey(key);
    await _cerebro.setApiKey(key);
    await _cerebro.poll();
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (_cerebro.connected) {
        _status = 'Conectado al Cerebro.';
      } else if (_cerebro.error != null) {
        _statusError = 'No se pudo conectar: ${_cerebro.error}';
      } else if (url.isEmpty) {
        _statusError = 'Escribe la dirección del Cerebro.';
      } else {
        _statusError = 'No se pudo conectar al Cerebro.';
      }
    });
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _status = null;
      _statusError = null;
    });
    final url = _urlController.text.trim().replaceAll(RegExp(r'/+$'), '');
    final key = _apiKeyController.text.trim();
    await _settingsStore.setCerebroServerUrl(url);
    await _settingsStore.setCerebroApiKey(key);
    await _cerebro.setApiKey(key);
    await _cerebro.poll();
    if (!mounted) return;
    setState(() {
      _testing = false;
      if (_cerebro.connected) {
        _status = 'Conectado al Cerebro.';
      } else if (_cerebro.error != null) {
        _statusError = 'No se pudo conectar: ${_cerebro.error}';
      } else {
        _statusError = 'No se pudo conectar al Cerebro.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Cerebro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Esta es la conexión que tu billetera usa para enviar los '
            'intercambios por debajo del mínimo a tu Cerebro.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Copia la dirección que ves en el panel de Mi Bóveda Cerebro '
            '(ej. http://127.0.0.1:8787) y la clave API de la pestaña Erleo.',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Dirección del Cerebro',
              hintText: 'http://127.0.0.1:8787',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Clave API',
              hintText: 'Pega la clave de la pestaña Erleo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          if (_status != null) ...[
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(_status!, style: const TextStyle(color: Colors.green))),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (_statusError != null) ...[
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(_statusError!, style: const TextStyle(color: Colors.red))),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_saving || _testing) ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Guardando…' : 'Guardar'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_saving || _testing) ? null : _test,
              icon: _testing
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_tethering_rounded),
              label: Text(_testing ? 'Probando…' : 'Probar conexión'),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _cerebro.connected
                            ? Icons.cloud_done
                            : (_cerebro.error != null ? Icons.cloud_off : Icons.cloud_queue),
                        color: _cerebro.connected
                            ? Colors.green
                            : (_cerebro.error != null ? Colors.red : theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Text(_cerebro.connected
                          ? 'Conectado'
                          : (_cerebro.error != null ? 'Sin conexión' : 'Sin configurar')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
