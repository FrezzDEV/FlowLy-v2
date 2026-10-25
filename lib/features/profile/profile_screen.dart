import 'package:flutter/material.dart';

import '../../core/storage/image_store.dart';
import 'profile_controller.dart';

const Color _screenBackground = Color(0xFF08090B);
const Color _accent = Color(0xFFB6F36B);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.backButtonKey});

  final GlobalKey? backButtonKey;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _bannerContentHeight = 150;
  static const double _avatarRadius = 50;

  final ProfileController _profile = ProfileController.instance;

  void _openSettings() {
    // Отдельный непрозрачный маршрут с коротким затуханием: экран настроек
    // сразу закрывает профиль и не «просвечивает» сквозь него.
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (_, __, ___) => const SettingsScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final path = await pickImageWithFeedback(
      context,
      prefix: 'avatar',
      maxWidth: 800,
      maxHeight: 800,
    );
    if (path == null) return;
    if (!mounted) {
      await ImageStore.delete(path);
      return;
    }
    await _profile.setAvatar(path);
  }

  Future<void> _pickBanner() async {
    final path = await pickImageWithFeedback(
      context,
      prefix: 'banner',
      maxWidth: 1600,
      maxHeight: 900,
    );
    if (path == null) return;
    if (!mounted) {
      await ImageStore.delete(path);
      return;
    }
    await _profile.setBanner(path);
  }

  Future<void> _showImageActions({
    required String title,
    required bool hasImage,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Material(
        color: const Color(0xFF17181D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Выбрать из галереи'),
                  onTap: () => Navigator.of(sheetContext).pop('pick'),
                ),
                if (hasImage)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Удалить фото',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () => Navigator.of(sheetContext).pop('remove'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (action == 'pick') {
      onPick();
    } else if (action == 'remove') {
      onRemove();
    }
  }

  Future<void> _editIdentity() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditProfileSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final bannerHeight = safeTop + _bannerContentHeight;

    return AnimatedBuilder(
      animation: _profile,
      builder: (context, _) {
        final bannerPath = _profile.bannerPath;
        final avatarPath = _profile.avatarPath;

        final bannerFallback = DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF275F7D), Color(0xFF51416D)],
            ),
          ),
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(top: safeTop),
              child: Icon(
                Icons.landscape_rounded,
                size: 56,
                color: Colors.white.withValues(alpha: .22),
              ),
            ),
          ),
        );
        const avatarFallback = ColoredBox(
          color: Color(0xFF24272B),
          child: Center(child: Icon(Icons.person_rounded, size: 52)),
        );

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: bannerHeight + _avatarRadius,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Баннер на всю ширину, под статус-баром.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: bannerHeight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showImageActions(
                        title: 'Баннер профиля',
                        hasImage: bannerPath != null,
                        onPick: _pickBanner,
                        onRemove: () => _profile.setBanner(null),
                      ),
                      child: bannerPath == null
                          ? bannerFallback
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                FileImageBox(
                                  key: ValueKey(bannerPath),
                                  path: bannerPath,
                                  cacheWidth: 1200,
                                  fallback: bannerFallback,
                                ),
                                // Затемнение сверху, чтобы кнопки были видны.
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.center,
                                      colors: [
                                        Colors.black.withValues(alpha: .45),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  Positioned(
                    top: safeTop + 4,
                    left: 8,
                    child: widget.backButtonKey != null
                        ? _OverlayButton(
                            key: widget.backButtonKey,
                            tooltip: 'Назад',
                            icon: Icons.arrow_back_rounded,
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        : const SizedBox(width: 48, height: 48),
                  ),
                  Positioned(
                    top: safeTop + 4,
                    right: 8,
                    child: _OverlayButton(
                      tooltip: 'Настройки',
                      icon: Icons.settings_rounded,
                      onPressed: _openSettings,
                    ),
                  ),
                  Positioned(
                    top: bannerHeight - 46,
                    right: 12,
                    child: const IgnorePointer(
                      child: _CameraBadge(size: 32),
                    ),
                  ),
                  // Аватар по центру сверху, поверх нижнего края баннера.
                  Positioned(
                    top: bannerHeight - _avatarRadius,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _showImageActions(
                          title: 'Фото профиля',
                          hasImage: avatarPath != null,
                          onPick: _pickAvatar,
                          onRemove: () => _profile.setAvatar(null),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: _avatarRadius * 2 + 8,
                              height: _avatarRadius * 2 + 8,
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: _screenBackground,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: avatarPath == null
                                    ? avatarFallback
                                    : FileImageBox(
                                        key: ValueKey(avatarPath),
                                        path: avatarPath,
                                        cacheWidth: 400,
                                        fallback: avatarFallback,
                                      ),
                              ),
                            ),
                            const Positioned(
                              right: 2,
                              bottom: 2,
                              child: IgnorePointer(
                                child: _CameraBadge(size: 30),
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    _profile.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${_profile.username}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _editIdentity,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Редактировать профиль'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }
}

/// Круглая кнопка поверх баннера с полупрозрачной подложкой.
class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .35),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 24),
        ),
      );
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: _accent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.photo_camera_rounded,
          size: size * .55,
          color: const Color(0xFF11130D),
        ),
      );
}

/// Редактирование имени и @юзернейма.
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final ProfileController _profile = ProfileController.instance;
  late final TextEditingController _nameController =
      TextEditingController(text: _profile.name);
  late final TextEditingController _usernameController =
      TextEditingController(text: _profile.username);
  String? _nameError;
  String? _usernameError;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final usernameError =
        ProfileController.validateUsername(_usernameController.text);
    final nameError = name.isEmpty ? 'Введите имя' : null;
    if (nameError != null || usernameError != null) {
      setState(() {
        _nameError = nameError;
        _usernameError = usernameError;
      });
      return;
    }
    await _profile.updateIdentity(
      name: name,
      username: _usernameController.text,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Material(
          color: const Color(0xFF17181D),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Редактировать профиль',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: ProfileController.maxNameLength,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Имя',
                    counterText: '',
                    errorText: _nameError,
                  ),
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _usernameController,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: ProfileController.maxUsernameLength + 1,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: 'Юзернейм',
                    prefixText: '@',
                    counterText: '',
                    errorText: _usernameError,
                  ),
                  onChanged: (_) {
                    if (_usernameError != null) {
                      setState(() => _usernameError = null);
                    }
                  },
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: const Color(0xFF11130D),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ),
        ),
      );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        // Собственный непрозрачный фон: без него страница настроек рисуется
        // поверх профиля и тот просвечивает, пока идёт переход маршрута.
        backgroundColor: _screenBackground,
        body: SafeArea(
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
              const _SettingRow(
                Icons.palette_outlined,
                'Внешний вид',
                'Тёмная тема',
              ),
              const _SettingRow(
                Icons.notifications_none_rounded,
                'Уведомления',
                'Настройка уведомлений',
              ),
              const _SettingRow(
                Icons.high_quality_rounded,
                'Качество звука',
                'Будет доступно после интеграции',
              ),
              const _SettingRow(
                Icons.language_rounded,
                'Язык',
                'Русский',
              ),
              const _SettingRow(
                Icons.info_outline_rounded,
                'О приложении',
                'FlowLy · 0.1.0',
              ),
            ],
          ),
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
