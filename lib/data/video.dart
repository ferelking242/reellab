import 'package:video_player/video_player.dart';

/// Represents one item in the feed. Populated from the JSON payload that
/// Watchtower's RedGIFs extension embeds in the `link` field of every
/// popular/latest/search result (see WatchtowerClient._decodeLink).
class Video {
  String id;
  String user;
  String userPic;
  String videoTitle;
  String songName;
  String likes;
  String comments;
  String url;
  String sdUrl;

  VideoPlayerController? controller;

  Video({
    required this.id,
    required this.user,
    required this.userPic,
    required this.videoTitle,
    required this.songName,
    required this.likes,
    required this.comments,
    required this.url,
    this.sdUrl = '',
  });

  Future<void> loadController() async {
    final source = url.isNotEmpty ? url : sdUrl;
    // ignore: deprecated_member_use
    controller = VideoPlayerController.network(source);
    await controller?.initialize();
    controller?.setLooping(true);
  }
}
