import 'package:shared_preferences/shared_preferences.dart';

/// Persists the Watchtower server URL and optional API key across sessions.
class ServerConfig {
  static const _urlKey = 'watchtower_server_url';
  static const _apiKeyKey = 'watchtower_api_key';

  static ServerConfig? _instance;

  static ServerConfig get instance {
    assert(_instance != null, 'ServerConfig.init() must be called before use.');
    return _instance!;
  }

  String? serverUrl;
  String? apiKey;

  ServerConfig._({this.serverUrl, this.apiKey});

  /// Must be awaited in main() before runApp().
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = ServerConfig._(
      serverUrl: prefs.getString(_urlKey),
      apiKey: prefs.getString(_apiKeyKey),
    );
  }

  bool get isConfigured => serverUrl != null && serverUrl!.isNotEmpty;

  Future<void> save({required String url, String? key}) async {
    serverUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    apiKey = (key == null || key.trim().isEmpty) ? null : key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, serverUrl!);
    if (apiKey != null) {
      await prefs.setString(_apiKeyKey, apiKey!);
    } else {
      await prefs.remove(_apiKeyKey);
    }
  }

  Future<void> clear() async {
    serverUrl = null;
    apiKey = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_urlKey);
    await prefs.remove(_apiKeyKey);
  }
}
