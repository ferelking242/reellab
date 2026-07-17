import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:tiktok_flutter/data/server_config.dart';

class ConnectServerScreen extends StatefulWidget {
  /// Called after the user saves a valid configuration.
  final VoidCallback? onConnected;

  const ConnectServerScreen({super.key, this.onConnected});

  @override
  State<ConnectServerScreen> createState() => _ConnectServerScreenState();
}

class _ConnectServerScreenState extends State<ConnectServerScreen> {
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();

  bool _testing = false;
  String? _statusMsg;
  bool _statusOk = false;

  @override
  void initState() {
    super.initState();
    final config = ServerConfig.instance;
    if (config.serverUrl != null) _urlCtrl.text = config.serverUrl!;
    if (config.apiKey != null) _keyCtrl.text = config.apiKey!;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  // ── Test ───────────────────────────────────────────────────────────────────

  Future<void> _test() async {
    final url =
        _urlCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');
    if (url.isEmpty) {
      _setStatus(ok: false, msg: 'Entrez une URL de serveur.');
      return;
    }

    setState(() {
      _testing = true;
      _statusMsg = null;
    });

    try {
      // 1 — ping
      final pingRes = await http
          .get(Uri.parse('$url/api/ping'))
          .timeout(const Duration(seconds: 10));

      if (pingRes.statusCode != 200) {
        throw Exception('Ping HTTP ${pingRes.statusCode}');
      }

      final ping = jsonDecode(pingRes.body) as Map<String, dynamic>;
      final ok = ping['ok'] == true || ping['status'] == 'ok';
      if (!ok) throw Exception('Réponse ping invalide');

      final version = (ping['version'] as String?) ?? '?';

      // 2 — sources count
      final key = _keyCtrl.text.trim();
      final headers =
          key.isNotEmpty ? {'x-api-key': key} : <String, String>{};
      final srcRes = await http
          .get(Uri.parse('$url/api/sources'), headers: headers)
          .timeout(const Duration(seconds: 15));

      int count = 0;
      if (srcRes.statusCode == 200) {
        final body = jsonDecode(srcRes.body) as Map<String, dynamic>;
        count = (body['count'] as int?) ??
            (body['sources'] as List?)?.length ??
            0;
      }

      _setStatus(
        ok: true,
        msg: '✓ Serveur OK — $count sources disponibles (version $version)',
      );
    } on TimeoutException {
      _setStatus(ok: false, msg: 'Délai dépassé — serveur inaccessible.');
    } catch (e) {
      _setStatus(ok: false, msg: 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _setStatus({required bool ok, required String msg}) {
    if (!mounted) return;
    setState(() {
      _statusOk = ok;
      _statusMsg = msg;
    });
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final url =
        _urlCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');
    if (url.isEmpty) {
      _setStatus(ok: false, msg: 'Entrez une URL avant de sauvegarder.');
      return;
    }
    final key = _keyCtrl.text.trim();
    await ServerConfig.instance
        .save(url: url, key: key.isEmpty ? null : key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Serveur sauvegardé ✓'),
            duration: Duration(seconds: 2)),
      );
    }
    widget.onConnected?.call();
  }

  // ── Clear ──────────────────────────────────────────────────────────────────

  Future<void> _clear() async {
    await ServerConfig.instance.clear();
    setState(() {
      _urlCtrl.clear();
      _keyCtrl.clear();
      _statusMsg = null;
      _statusOk = false;
    });
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final config = ServerConfig.instance;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Connecter un serveur',
            style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Description
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Configure l\'URL de ton serveur Watchtower et la clé API. '
              'Teste la connexion pour choisir quelle source afficher par défaut.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),

          // URL
          _label('URL du serveur'),
          const SizedBox(height: 8),
          _inputField(
            controller: _urlCtrl,
            hint: 'https://monserveur.replit.app',
            keyboardType: TextInputType.url,
            suffix: IconButton(
              icon: const Icon(Icons.paste, color: Colors.white54),
              onPressed: () async {
                final d = await Clipboard.getData('text/plain');
                if (d?.text != null && mounted) {
                  setState(() => _urlCtrl.text = d!.text!.trim());
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // API key
          _label('Clé API (optionnel)'),
          const SizedBox(height: 8),
          _inputField(
            controller: _keyCtrl,
            hint: 'Laisse vide si pas de clé configurée',
            obscure: true,
          ),
          const SizedBox(height: 20),

          // Status banner
          if (_statusMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _statusOk
                    ? Colors.green.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _statusOk ? Colors.green : Colors.red, width: 1),
              ),
              child: Text(
                _statusMsg!,
                style: TextStyle(
                    color: _statusOk ? Colors.green[300] : Colors.red[300],
                    fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    foregroundColor: Colors.white70,
                  ),
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white54))
                      : const Icon(Icons.wifi_tethering),
                  label: Text(_testing ? 'Test...' : 'Tester'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 250, 45, 108),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Sauvegarder'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Debug
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Debug',
                    style: TextStyle(color: Colors.white30, fontSize: 11)),
                const SizedBox(height: 8),
                _debugLine(
                    'URL: ${_urlCtrl.text.isEmpty ? '(vide)' : _urlCtrl.text}'),
                _debugLine(
                    'Clé: ${_keyCtrl.text.isEmpty ? '(aucune)' : '****'}'),
                _debugLine(
                  config.isConfigured
                      ? 'Serveur configuré ✓'
                      : 'Aucun serveur configuré — configure un serveur pour voir du contenu',
                  color: config.isConfigured ? Colors.green[300] : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Clear
          TextButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.delete_outline,
                color: Colors.white30, size: 16),
            label: const Text('Effacer la config (retour mock)',
                style: TextStyle(color: Colors.white30, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _debugLine(String text, {Color? color}) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: TextStyle(
              color: color ?? Colors.white40,
              fontSize: 11,
              fontFamily: 'monospace'),
        ),
      );
}
