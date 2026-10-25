import 'dart:io';

import 'package:flutter/material.dart';

import '../player/player_controller.dart';

const _plaqueColor = Color(0xB3000000);
const _mutedText = Color(0xFFB8BAC0);
const _sectionGap = 24.0;
const _edgePadding = 20.0;

/// Artwork kinds drawn with gradients and icons; the prototype ships no images.
enum ProfileArt {
  heart,
  topTracks,
  redSitting,
  divide,
  outrun,
  note,
  blackWhite,
}

ProfileArt profileArtForTrack(PlayerTrack track) {
  final key = '${track.title}|${track.album}'.toLowerCase();
  if (key.contains('midnight flow')) return ProfileArt.redSitting;
  if (key.contains('afterlife')) return ProfileArt.divide;
  if (key.contains('divinely')) return ProfileArt.redSitting;
  if (key.contains('outrun')) return ProfileArt.outrun;
  return ProfileArt.note;
}

PlayerTrack _trackByArtist(String artist) {
  final catalog = PlayerController.catalog;
  return catalog.firstWhere(
    (track) => track.artist == artist,
    orElse: () => catalog.first,
  );
}

class ProfileSectionHeader extends StatelessWidget {
  const ProfileSectionHeader({
    super.key,
    required this.title,
    required this.onEdit,
  });

  final String title;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(_edgePadding, 0, _edgePadding, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.3,
                ),
              ),
            ),
            Material(
              color: const Color(0xFF1D1F27),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    'Редактировать',
                    style: TextStyle(fontSize: 14, color: Color(0xFFE6E7EB)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class ProfileSectionBlock extends StatelessWidget {
  const ProfileSectionBlock({
    super.key,
    required this.title,
    required this.onEdit,
    required this.child,
    this.emptyText,
  });

  final String title;
  final VoidCallback onEdit;
  final Widget? child;
  final String? emptyText;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: _sectionGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileSectionHeader(title: title, onEdit: onEdit),
            if (child != null)
              child!
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _edgePadding),
                child: Text(
                  emptyText ?? '',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Избранное
// ---------------------------------------------------------------------------

class ProfileFeaturedCardData {
  const ProfileFeaturedCardData({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.art,
    this.secondArt,
    this.vinyl = true,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;
  final ProfileArt art;
  final ProfileArt? secondArt;
  final bool vinyl;
  final bool selected;
  final VoidCallback? onTap;

  static const defaults = <ProfileFeaturedCardData>[
    ProfileFeaturedCardData(
      title: 'Любимые треки',
      subtitle: 'Unknown Artist',
      colors: [Color(0xFF7A5CFF), Color(0xFFFF6FA8)],
      art: ProfileArt.heart,
      vinyl: false,
      selected: true,
    ),
    ProfileFeaturedCardData(
      title: 'Топ треков',
      subtitle: 'Ed Sheeran',
      colors: [Color(0xFF2F6FDB), Color(0xFF3CC4B6)],
      art: ProfileArt.topTracks,
    ),
    ProfileFeaturedCardData(
      title: 'Плейлисты',
      subtitle: 'Lewis Capaldi',
      colors: [Color(0xFFFF8A3C), Color(0xFFF2C94C)],
      art: ProfileArt.redSitting,
    ),
    ProfileFeaturedCardData(
      title: 'Альбомы',
      subtitle: 'Kavinsky',
      colors: [Color(0xFF4AA3DF), Color(0xFF6CCBEA)],
      art: ProfileArt.redSitting,
      secondArt: ProfileArt.divide,
      selected: true,
    ),
    ProfileFeaturedCardData(
      title: 'Divinely Uninspired',
      subtitle: 'Lewis Capaldi',
      colors: [Color(0xFF1B1B1D), Color(0xFF4A4A4F)],
      art: ProfileArt.blackWhite,
    ),
  ];
}

class ProfileFeaturedCarousel extends StatelessWidget {
  const ProfileFeaturedCarousel({super.key, required this.cards});

  final List<ProfileFeaturedCardData> cards;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: _edgePadding),
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, index) => _FeaturedCard(data: cards[index]),
        ),
      );
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.data});

  final ProfileFeaturedCardData data;

  @override
  Widget build(BuildContext context) {
    const width = 110.0;
    const height = 140.0;
    const coverSize = 62.0;

    Widget content;
    if (data.art == ProfileArt.heart) {
      content = const Align(
        alignment: Alignment(0, -.45),
        child: Icon(Icons.favorite_rounded, size: 58, color: Color(0xFFFFE3F1)),
      );
    } else if (data.secondArt != null) {
      content = Stack(
        children: [
          Positioned(
            left: 10,
            top: 16,
            child: ProfileCoverArt(art: data.art, size: 44),
          ),
          if (data.vinyl)
            const Positioned(left: 62, top: 22, child: ProfileVinyl(size: 44)),
          Positioned(
            left: 36,
            top: 16,
            child: ProfileCoverArt(art: data.secondArt!, size: 44),
          ),
        ],
      );
    } else {
      content = Stack(
        children: [
          if (data.vinyl)
            const Positioned(left: 44, top: 18, child: ProfileVinyl(size: coverSize)),
          Positioned(
            left: 10,
            top: 14,
            child: ProfileCoverArt(art: data.art, size: coverSize),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: data.colors,
          ),
          border: Border.all(
            color: data.selected
                ? Colors.white.withValues(alpha: .55)
                : Colors.white.withValues(alpha: .08),
            width: data.selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: content),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: _plaqueColor,
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _mutedText, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Плейлисты
// ---------------------------------------------------------------------------

enum ProfilePlaylistArt { mixCircles, sunset, collageNeon, collageDark }

class ProfilePlaylistCardData {
  const ProfilePlaylistCardData({
    required this.title,
    required this.subtitle,
    this.art = ProfilePlaylistArt.collageDark,
    this.coverPath,
    this.color,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final ProfilePlaylistArt art;
  final String? coverPath;
  final Color? color;
  final VoidCallback? onTap;

  static const defaults = <ProfilePlaylistCardData>[
    ProfilePlaylistCardData(
      title: 'Мой Микс',
      subtitle: '27 подписчиков',
      art: ProfilePlaylistArt.mixCircles,
    ),
    ProfilePlaylistCardData(
      title: 'Вечерний Вайб',
      subtitle: '71 подписчик',
      art: ProfilePlaylistArt.sunset,
    ),
    ProfilePlaylistCardData(
      title: 'Мой Микс 2',
      subtitle: '23 подписчика',
      art: ProfilePlaylistArt.collageNeon,
    ),
    ProfilePlaylistCardData(
      title: 'Ночной драйв',
      subtitle: '72 подписчика',
      art: ProfilePlaylistArt.collageDark,
    ),
  ];
}

class ProfilePlaylistRow extends StatelessWidget {
  const ProfilePlaylistRow({super.key, required this.cards});

  final List<ProfilePlaylistCardData> cards;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: _edgePadding),
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, index) => _PlaylistCard(data: cards[index]),
        ),
      );
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.data});

  final ProfilePlaylistCardData data;

  @override
  Widget build(BuildContext context) {
    Widget art;
    if (data.coverPath != null) {
      art = Image.file(
        File(data.coverPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _PlaylistFallback(color: data.color),
      );
    } else if (data.color != null) {
      art = _PlaylistFallback(color: data.color);
    } else {
      art = _PlaylistArtwork(kind: data.art);
    }

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: 120,
        height: 150,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: art),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: _plaqueColor,
                padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistFallback extends StatelessWidget {
  const _PlaylistFallback({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? const Color(0xFF275F7D);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, .6)!],
        ),
      ),
      child: const Align(
        alignment: Alignment(0, -.35),
        child: Icon(Icons.queue_music_rounded, size: 44, color: Colors.white70),
      ),
    );
  }
}

class _PlaylistArtwork extends StatelessWidget {
  const _PlaylistArtwork({required this.kind});

  final ProfilePlaylistArt kind;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case ProfilePlaylistArt.mixCircles:
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB042E8), Color(0xFF3C6DF0), Color(0xFF2FA4E8)],
            ),
          ),
          child: Align(
            alignment: const Alignment(0, -.4),
            child: _ConcentricCircles(size: 84),
          ),
        );
      case ProfilePlaylistArt.sunset:
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE0589A), Color(0xFF7A3AA8), Color(0xFF2A1745)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: 12,
                top: 22,
                child: Icon(Icons.accessibility_new_rounded,
                    size: 64, color: Color(0xFF1B0F2E)),
              ),
              for (final dot in const [
                Offset(14, 78),
                Offset(30, 66),
                Offset(48, 82),
                Offset(22, 52),
              ])
                Positioned(
                  left: dot.dx,
                  top: dot.dy,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFC27A).withValues(alpha: .75),
                    ),
                  ),
                ),
            ],
          ),
        );
      case ProfilePlaylistArt.collageNeon:
        return const _Collage(colors: [
          [Color(0xFFFF4FA3), Color(0xFF3B2DB5)],
          [Color(0xFF1B3BA8), Color(0xFF0B1030)],
          [Color(0xFFE0409A), Color(0xFF6A3CD6)],
          [Color(0xFF3D6BFF), Color(0xFF8A5A2B)],
        ]);
      case ProfilePlaylistArt.collageDark:
        return const _Collage(colors: [
          [Color(0xFF8C8F94), Color(0xFF5C5F66)],
          [Color(0xFFB9BBC0), Color(0xFF3A3C41)],
          [Color(0xFF2A2B30), Color(0xFF15161A)],
          [Color(0xFF6B5B45), Color(0xFF2B2A28)],
        ]);
    }
  }
}

class _Collage extends StatelessWidget {
  const _Collage({required this.colors});

  final List<List<Color>> colors;

  Widget _tile(List<Color> pair) => Expanded(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: pair,
            ),
          ),
          child: const SizedBox.expand(),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: Row(children: [_tile(colors[0]), _tile(colors[1])]),
          ),
          Expanded(
            child: Row(children: [_tile(colors[2]), _tile(colors[3])]),
          ),
        ],
      );
}

class _ConcentricCircles extends StatelessWidget {
  const _ConcentricCircles({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final entry in const [
              [1.0, Color(0xFFFF5FA8), Color(0xFF7A3CF0)],
              [.74, Color(0xFF4F7BFF), Color(0xFFB04CF0)],
              [.5, Color(0xFFB04CF0), Color(0xFFFF8AC0)],
            ])
              Container(
                width: size * (entry[0] as double),
                height: size * (entry[0] as double),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [entry[1] as Color, entry[2] as Color],
                  ),
                ),
              ),
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Треки
// ---------------------------------------------------------------------------

class ProfileTrackList extends StatelessWidget {
  const ProfileTrackList({
    super.key,
    required this.tracks,
    required this.onPlay,
  });

  final List<PlayerTrack> tracks;
  final ValueChanged<PlayerTrack> onPlay;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final track in tracks)
            InkWell(
              onTap: () => onPlay(track),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _edgePadding,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    ProfileCoverArt(
                      art: profileArtForTrack(track),
                      size: 50,
                      radius: 12,
                      fallbackColor: track.color,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: _mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Альбомы
// ---------------------------------------------------------------------------

class ProfileAlbumData {
  const ProfileAlbumData({
    required this.title,
    required this.caption,
    required this.art,
    required this.artist,
    this.vinylCenter = const Color(0xFFC62828),
  });

  final String title;
  final String caption;
  final ProfileArt art;
  final String artist;
  final Color vinylCenter;

  static const defaults = <ProfileAlbumData>[
    ProfileAlbumData(
      title: 'Midnight Flow',
      caption: '2023',
      art: ProfileArt.note,
      artist: 'Unknown Artist',
    ),
    ProfileAlbumData(
      title: 'Afterlife',
      caption: '2022',
      art: ProfileArt.divide,
      artist: 'Ed Sheeran',
      vinylCenter: Color(0xFF3E9ED6),
    ),
    ProfileAlbumData(
      title: 'Divinely Uninspired to a Hellish Extent',
      caption: '2019',
      art: ProfileArt.redSitting,
      artist: 'Lewis Capaldi',
    ),
    ProfileAlbumData(
      title: 'OutRun',
      caption: 'Kavinsky',
      art: ProfileArt.outrun,
      artist: 'Kavinsky',
      vinylCenter: Color(0xFFE0409A),
    ),
  ];
}

class ProfileAlbumRow extends StatelessWidget {
  const ProfileAlbumRow({
    super.key,
    required this.albums,
    required this.onPlay,
  });

  final List<ProfileAlbumData> albums;
  final ValueChanged<PlayerTrack> onPlay;

  @override
  Widget build(BuildContext context) {
    const size = 95.0;
    return SizedBox(
      height: size + 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _edgePadding),
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final album = albums[index];
          return GestureDetector(
            onTap: () => onPlay(_trackByArtist(album.artist)),
            child: SizedBox(
              width: size * 1.45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: size,
                    child: Stack(
                      children: [
                        Positioned(
                          left: size * .45,
                          top: 0,
                          child: ProfileVinyl(
                            size: size,
                            centerColor: album.vinylCenter,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: ProfileCoverArt(
                            art: album.art,
                            size: size,
                            radius: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    album.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: _mutedText),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Авторы
// ---------------------------------------------------------------------------

class ProfileArtistData {
  const ProfileArtistData(this.name, this.color, {this.grayscale = false});

  final String name;
  final Color color;
  final bool grayscale;

  static const defaults = <ProfileArtistData>[
    ProfileArtistData('Ed Sheeran', Color(0xFFB0643C)),
    ProfileArtistData('Lewis Capaldi', Color(0xFF9E2A1C)),
    ProfileArtistData('Kavinsky', Color(0xFF2C3E63)),
    ProfileArtistData('Lord Huron', Color(0xFF6B6A4C)),
    ProfileArtistData('Rob Stone', Color(0xFF3A404C)),
    ProfileArtistData('Harry Styles', Color(0xFF7A7A7A), grayscale: true),
  ];
}

class ProfileArtistRow extends StatelessWidget {
  const ProfileArtistRow({
    super.key,
    required this.artists,
    required this.onPlay,
  });

  final List<ProfileArtistData> artists;
  final ValueChanged<PlayerTrack> onPlay;

  static String _initials(String name) => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    const avatar = 70.0;
    return SizedBox(
      height: avatar + 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _edgePadding),
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) {
          final artist = artists[index];
          final base = artist.color;
          return GestureDetector(
            onTap: () => onPlay(_trackByArtist(artist.name)),
            child: SizedBox(
              width: 92,
              child: Column(
                children: [
                  SizedBox(
                    width: avatar + 6,
                    height: avatar + 6,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: avatar + 6,
                          height: avatar + 6,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF3B6FD0),
                              width: 2.5,
                            ),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  base,
                                  Color.lerp(base, Colors.black, .65)!,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _initials(artist.name),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: artist.grayscale
                                      ? Colors.white70
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF3B8EF0),
                              border: Border.all(
                                color: const Color(0xFF08090B),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Общие элементы обложек
// ---------------------------------------------------------------------------

class ProfileCoverArt extends StatelessWidget {
  const ProfileCoverArt({
    super.key,
    required this.art,
    required this.size,
    this.radius = 6,
    this.fallbackColor,
  });

  final ProfileArt art;
  final double size;
  final double radius;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: _body(),
        ),
      );

  Widget _gradient(List<Color> colors, Widget? child) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: child == null ? null : Center(child: child),
      );

  Widget _body() {
    switch (art) {
      case ProfileArt.heart:
        return _gradient(
          const [Color(0xFF7A5CFF), Color(0xFFFF6FA8)],
          Icon(Icons.favorite_rounded, size: size * .6, color: Colors.white),
        );
      case ProfileArt.topTracks:
        return _gradient(
          const [Color(0xFF6A2FD6), Color(0xFFE0529A)],
          Padding(
            padding: EdgeInsets.all(size * .08),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Топ треков\nи альбомы',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * .15,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ),
        );
      case ProfileArt.redSitting:
        return _gradient(
          const [Color(0xFFE0391F), Color(0xFF4A0C0A)],
          Icon(Icons.self_improvement_rounded,
              size: size * .62, color: const Color(0xFFFFB199)),
        );
      case ProfileArt.divide:
        final dot = size * .17;
        return ColoredBox(
          color: const Color(0xFF45B3E7),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: dot,
                  height: dot,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0D0D0F),
                  ),
                ),
                SizedBox(height: size * .06),
                Container(
                  width: size * .62,
                  height: size * .1,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D0F),
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
                SizedBox(height: size * .06),
                Container(
                  width: dot,
                  height: dot,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0D0D0F),
                  ),
                ),
              ],
            ),
          ),
        );
      case ProfileArt.outrun:
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B1030), Color(0xFF2A1058)],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: size * .16,
                child: Container(
                  width: size * .5,
                  height: size * .5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFF4FA3), Color(0xFF3DB8FF)],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: size * .08,
                child: Icon(
                  Icons.directions_car_filled_rounded,
                  size: size * .34,
                  color: const Color(0xFF0A0A12),
                ),
              ),
            ],
          ),
        );
      case ProfileArt.note:
        return _gradient(
          const [Color(0xFF3A3358), Color(0xFF1C1A30)],
          Icon(Icons.music_note_rounded, size: size * .5, color: Colors.white),
        );
      case ProfileArt.blackWhite:
        return _gradient(
          const [Color(0xFFE4E4E6), Color(0xFF3A3A3F)],
          Icon(Icons.self_improvement_rounded,
              size: size * .62, color: const Color(0xFF161618)),
        );
    }
  }
}

class ProfileVinyl extends StatelessWidget {
  const ProfileVinyl({
    super.key,
    required this.size,
    this.centerColor = const Color(0xFF8E8E93),
  });

  final double size;
  final Color centerColor;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _VinylPainter(centerColor)),
      );
}

class _VinylPainter extends CustomPainter {
  const _VinylPainter(this.center);

  final Color center;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0B0B0D));
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .07);
    for (final factor in const [.9, .78, .66, .54]) {
      canvas.drawCircle(c, r * factor, ring);
    }
    canvas.drawCircle(c, r * .28, Paint()..color = center);
    canvas.drawCircle(c, r * .05, Paint()..color = const Color(0xFF0B0B0D));
  }

  @override
  bool shouldRepaint(_VinylPainter oldDelegate) =>
      oldDelegate.center != center;
}
