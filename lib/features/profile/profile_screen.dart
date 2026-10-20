import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Профиль', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
      const SizedBox(height: 24),
      const Center(child: CircleAvatar(radius: 42, backgroundColor: Color(0xFF24272B), child: Icon(Icons.person_rounded, size: 44))),
      const SizedBox(height: 12),
      const Center(child: Text('Слушатель FlowLy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
      const Center(child: Text('Демо-профиль', style: TextStyle(color: Colors.white60))),
      const SizedBox(height: 32),
      const Text('Настройки', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      _SettingRow(Icons.palette_outlined, 'Внешний вид', 'Тёмная тема'),
      _SettingRow(Icons.notifications_none_rounded, 'Уведомления', 'Настройка уведомлений'),
      _SettingRow(Icons.high_quality_rounded, 'Качество звука', 'Будет доступно после интеграции'),
      _SettingRow(Icons.language_rounded, 'Язык', 'Русский'),
      _SettingRow(Icons.info_outline_rounded, 'О приложении', 'FlowLy · 0.1.0'),
    ]),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(this.icon, this.title, this.subtitle);
  final IconData icon; final String title; final String subtitle;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF1C1E22), borderRadius: BorderRadius.circular(12)), child: Icon(icon)),
    title: Text(title), subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60)),
    trailing: const Icon(Icons.chevron_right_rounded), onTap: () {},
  );
}
