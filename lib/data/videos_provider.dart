import 'dart:convert';

import 'package:watchtower_client/watchtower_client.dart' as sdk;

import 'package:tiktok_flutter/data/server_config.dart';
import 'package:tiktok_flutter/data/video.dart';

class VideosAPI {
  List<Video> listVideos = [];
  bool isLoading = false;
  String? error;
  int _page = 1;
  String? _sourceId;

  VideosAPI() {
    load();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    try {
      final config = ServerConfig.instance;
      if (!config.isConfigured) {
        error =
            'Aucun serveur configuré — configure un serveur pour voir du contenu.';
        listVideos = [];
        return;
      }

      final client = sdk.WatchtowerClient(
        url: config.serverUrl!,
        apiKey: config.apiKey,
      );

      try {
        final ok = await client.ping();
        if (!ok) {
          error = 'Serveur inaccessible. Vérifie l\'URL dans Paramètres.';
          listVideos = [];
          return;
        }

        final sources = await client.sources.list();
        final videoSources =
            sources.where((s) => s.itemType == sdk.ItemType.video).toList();

        if (videoSources.isEmpty) {
          error = 'Aucune source vidéo disponible sur ce serveur.';
          listVideos = [];
          return;
        }

        // Prefer Miraculum (id 1900000001) — great multi-lang video source.
        final source = videoSources.firstWhere(
          (s) =>
              s.id == '1900000001' ||
              s.name.toLowerCase().contains('miraculum'),
          orElse: () => videoSources.first,
        );
        _sourceId = source.id;

        final page = await client.sources.popular(source.id, page: 1);
        listVideos =
            page.items.map(_toVideo).where((v) => v.url.isNotEmpty).toList();
        _page = 1;
      } finally {
        client.close();
      }
    } catch (e) {
      error = 'Erreur : $e';
      listVideos = [];
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadMore() async {
    if (_sourceId == null || isLoading) return;
    isLoading = true;
    try {
      final config = ServerConfig.instance;
      if (!config.isConfigured) return;
      final client = sdk.WatchtowerClient(
        url: config.serverUrl!,
        apiKey: config.apiKey,
      );
      try {
        _page += 1;
        final page = await client.sources.popular(_sourceId!, page: _page);
        listVideos
            .addAll(page.items.map(_toVideo).where((v) => v.url.isNotEmpty));
      } finally {
        client.close();
      }
    } catch (_) {
      _page -= 1;
    } finally {
      isLoading = false;
    }
  }

  /// Converts a [sdk.FeedItem] to a [Video].
  ///
  /// Some sources (e.g. Miraculum) encode extra data as a JSON string inside
  /// [FeedItem.link] — we decode it to extract hd/sd URLs, creator, title, etc.
  Video _toVideo(sdk.FeedItem item) {
    Map<String, dynamic> decoded = {};
    try {
      final raw = item.link;
      if (raw.startsWith('{')) {
        decoded = jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (_) {}

    final hd = (decoded['hd'] as String?) ?? '';
    final sd = (decoded['sd'] as String?) ?? hd;
    final url = hd.isNotEmpty
        ? hd
        : (sd.isNotEmpty ? sd : (decoded.isEmpty ? item.link : ''));
    final creator =
        (decoded['creator'] as String?) ?? item.author ?? item.name;
    final title = (decoded['title'] as String?) ?? item.name;
    final poster = (decoded['poster'] as String?) ?? item.imageUrl ?? '';
    final likes = (decoded['likes'] ?? 0).toString();

    return Video(
      id: url,
      user: creator,
      userPic: poster,
      videoTitle: title,
      songName: creator,
      likes: likes,
      comments: '0',
      url: url,
      sdUrl: sd.isNotEmpty ? sd : url,
    );
  }
}
