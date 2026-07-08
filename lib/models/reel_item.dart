// ── ReelItem — modèle de données pour un reel (remplace MManga dans Watchtower)
class ReelItem {
  final String id;
  final String hdUrl;
  final String sdUrl;
  final String posterUrl;
  final String creator;
  final String title;
  final bool   hasAudio;
  final int    likes;
  final int    views;
  final double width;
  final double height;

  const ReelItem({
    required this.id,
    required this.hdUrl,
    this.sdUrl = '',
    this.posterUrl = '',
    this.creator = '',
    this.title = '',
    this.hasAudio = true,
    this.likes = 0,
    this.views = 0,
    this.width = 9,
    this.height = 16,
  });

  double get aspectRatio => width > 0 && height > 0 ? width / height : 9 / 16;
}

// ── CreatorItem — modèle créateur pour l'onglet Suivis
class CreatorItem {
  final String username;
  final String avatarUrl;
  final String bannerUrl;
  final bool   verified;
  final int    followers;
  final int    totalGifs;

  const CreatorItem({
    required this.username,
    this.avatarUrl = '',
    this.bannerUrl = '',
    this.verified = false,
    this.followers = 0,
    this.totalGifs = 0,
  });
}
