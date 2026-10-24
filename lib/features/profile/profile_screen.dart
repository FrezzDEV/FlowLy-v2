import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.backButtonKey});

  final GlobalKey? backButtonKey;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _openSettings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  if (widget.backButtonKey != null)
                    IconButton(
                      key: widget.backButtonKey,
                      tooltip: 'Назад',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: 48, height: 48),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Настройки',
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_rounded, size: 26),
                  ),
                ],
              ),
              const Spacer(),
              const CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFF24272B),
                child: Icon(Icons.person_rounded, size: 44),
              ),
              const SizedBox(height: 12),
              const Text(
                'Слушатель FlowLy',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Демо-профиль',
                style: TextStyle(color: Colors.white60),
              ),
              const Spacer(),
            ],
          ),
        ),
      );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Назад',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Настройки',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingRow(
              Icons.palette_outlined,
              'Внешний вид',
              'Тёмная тема',
            ),
            _SettingRow(
              Icons.notifications_none_rounded,
              'Уведомления',
              'Настройка уведомлений',
            ),
            _SettingRow(
              Icons.high_quality_rounded,
              'Качество звука',
              'Будет доступно после интеграции',
            ),
            _SettingRow(
              Icons.language_rounded,
              'Язык',
              'Русский',
            ),
            _SettingRow(
              Icons.info_outline_rounded,
              'О приложении',
              'FlowLy · 0.1.0',
            ),
          ],
        ),
      );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1E22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white60),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      );
}
