import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thrown when Watchtower's local server can't be reached — i.e. the
/// Watchtower app isn't running (or hasn't been opened yet) on this device.
class WatchtowerNotRunningException implements Exception {
  final String message;
  WatchtowerNotRunningException([this.message = 'Watchtower ne répond pas']);
  @override
  String toString() => message;
}

/// A source exposed by Watchtower (e.g. the RedGIFs extension).
class WatchtowerSource {
  final String id;
  final String name;
  WatchtowerSource({required this.id, required this.name});

  factory WatchtowerSource.fromJson(Map<String, dynamic> json) =>
      WatchtowerSource(id: '${json['id']}', name: json['name'] ?? '');
}

/// One raw item returned by /api/source/<id>/popular|latest|search.
/// RedGIFs (and other "reel" extensions) embed the real playable data as a
/// JSON string inside `link` — see watchtower-extensions'
/// src/watch/nsfw/multi/redgifs.js `_gifToItem()`.
class WatchtowerItem {
  final String name;
  final String imageUrl;
  final String hd;
  final String sd;
  final String creator;
  final String title;
  final String likes;
  final String views;

  WatchtowerItem({
    required this.name,
    required this.imageUrl,
    required this.hd,
    required this.sd,
    required this.creator,
    required this.title,
    required this.likes,
    required this.views,
  });

  factory WatchtowerItem.fromManga(Map<String, dynamic> m) {
    Map<String, dynamic> decoded = const {};
    try {
      final raw = m['link'];
      if (raw is String) {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) decoded = parsed;
      }
    } catch (_) {
      // `link` wasn't JSON (e.g. a plain URL) — fall back to empty map,
      // callers use m['imageUrl']/m['link'] directly in that case.
    }
    final imageUrl = (m['imageUrl'] as String?) ?? decoded['poster'] ?? '';
    return WatchtowerItem(
      name: (m['name'] as String?) ?? decoded['creator'] ?? 'Watchtower',
      imageUrl: imageUrl,
      hd: decoded['hd'] ?? '',
      sd: decoded['sd'] ?? decoded['hd'] ?? (m['link'] is String && decoded.isEmpty ? m['link'] : ''),
      creator: decoded['creator'] ?? (m['name'] as String?) ?? '',
      title: decoded['title'] ?? (m['description'] as String?) ?? '',
      likes: '${decoded['likes'] ?? ''}',
      views: '${decoded['views'] ?? ''}',
    );
  }
}

/// HTTP client for Watchtower's embedded local server
/// (lib/remote/remote_server_service.dart in the Watchtower app, port 4567).
///
/// Watchtower and this app both run on the *same physical device*, so we
/// always talk to the loopback interface (127.0.0.1) — no pairing, no LAN
/// discovery, no account needed. This avoids embedding a QuickJS engine (and
/// the whole extension runtime) inside this app: Watchtower does the JS
/// extension execution and simply exposes the results as JSON over HTTP
/// while it's running in the background.
class WatchtowerClient {
  WatchtowerClient._();
  static final WatchtowerClient instance = WatchtowerClient._();

  /// Candidate base URLs, tried in order. 10.0.2.2 is the Android emulator's
  /// alias for the host loopback, useful only when testing in an emulator
  /// where Watchtower runs on the host instead of the same virtual device.
  static const List<String> _candidateBases = [
    'http://127.0.0.1:4567',
    'http://localhost:4567',
  ];

  String? _workingBase;

  Future<String> _base() async {
    if (_workingBase != null) return _workingBase!;
    for (final base in _candidateBases) {
      try {
        final res = await http
            .get(Uri.parse('$base/api/ping'))
            .timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          _workingBase = base;
          return base;
        }
      } catch (_) {
        // try next candidate
      }
    }
    throw WatchtowerNotRunningException();
  }

  /// True once we've confirmed Watchtower answers on the loopback interface.
  Future<bool> isAvailable() async {
    try {
      await _base();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Forces re-probing the candidate URLs (e.g. after the user is told to
  /// open Watchtower and taps "Retry").
  void resetConnection() => _workingBase = null;

  Future<List<WatchtowerSource>> getSources() async {
    final base = await _base();
    final res = await http.get(Uri.parse('$base/api/sources'));
    if (res.statusCode != 200) throw WatchtowerNotRunningException();
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['sources'] as List? ?? []);
    return list
        .cast<Map<String, dynamic>>()
        .map(WatchtowerSource.fromJson)
        .toList();
  }

  /// Finds the RedGIFs extension source. Returns null if the user hasn't
  /// installed/enabled it inside Watchtower yet.
  Future<WatchtowerSource?> findRedgifsSource() async {
    final sources = await getSources();
    for (final s in sources) {
      if (s.name.toLowerCase().contains('redgif')) return s;
    }
    return null;
  }

  Future<List<WatchtowerItem>> getPopular(String sourceId, {int page = 1}) =>
      _getList('popular', sourceId, page);

  Future<List<WatchtowerItem>> getLatest(String sourceId, {int page = 1}) =>
      _getList('latest', sourceId, page);

  Future<List<WatchtowerItem>> search(String sourceId, String query,
      {int page = 1}) async {
    final base = await _base();
    final uri = Uri.parse(
        '$base/api/source/$sourceId/search?q=${Uri.encodeQueryComponent(query)}&page=$page');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw WatchtowerNotRunningException();
    return _parseMangas(res.body);
  }

  Future<List<WatchtowerItem>> _getList(
      String endpoint, String sourceId, int page) async {
    final base = await _base();
    final uri = Uri.parse('$base/api/source/$sourceId/$endpoint?page=$page');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw WatchtowerNotRunningException();
    return _parseMangas(res.body);
  }

  List<WatchtowerItem> _parseMangas(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final mangas = (decoded['mangas'] as List? ?? []);
    return mangas
        .cast<Map<String, dynamic>>()
        .map(WatchtowerItem.fromManga)
        .where((it) => it.hd.isNotEmpty || it.sd.isNotEmpty)
        .toList();
  }
}
