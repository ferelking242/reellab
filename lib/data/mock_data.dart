import '../models/reel_item.dart';

// ── Mock reels — vidéos publiques pour tester l'UI sans API
// Remplacer les URLs par des vraies URLs RedGIFs lors de l'intégration.
const mockReels = <ReelItem>[
  ReelItem(
    id: 'r1',
    hdUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    posterUrl: 'https://picsum.photos/seed/reel1/400/700',
    creator: 'creator_one',
    title: 'Test reel #1 — remplacer par RedGIFs',
    hasAudio: true,
    likes: 12400,
    views: 98700,
  ),
  ReelItem(
    id: 'r2',
    hdUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
    posterUrl: 'https://picsum.photos/seed/reel2/400/700',
    creator: 'creator_two',
    title: 'Test reel #2',
    hasAudio: true,
    likes: 8900,
    views: 34500,
  ),
  ReelItem(
    id: 'r3',
    hdUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
    posterUrl: 'https://picsum.photos/seed/reel3/400/700',
    creator: 'creator_three',
    title: 'Test reel #3 — verticalité OK',
    hasAudio: true,
    likes: 5100,
    views: 22000,
  ),
  ReelItem(
    id: 'r4',
    hdUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    posterUrl: 'https://picsum.photos/seed/reel4/400/700',
    creator: 'creator_one',
    title: 'Test reel #4',
    hasAudio: false,
    likes: 3300,
    views: 14000,
  ),
  ReelItem(
    id: 'r5',
    hdUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    posterUrl: 'https://picsum.photos/seed/reel5/400/700',
    creator: 'creator_four',
    title: 'Test reel #5',
    hasAudio: true,
    likes: 7200,
    views: 41000,
  ),
  ReelItem(
    id: 'r6',
    hdUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
    posterUrl: 'https://picsum.photos/seed/reel6/400/700',
    creator: 'creator_five',
    title: 'Test reel #6',
    hasAudio: true,
    likes: 19800,
    views: 120000,
  ),
];

// Mock Explorer items (miniatures avec ratio variable pour le masonry)
final mockExplorerItems = <ReelItem>[
  for (var i = 1; i <= 20; i++)
    ReelItem(
      id: 'e$i',
      hdUrl: '',
      posterUrl: 'https://picsum.photos/seed/exp$i/400/${(i.isEven ? 700 : 500)}',
      creator: 'creator_$i',
      title: 'Item explorer #$i',
      likes: i * 310,
      views: i * 1200,
      width: 9,
      height: i.isEven ? 16 : 12,
    ),
];

// Mock creators pour l'onglet Suivis
const mockCreators = <CreatorItem>[
  CreatorItem(
    username: 'alpha_creator',
    avatarUrl: 'https://picsum.photos/seed/creator1/200/200',
    bannerUrl: 'https://picsum.photos/seed/banner1/400/200',
    verified: true,
    followers: 124000,
    totalGifs: 342,
  ),
  CreatorItem(
    username: 'beta_creator',
    avatarUrl: 'https://picsum.photos/seed/creator2/200/200',
    bannerUrl: 'https://picsum.photos/seed/banner2/400/200',
    verified: false,
    followers: 89400,
    totalGifs: 210,
  ),
  CreatorItem(
    username: 'gamma_creator',
    avatarUrl: 'https://picsum.photos/seed/creator3/200/200',
    bannerUrl: 'https://picsum.photos/seed/banner3/400/200',
    verified: true,
    followers: 67200,
    totalGifs: 178,
  ),
  CreatorItem(
    username: 'delta_creator',
    avatarUrl: 'https://picsum.photos/seed/creator4/200/200',
    bannerUrl: 'https://picsum.photos/seed/banner4/400/200',
    verified: false,
    followers: 45100,
    totalGifs: 95,
  ),
  CreatorItem(
    username: 'epsilon_x',
    avatarUrl: 'https://picsum.photos/seed/creator5/200/200',
    bannerUrl: 'https://picsum.photos/seed/banner5/400/200',
    verified: true,
    followers: 201000,
    totalGifs: 480,
  ),
  CreatorItem(
    username: 'zeta_films',
    avatarUrl: 'https://picsum.photos/seed/creator6/200/200',
    bannerUrl: 'https://picsum.photos/seed/banner6/400/200',
    verified: false,
    followers: 32000,
    totalGifs: 67,
  ),
];

// Niches pour le filtre Explorer (mirror de redgifs.js)
const mockNiches = <({String id, String label})>[
  (id: 'for_you',              label: 'Pour toi'),
  (id: 'niche_just-boobs',     label: 'Just Boobs'),
  (id: 'niche_blowjobs',       label: 'Blowjobs'),
  (id: 'niche_thick-booty',    label: 'Thick Booty'),
  (id: 'niche_amateur-girls',  label: 'Amateur Girls'),
  (id: 'niche_real-couples',   label: 'Real Couples'),
  (id: 'niche_real-orgasms',   label: 'Real Orgasms'),
  (id: 'niche_curvy-chicks',   label: 'Curvy Chicks'),
  (id: 'niche_rough-sex',      label: 'Rough Sex'),
  (id: 'niche_legal-teens',    label: 'Legal Teens'),
  (id: 'niche_busty-asians',   label: 'Busty Asians'),
  (id: 'niche_goth-girls',     label: 'Goth Girls'),
  (id: 'niche_latinas',        label: 'Latinas'),
];
