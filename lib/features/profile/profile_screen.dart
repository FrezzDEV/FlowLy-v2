import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/local_image_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.backButtonKey});

  final GlobalKey? backButtonKey;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _nameKey = 'flowly.profile.name';
  static const _usernameKey = 'flowly.profile.username';
  static const _avatarKey = 'flowly.profile.avatar';
  static const _bannerKey = 'flowly.profile.banner';

  String _name = 'Слушатель FlowLy';
  String _username = 'flowly_listener';
  String? _avatarPath;
  String? _bannerPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _name = preferences.getString(_nameKey) ?? _name;
        _username = preferences.getString(_usernameKey) ?? _username;
        _avatarPath = preferences.getString(_avatarKey);
        _bannerPath = preferences.getString(_bannerKey);
      });
    } catch (_) {
      // Keep the editable demo profile usable when local storage is unavailable.
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final path = await LocalImageStorage.pickAndPersistImage(folder: 'profile');
      if (path == null || !mounted) return;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_avatarKey, path);
      if (!mounted) return;
      setState(() => _avatarPath = path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть галерею.')),
      );
    }
  }

  Future<void> _pickBanner() async {
    try {
      final path = await LocalImageStorage.pickAndPersistImage(folder: 'profile');
      if (path == null || !mounted) return;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_bannerKey, path);
      if (!mounted) return;
      setState(() => _bannerPath = path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть галерею.')),
      );
    }
  }

  Future<void> _editIdentity() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _EditProfileDialog(
        initialName: _name,
        initialUsername: _username,
      ),
    );
    if (result == null || !mounted) return;

    final name = (result['name'] ?? '').trim();
    final username = (result['username'] ?? '')
        .trim()
        .replaceFirst(RegExp(r'^@+'), '');
    if (name.isEmpty || username.isEmpty) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_nameKey, name);
      await preferences.setString(_usernameKey, username);
    } catch (_) {
      // The changes remain visible for this session if storage is unavailable.
    }
    if (!mounted) return;
    setState(() {
      _name = name;
      _username = username;
    });
  }

  Widget _image(String? path, {BoxFit fit = BoxFit.cover}) {
    if (path == null) {
      return const ColoredBox(
        color: Color(0xFF24272B),
        child: Center(child: Icon(Icons.person_rounded, size: 44)),
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFF24272B),
        child: Center(child: Icon(Icons.person_rounded, size: 44)),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const SettingsScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    SizedBox(
                      height: 206,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 158,
                            child: GestureDetector(
                              onTap: _pickBanner,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    const DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF345B56),
                                            Color(0xFF263047),
                                            Color(0xFF15171E),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_bannerPath != null)
                                      Positioned.fill(
                                        child: Image.file(
                                          File(_bannerPath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                      ),
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withValues(alpha: .08),
                                              Colors.black.withValues(alpha: .42),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: .38),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.photo_camera_outlined, size: 15),
                                            SizedBox(width: 5),
                                            Text(
                                              'Изменить баннер',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: _pickAvatar,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 108,
                                      height: 108,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF08090B),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFB6F36B),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(child: _image(_avatarPath)),
                                    ),
                                    Positioned(
                                      right: 2,
                                      bottom: 2,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFB6F36B),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF08090B),
                                            width: 3,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          color: Color(0xFF11130D),
                                          size: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '@$_username',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _editIdentity,
                        icon: const Icon(Icons.edit_rounded, size: 17),
                        label: const Text('Редактировать профиль'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB6F36B),
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.initialName,
    required this.initialUsername,
  });

  final String initialName;
  final String initialUsername;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName);
  late final TextEditingController _usernameController =
      TextEditingController(text: widget.initialUsername);

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().replaceFirst(
          RegExp(r'^@+'),
          '',
        );
    if (name.isEmpty || username.isEmpty) return;
    Navigator.of(context).pop({'name': name, 'username': username});
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF191A20),
        title: const Text('Редактировать профиль'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                maxLength: 30,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: '@Юзернейм',
                  prefixText: '@',
                  counterText: '',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: _submit,
            child: const Text('Сохранить'),
          ),
        ],
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
