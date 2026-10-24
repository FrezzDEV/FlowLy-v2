import 'package:flutter/material.dart';

import '../../navigation/reveal_stagger.dart';
import '../player/draggable_player.dart';
import '../player/player_controller.dart';

class CatalogCollectionScreen extends StatelessWidget {
  const CatalogCollectionScreen({
    super.key,
    required this.title,
    required this.tracks,
    this.backButtonKey,
  });

  final String title;
  final List<PlayerTrack> tracks;
  final GlobalKey? backButtonKey;

  @override
  Widget build(BuildContext context) {
    final controller = PlayerController.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFF08090B),
        appBar: AppBar(
          automaticallyImplyLeading: backButtonKey == null,
          leading: backButtonKey == null
              ? null
              : RevealHeader(
                  child: IconButton(
                    key: backButtonKey,
                    tooltip: 'Назад',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
          title: RevealHeader(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          backgroundColor: const Color(0xFF08090B),
          surfaceTintColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
          children: [
            RevealHeader(
              child: Container(
                height: 180,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tracks.isEmpty
                          ? const Color(0xFF272933)
                          : tracks.first.color,
                      const Color(0xFF101116),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    tracks.isNotEmpty && tracks.first.artist == title
                        ? Icons.person_rounded
                        : Icons.album_rounded,
                    size: 72,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            RevealHeader(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  '${tracks.length} треков',
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
            ),
            ...List<Widget>.generate(tracks.length, (index) {
              final track = tracks[index];
              final isCurrent =
                  controller.currentTrack.title == track.title &&
                  controller.currentTrack.artist == track.artist;

              return RevealStagger(
                index: index,
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: track.color,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(track.icon),
                  ),
                  title: Text(track.title),
                  subtitle: Text(track.artist),
                  trailing: IconButton(
                    tooltip: isCurrent && controller.isPlaying
                        ? 'Пауза'
                        : 'Воспроизвести',
                    icon: Icon(
                      isCurrent && controller.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    onPressed: () {
                      if (isCurrent) {
                        controller.togglePlay();
                      } else {
                        controller.playTrack(track);
                      }
                    },
                  ),
                  onTap: () {
                    controller.playTrack(track);
                    draggablePlayerKey.currentState?.open();
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
