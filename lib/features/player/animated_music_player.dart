
import 'package:flutter/material.dart';

import 'player_controller.dart';

class AlbumCover extends StatelessWidget {
  const AlbumCover({super.key, required this.track, required this.size});

  final PlayerTrack track;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.08),
          gradient: LinearGradient(
            colors: [track.color, const Color(0xFF24243A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -size * 0.09,
              top: -size * 0.10,
              child: Icon(
                track.icon,
                size: size * 0.65,
                color: Colors.white.withValues(alpha: .12),
              ),
            ),
            Icon(track.icon, color: Colors.white, size: size * .42),
          ],
        ),
      );
}
