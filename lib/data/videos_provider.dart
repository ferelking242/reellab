import 'package:tiktok_flutter/data/video.dart';
import 'package:tiktok_flutter/data/watchtower_client.dart';

/// Replaces the old Firebase/Firestore-backed VideosAPI. The feed is now
/// sourced live from Watchtower's RedGIFs extension via WatchtowerClient —
/// see watchtower_client.dart for how the two apps talk to each other.
class VideosAPI {
  List<Video> listVideos = <Video>[];
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
      final client = WatchtowerClient.instance;
      final source = await client.findRedgifsSource();
      if (source == null) {
        error =
            'Extension RedGIFs introuvable. Ouvre Watchtower, active-la dans '
            'Extensions, puis reviens ici.';
        listVideos = [];
        return;
      }
      _sourceId = source.id;
      final items = await client.getPopular(_sourceId!, page: 1);
      listVideos = items.map(_toVideo).toList();
      _page = 1;
    } on WatchtowerNotRunningException catch (e) {
      error = 'Watchtower n\'est pas lancé. Ouvre l\'app Watchtower en '
          'arrière-plan puis réessaie. (${e.message})';
      listVideos = [];
    } catch (e) {
      error = 'Erreur de chargement : $e';
      listVideos = [];
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadMore() async {
    if (_sourceId == null || isLoading) return;
    isLoading = true;
    try {
      _page += 1;
      final items =
          await WatchtowerClient.instance.getPopular(_sourceId!, page: _page);
      listVideos.addAll(items.map(_toVideo));
    } catch (_) {
      _page -= 1;
    } finally {
      isLoading = false;
    }
  }

  Video _toVideo(WatchtowerItem item) {
    return Video(
      id: item.hd.isNotEmpty ? item.hd : item.sd,
      user: item.creator.isNotEmpty ? item.creator : item.name,
      userPic: item.imageUrl,
      videoTitle: item.title,
      songName: item.creator,
      likes: item.likes.isNotEmpty ? item.likes : '0',
      comments: '0',
      url: item.hd,
      sdUrl: item.sd,
    );
  }
}
