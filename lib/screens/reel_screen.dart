import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../data/mock_data.dart';
import '../models/reel_item.dart';

// ── ReelScreen ──────────────────────────────────────────────────────────────
// Sandbox version — identique à Watchtower visuellement.
// Données : mock_data.dart (remplacer par appels extension lors de l'intégration).
//
// Tabs : Explorer | Suivis | Pour toi
// Pour intégrer dans Watchtower :
//   1. Remplacer ReelItem par MManga + _parseLink()
//   2. Remplacer _loadMock*() par getCustomListProvider()
//   3. Ajouter Source source param sur ReelScreen
//   4. Remplacer StatefulWidget par ConsumerStatefulWidget

const _kTabExplorer = 0;
const _kTabSuivis   = 1;
const _kTabPourToi  = 2;

// ── Media type filter ────────────────────────────────────────────────────────
enum _MediaType { all, gif, image }

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1).replaceAll('.', ',')} M';
  if (n >=    1000) return '${(n /    1000).toStringAsFixed(1).replaceAll('.', ',')} K';
  return n.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// ReelScreen — shell principal
// ─────────────────────────────────────────────────────────────────────────────

class ReelScreen extends StatefulWidget {
  const ReelScreen({super.key});

  @override
  State<ReelScreen> createState() => _ReelScreenState();
}

class _ReelScreenState extends State<ReelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _pourToiActive = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: _kTabPourToi);
    _applySystemUI(true);
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    final isPourToi = _tabs.index == _kTabPourToi;
    if (isPourToi != _pourToiActive) {
      setState(() => _pourToiActive = isPourToi);
      _applySystemUI(isPourToi);
    }
  }

  void _applySystemUI(bool pourToi) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      pourToi ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTabChanged)
      ..dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  Color get _barBg    => _pourToiActive ? Colors.black       : Colors.white;
  Color get _iconCol  => _pourToiActive ? Colors.white       : Colors.black87;
  Color get _tabSel   => _pourToiActive ? Colors.white       : Colors.black87;
  Color get _tabUnsel => _pourToiActive ? Colors.white54     : Colors.black45;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _pourToiActive ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: _pourToiActive,
        backgroundColor: _pourToiActive ? Colors.black : Colors.white,
        appBar: _buildAppBar(context),
        body: TabBarView(
          controller: _tabs,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _ExplorerTab(),
            _SuivisTab(),
            _PourToiTab(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor:        _pourToiActive ? Colors.transparent : Colors.white,
      surfaceTintColor:       Colors.transparent,
      shadowColor:            Colors.transparent,
      elevation:              0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _LiveBadge(color: _iconCol),
        ),
      ),
      title: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        dividerHeight: 0,
        indicatorWeight: 2.2,
        indicatorColor: _tabSel,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelColor: _tabSel,
        unselectedLabelColor: _tabUnsel,
        labelStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        unselectedLabelStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(text: 'Explorer'),
          Tab(text: 'Suivis'),
          Tab(text: 'Pour toi'),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search_rounded, color: _iconCol, size: 24),
          onPressed: () {},
          splashRadius: 20,
          padding: const EdgeInsets.only(right: 6),
        ),
      ],
    );
  }
}

// ── LIVE badge ────────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  final Color color;
  const _LiveBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.tv_rounded, color: color, size: 26),
        Positioned(
          right: -4, top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white, fontSize: 7,
                fontWeight: FontWeight.w900, letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EXPLORER TAB — masonry grid + GIF/Image toggle + niche chips
// ══════════════════════════════════════════════════════════════════════════════

class _ExplorerTab extends StatefulWidget {
  const _ExplorerTab();
  @override
  State<_ExplorerTab> createState() => _ExplorerTabState();
}

class _ExplorerTabState extends State<_ExplorerTab>
    with AutomaticKeepAliveClientMixin {
  int        _selNiche  = 0;
  _MediaType _mediaType = _MediaType.all;
  List<ReelItem> _items = [];
  bool _loading = false;
  bool _init    = true;
  final _scroll = ScrollController();

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) _load();
  }

  // ── SANDBOX: remplace getCustomListProvider par mock data ─────────────────
  // Dans Watchtower: ref.read(getCustomListProvider(source: source, listId: _listId, page: _page).future)
  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 200)); // simule latence réseau
    if (mounted) {
      setState(() {
        // En sandbox, on réinitialise toujours avec mockExplorerItems
        // En prod: addAll(res.list) + pagination
        _items = List.from(mockExplorerItems);
        _init  = false;
        _loading = false;
      });
    }
  }

  void _selectNiche(int idx) {
    if (idx == _selNiche && _mediaType == _MediaType.all) return;
    setState(() {
      _selNiche  = idx;
      _mediaType = _MediaType.all;
      _items     = [];
      _init      = true;
    });
    _load();
  }

  void _selectType(_MediaType t) {
    if (t == _mediaType) return;
    setState(() {
      _mediaType = t;
      _items     = [];
      _init      = true;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final left  = <ReelItem>[];
    final right = <ReelItem>[];
    for (var i = 0; i < _items.length; i++) {
      (i.isEven ? left : right).add(_items[i]);
    }

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        // ── Type filter (Tout / GIF / Image) ────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                _TypePill(label: 'Tout',  active: _mediaType == _MediaType.all,
                    onTap: () => _selectType(_MediaType.all)),
                const SizedBox(width: 8),
                _TypePill(label: 'GIF',   active: _mediaType == _MediaType.gif,
                    onTap: () => _selectType(_MediaType.gif)),
                const SizedBox(width: 8),
                _TypePill(label: 'Image', active: _mediaType == _MediaType.image,
                    onTap: () => _selectType(_MediaType.image)),
              ],
            ),
          ),
        ),

        // ── Niche chips — seulement quand "Tout" ─────────────────────
        if (_mediaType == _MediaType.all)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: mockNiches.length,
                itemBuilder: (ctx, i) {
                  final sel = i == _selNiche;
                  return GestureDetector(
                    onTap: () => _selectNiche(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: sel ? Colors.black87 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? Colors.black87 : Colors.grey.shade300),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        mockNiches[i].label,
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.black87,
                          fontSize: 13, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        else
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

        if (_init)
          const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_items.isEmpty)
          const SliverFillRemaining(
              child: Center(child: Text('Aucun contenu',
                  style: TextStyle(color: Colors.black45))))
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _GridColumn(items: left)),
                  const SizedBox(width: 2),
                  Expanded(child: _GridColumn(items: right)),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ],
    );
  }
}

class _GridColumn extends StatelessWidget {
  final List<ReelItem> items;
  const _GridColumn({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(children: items.map((r) => _ExplorerCard(item: r)).toList());
  }
}

// ── Type filter pill ──────────────────────────────────────────────────────────

class _TypePill extends StatelessWidget {
  final String       label;
  final bool         active;
  final VoidCallback onTap;
  const _TypePill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.black87 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? Colors.black87 : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.black54,
            fontSize: 13, fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Explorer card (miniature masonry) ─────────────────────────────────────────

class _ExplorerCard extends StatelessWidget {
  final ReelItem item;
  const _ExplorerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: ColoredBox(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: item.aspectRatio,
                child: item.posterUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const ColoredBox(color: Color(0xFFEEEEEE)),
                        errorWidget: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFFEEEEEE)),
                      )
                    : const ColoredBox(color: Color(0xFFEEEEEE)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.title.isNotEmpty)
                      Text(item.title,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: Colors.black87, height: 1.3),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade300),
                          child: const Icon(Icons.person,
                              size: 11, color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.creator.isNotEmpty
                                ? '@${item.creator}'
                                : 'Anonyme',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.likes > 0) ...[
                          const Icon(Icons.favorite_border_rounded,
                              size: 12, color: Colors.black38),
                          const SizedBox(width: 2),
                          Text(_fmtCount(item.likes),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black45)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUIVIS TAB — créateurs populaires (grille 2 cols)
// ══════════════════════════════════════════════════════════════════════════════

class _SuivisTab extends StatefulWidget {
  const _SuivisTab();
  @override
  State<_SuivisTab> createState() => _SuivisTabState();
}

class _SuivisTabState extends State<_SuivisTab>
    with AutomaticKeepAliveClientMixin {
  bool _init = true;
  final _scroll = ScrollController();

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) setState(() => _init = false);
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_init) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Text('Créateurs populaires',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.68,
            ),
            itemCount: mockCreators.length,
            itemBuilder: (ctx, i) => _CreatorCard(creator: mockCreators[i]),
          ),
        ),
      ],
    );
  }
}

class _CreatorCard extends StatelessWidget {
  final CreatorItem creator;
  const _CreatorCard({required this.creator});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // ── Bannière floutée ─────────────────────────────────────────
          SizedBox(
            height: 58,
            child: Stack(
              fit: StackFit.expand,
              children: [
                creator.bannerUrl.isNotEmpty
                    ? ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: CachedNetworkImage(
                          imageUrl: creator.bannerUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: const Color(0xFF1A1A2E)),
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A1A2E), Color(0xFF2C2C54)],
                          ),
                        ),
                      ),
                Container(color: Colors.black.withOpacity(0.20)),
              ],
            ),
          ),
          // ── Avatar (chevauche la bannière) ───────────────────────────
          Transform.translate(
            offset: const Offset(0, -28),
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: creator.avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: creator.avatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.person, size: 28, color: Colors.grey),
                    )
                  : const Icon(Icons.person, size: 28, color: Colors.grey),
            ),
          ),
          // ── Info (compensé par le translate) ────────────────────────
          Transform.translate(
            offset: const Offset(0, -20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text('@${creator.username}',
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700, color: Colors.black87),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center),
                      ),
                      if (creator.verified) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.verified_rounded,
                            size: 14, color: Color(0xFF1DA1F2)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                if (creator.followers > 0)
                  Text('${_fmtCount(creator.followers)} abonnés',
                      style: const TextStyle(fontSize: 11, color: Colors.black45)),
                if (creator.totalGifs > 0)
                  Text('${creator.totalGifs} GIFs',
                      style: const TextStyle(fontSize: 11, color: Colors.black38)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black87, width: 1.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Suivre',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w700, color: Colors.black87)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// POUR TOI TAB — player TikTok plein écran (vertical PageView)
// ══════════════════════════════════════════════════════════════════════════════

class _PourToiTab extends StatefulWidget {
  const _PourToiTab();
  @override
  State<_PourToiTab> createState() => _PourToiTabState();
}

class _PourToiTabState extends State<_PourToiTab>
    with AutomaticKeepAliveClientMixin {
  late final Player          _player;
  late final VideoController _videoCtrl;
  late final PageController  _pageCtrl;

  // ── SANDBOX: données mock (remplacer par getCustomListProvider dans Watchtower)
  final List<ReelItem> _items = List.from(mockReels);
  int  _curPage = 0;
  bool _paused  = false;

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _player    = Player();
    _videoCtrl = VideoController(_player);
    _pageCtrl  = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playItem(0);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _playItem(int idx) {
    if (idx >= _items.length) return;
    final item = _items[idx];
    final url  = item.hdUrl.isNotEmpty ? item.hdUrl : item.sdUrl;
    if (url.isEmpty) return;
    _player
      ..open(Media(url))
      ..setPlaylistMode(PlaylistMode.single)
      ..play();
    if (mounted) setState(() => _paused = false);
  }

  void _onPageChanged(int idx) {
    setState(() => _curPage = idx);
    _playItem(idx);
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    _paused ? _player.pause() : _player.play();
  }

  ReelItem? get _current =>
      _items.isNotEmpty && _curPage < _items.length ? _items[_curPage] : null;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_items.isEmpty) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: Text('Aucun contenu',
            style: TextStyle(color: Colors.white54, fontSize: 15))),
      );
    }

    final item   = _current;
    final likes  = item?.likes  ?? 0;
    final views  = item?.views  ?? 0;
    final creator = item?.creator ?? '';
    final title   = item?.title   ?? '';
    final hasAudio = item?.hasAudio ?? false;

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          // ── Feed vertical ────────────────────────────────────────────
          PageView.builder(
            controller: _pageCtrl,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            physics: const PageScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (ctx, i) => _ReelPage(
              item:            _items[i],
              videoController: _videoCtrl,
              isActive:        i == _curPage,
              paused:          _paused,
              onTap:           _togglePause,
            ),
          ),

          // ── Dégradé haut ────────────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: const Alignment(0, -0.4),
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Dégradé bas ─────────────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: const Alignment(0, 0.25),
                    colors: [
                      Colors.black.withOpacity(0.72),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55],
                  ),
                ),
              ),
            ),
          ),

          // ── Rail droite ──────────────────────────────────────────────
          Positioned(
            right: 10, bottom: 90,
            child: _TikTokRail(
              hasAudio: hasAudio,
              likes:    likes,
              views:    views,
            ),
          ),

          // ── Info bas ────────────────────────────────────────────────
          Positioned(
            left: 14, right: 90, bottom: 20,
            child: _BottomInfo(creator: creator, title: title),
          ),

          // ── Icône pause ─────────────────────────────────────────────
          if (_paused)
            const IgnorePointer(
              child: Center(
                child: Icon(Icons.play_arrow_rounded,
                    color: Colors.white54, size: 80),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Page reel (poster + vidéo) ────────────────────────────────────────────────

class _ReelPage extends StatelessWidget {
  final ReelItem        item;
  final VideoController videoController;
  final bool            isActive;
  final bool            paused;
  final VoidCallback    onTap;
  const _ReelPage({
    required this.item,
    required this.videoController,
    required this.isActive,
    required this.paused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.posterUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: item.posterUrl, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black),
            )
          else
            const ColoredBox(color: Colors.black),
          if (isActive)
            Video(
              controller: videoController,
              fit: BoxFit.contain,
              controls: NoVideoControls,
            ),
        ],
      ),
    );
  }
}

// ── Rail d'actions TikTok (droite) ────────────────────────────────────────────

class _TikTokRail extends StatelessWidget {
  final bool hasAudio;
  final int  likes;
  final int  views;
  const _TikTokRail({required this.hasAudio, required this.likes, required this.views});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _AvatarFollow(),
        const SizedBox(height: 20),
        _RailAction(icon: Icons.favorite_rounded,
            count: likes > 0 ? _fmtCount(likes) : null),
        const SizedBox(height: 16),
        _RailAction(icon: Icons.chat_bubble_rounded,
            count: views > 0 ? _fmtCount(views) : null),
        const SizedBox(height: 16),
        const _RailAction(icon: Icons.bookmark_rounded),
        const SizedBox(height: 16),
        const _RailAction(icon: Icons.reply_rounded, flip: true),
      ],
    );
  }
}

class _AvatarFollow extends StatelessWidget {
  const _AvatarFollow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44, height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade800,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFFFF3B5C),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailAction extends StatelessWidget {
  final IconData icon;
  final String?  count;
  final bool     flip;
  const _RailAction({required this.icon, this.count, this.flip = false});

  @override
  Widget build(BuildContext context) {
    final ico = Icon(icon, color: Colors.white, size: 30);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        flip
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                child: ico,
              )
            : ico,
        if (count != null) ...[
          const SizedBox(height: 3),
          Text(count!,
              style: const TextStyle(
                color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
              )),
        ],
      ],
    );
  }
}

// ── Info overlay bas (créateur + description) ──────────────────────────────────

class _BottomInfo extends StatefulWidget {
  final String creator;
  final String title;
  const _BottomInfo({required this.creator, required this.title});
  @override
  State<_BottomInfo> createState() => _BottomInfoState();
}

class _BottomInfoState extends State<_BottomInfo> {
  bool _expanded = false;

  @override
  void didUpdateWidget(_BottomInfo old) {
    super.didUpdateWidget(old);
    if (old.creator != widget.creator) setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(color: Colors.black54, blurRadius: 8)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.creator.isNotEmpty)
          Text('@${widget.creator}',
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700,
                fontSize: 15, shadows: shadow,
              )),
        if (widget.title.isNotEmpty) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                    color: Colors.white, fontSize: 13,
                    height: 1.35, shadows: shadow),
                children: [
                  TextSpan(text: widget.title),
                  if (!_expanded && widget.title.length > 55)
                    const TextSpan(
                      text: '...plus',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.white70),
                    ),
                ],
              ),
              maxLines: _expanded ? 6 : 2,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
