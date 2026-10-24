import 'package:flutter/material.dart';

import '../../navigation/circle_reveal_route.dart';
import '../player/player_controller.dart';
import '../library/playlist_detail_screen.dart';
import '../library/playlist_sheets.dart';
import '../player/draggable_player.dart';
import '../profile/profile_screen.dart';

const _muted = Color(0xFFA5A6AC);
const _lime = Color(0xFFB6F36B);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            sliver: SliverToBoxAdapter(child: _header(context)),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(child: _sectionTitle('Недавние')),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            sliver: SliverToBoxAdapter(child: _quickGrid()),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 28),
            sliver: SliverToBoxAdapter(child: _popularSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 28),
            sliver: SliverToBoxAdapter(child: _mixSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverToBoxAdapter(child: _recentSection(context)),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    Offset? profileTapPosition;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _lime,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Color(0xFF11130D),
            size: 25,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Flow',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
        const Text(
          'Ly',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: _lime,
            letterSpacing: -.8,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTapDown: (details) =>
              profileTapPosition = details.globalPosition,
          child: IconButton(
            tooltip: 'Профиль',
            onPressed: () {
              final origin = profileTapPosition ??
                  Offset(
                    MediaQuery.sizeOf(context).width - 32,
                    MediaQuery.paddingOf(context).top + 32,
                  );
              final backButtonKey = GlobalKey();
              context.pushCircleReveal(
                page: ProfileScreen(backButtonKey: backButtonKey),
                tapPosition: origin,
                backButtonKey: backButtonKey,
                backgroundColor: const Color(0xFF08090B),
              );
            },
            icon: const CircleAvatar(
              radius: 19,
              backgroundColor: Color(0xFF24262B),
              child: Icon(Icons.person_outline, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, {String? action, VoidCallback? onAction}) => Row(
    children: [
      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -.4)),
      const Spacer(),
      if (action != null) TextButton(onPressed: onAction, child: Text(action, style: const TextStyle(color: _muted, fontSize: 14))),
    ],
  );

  Widget _quickGrid() {
    final items = [
      ('Избранное', Icons.favorite_rounded, const Color(0xFF6D4B9D)),
      ('Скачанные', Icons.download_rounded, const Color(0xFF32664E)),
      ('Afterlife', Icons.waves_rounded, const Color(0xFF24617B)),
      ('Chill mix', Icons.bolt_rounded, const Color(0xFF713B36)),
      ('Night Drive', Icons.directions_car_rounded, const Color(0xFF173C65)),
      ('Мой микс 01', Icons.graphic_eq_rounded, const Color(0xFF7B3B75)),
      ('Любимые', Icons.favorite_border_rounded, const Color(0xFF6A4A34)),
      ('As It Was', Icons.album_rounded, const Color(0xFF485C76)),
      ('В дорогу', Icons.headphones_rounded, const Color(0xFF2D6554)),
    ];
    final playTracks = [
      PlayerController.catalog[4],
      PlayerController.catalog[4],
      PlayerController.catalog[1],
      PlayerController.catalog[5],
      PlayerController.catalog[3],
      PlayerController.catalog[0],
      PlayerController.catalog[4],
      PlayerController.catalog[6],
      PlayerController.catalog[7],
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final spacing = 10.0;
      final tile = (constraints.maxWidth - spacing * 2) / 3;
      Offset? tapPosition;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (var i = 0; i < items.length; i++)
            SizedBox(
              width: tile,
              child: AspectRatio(
                aspectRatio: 1.06,
                child: Material(
                  color: const Color(0xFF17191D),
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTapDown: (details) =>
                        tapPosition = details.globalPosition,
                    onTap: () {
                      if (i == 0 || i == 1) {
                        final playlistId = i == 0
                            ? PlayerController.favoritesPlaylistId
                            : PlayerController.downloadsPlaylistId;
                        // Сохраняем постоянный shell и сворачиваем большой плеер.
                        draggablePlayerKey.currentState?.close();
                        final backButtonKey = GlobalKey();
                        context.pushCircleReveal(
                          page: PlaylistDetailScreen(
                            playlistId: playlistId,
                            backButtonKey: backButtonKey,
                          ),
                          tapPosition: tapPosition ??
                              Offset(
                                constraints.maxWidth / 2,
                                MediaQuery.sizeOf(context).height / 2,
                              ),
                          backButtonKey: backButtonKey,
                          backgroundColor: const Color(0xFF08090B),
                        );
                      } else {
                        PlayerController.instance.playTrack(playTracks[i]);
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [items[i].$3, const Color(0xFF111216)]))),
                        Positioned(right: -13, top: -14, child: Icon(items[i].$2, size: 86, color: Colors.white.withValues(alpha: .10))),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                            Icon(items[i].$2, color: i == 0 ? Colors.pink[100] : Colors.white.withValues(alpha: .9), size: 21),
                            const SizedBox(height: 7),
                            Text(items[i].$1, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.15)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _popularSection() {
    final tracks = [
      PlayerController.catalog[1],
      PlayerController.catalog[2],
      PlayerController.catalog[3],
      PlayerController.catalog[4],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('Популярное', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 172,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: tracks.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final track = tracks[index];
            return GestureDetector(
              onTap: () => PlayerController.instance.playTrack(track),
              child: SizedBox(
                width: 172,
                height: 172,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: .10)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [track.color, const Color(0xFF151619)],
                      ),
                    ),
                    child: Stack(children: [
                      Positioned(
                        right: -18,
                        top: 10,
                        child: Icon(track.icon, size: 130, color: Colors.white.withValues(alpha: .12)),
                      ),
                      Positioned(
                        left: 14,
                        right: 12,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _mixSection() {
    final mixes = [
      ('01', const Color(0xFF9C337F), const Color(0xFF3C184B)),
      ('02', const Color(0xFF287AC3), const Color(0xFF10223F)),
      ('03', const Color(0xFF2B8A68), const Color(0xFF102D25)),
      ('04', const Color(0xFF8045C5), const Color(0xFF24123D)),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Для тебя', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
      const SizedBox(height: 14),
      SizedBox(height: 172, child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: mixes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => Container(
          width: 172,
          height: 172,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .10)),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [mixes[i].$2, mixes[i].$3]),
          ),
          child: Stack(children: [
            Positioned(right: -28, top: -30, child: Icon(Icons.waves_rounded, size: 112, color: Colors.white.withValues(alpha: .12))),
            Align(alignment: Alignment.bottomLeft, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Мой микс\n${mixes[i].$1}', style: const TextStyle(fontSize: 16, height: 1.25, fontWeight: FontWeight.w700)),
            ])),
          ]),
        ),
      )),
    ]);
  }

  Widget _recentSection(BuildContext context) {
    final songs = [
      PlayerController.catalog[4],
      PlayerController.catalog[5],
      PlayerController.catalog[6],
      PlayerController.catalog[7],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Недавно прослушано'),
      const SizedBox(height: 8),
      for (final song in songs)
        ListTile(
          onTap: () => PlayerController.instance.playTrack(song),
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(colors: [song.color, const Color(0xFF17181B)]),
            ),
            child: Icon(song.icon, color: Colors.white70, size: 28),
          ),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          subtitle: Text(song.artist, style: const TextStyle(color: _muted, fontSize: 13)),
          trailing: PopupMenuButton<String>(
            tooltip: 'Действия с треком',
            icon: const Icon(Icons.more_vert_rounded, color: _muted),
            onSelected: (value) async {
              final player = PlayerController.instance;
              if (value == 'favorite') {
                final favorites = player.playlistById(
                  PlayerController.favoritesPlaylistId,
                );
                final exists = favorites?.tracks.any(
                  (track) =>
                      track.title == song.title && track.artist == song.artist,
                ) ?? false;
                if (exists) {
                  await player.removeTrackFromPlaylist(
                    PlayerController.favoritesPlaylistId,
                    song,
                  );
                } else {
                  await player.addTrackToPlaylist(
                    PlayerController.favoritesPlaylistId,
                    song,
                  );
                }
              } else if (value == 'playlist') {
                await showSaveTrackToPlaylistSheet(context, song);
              } else if (value == 'play') {
                player.playTrack(song);
                draggablePlayerKey.currentState?.open();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'favorite', child: Text('Добавить / убрать из избранного')),
              PopupMenuItem(value: 'playlist', child: Text('Добавить / убрать в плейлисте')),
              PopupMenuItem(value: 'play', child: Text('Открыть плеер')),
            ],
          ),
        ),
    ]);
  }
}
