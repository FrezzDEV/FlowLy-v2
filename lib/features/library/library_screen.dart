import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Библиотека', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
      const SizedBox(height: 22),
      const Wrap(spacing: 8, children: [
        _FilterChip(label: 'Плейлисты', selected: true),
        _FilterChip(label: 'Исполнители'),
        _FilterChip(label: 'Альбомы'),
      ]),
      const SizedBox(height: 22),
      _LibraryRow(Icons.favorite_rounded, const Color(0xFF7D376F), 'Избранное', 'Плейлист · 24 трека'),
      _LibraryRow(Icons.queue_music_rounded, const Color(0xFF275F7D), 'Мои плейлисты', 'Ваши коллекции'),
      _LibraryRow(Icons.download_rounded, const Color(0xFF32664E), 'Загрузки', 'Офлайн-контент появится позже'),
      _LibraryRow(Icons.history_rounded, const Color(0xFF674B31), 'История прослушивания', 'Недавно воспроизведённое'),
    ]),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label),
    backgroundColor: selected ? const Color(0xFFB6F36B).withValues(alpha: .18) : const Color(0xFF1A1C20),
    side: BorderSide(color: selected ? const Color(0xFFB6F36B) : Colors.white12),
  );
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow(this.icon, this.color, this.title, this.subtitle);
  final IconData icon; final Color color; final String title; final String subtitle;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 7),
    leading: Container(width: 54, height: 54, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Icon(icon)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60)),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () {},
  );
}
