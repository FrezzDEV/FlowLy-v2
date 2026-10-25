import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/image_store.dart';

/// Данные профиля пользователя: имя, @юзернейм, аватар и баннер.
class ProfileController extends ChangeNotifier {
  ProfileController._();

  static final ProfileController instance = ProfileController._();

  static const String _storageKey = 'flowly.profile.v1';
  static const String defaultName = 'Слушатель FlowLy';
  static const String defaultUsername = 'flowly_user';
  static const int maxNameLength = 30;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 24;

  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9_.]+$');

  String _name = defaultName;
  String _username = defaultUsername;
  String? _avatarPath;
  String? _bannerPath;
  bool _initialized = false;

  String get name => _name;

  /// Юзернейм без символа «@».
  String get username => _username;
  String? get avatarPath => _avatarPath;
  String? get bannerPath => _bannerPath;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_storageKey);
      if (encoded == null) return;
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return;
      final name = decoded['name'];
      final username = decoded['username'];
      if (name is String && name.trim().isNotEmpty) _name = name.trim();
      if (username is String && validateUsername(username) == null) {
        _username = normalizeUsername(username);
      }
      final avatar = decoded['avatarPath'];
      final banner = decoded['bannerPath'];
      _avatarPath = avatar is String ? avatar : null;
      _bannerPath = banner is String ? banner : null;
    } catch (_) {
      // Приложение работает и без платформенного хранилища.
    }
    notifyListeners();
  }

  /// Приводит ввод к виду «без @, строчные буквы».
  static String normalizeUsername(String value) {
    final trimmed = value.trim();
    final withoutAt = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
    return withoutAt.toLowerCase();
  }

  /// Возвращает текст ошибки или null, если юзернейм допустим.
  static String? validateUsername(String value) {
    final username = normalizeUsername(value);
    if (username.length < minUsernameLength) {
      return 'Минимум $minUsernameLength символа';
    }
    if (username.length > maxUsernameLength) {
      return 'Максимум $maxUsernameLength символа';
    }
    if (!_usernamePattern.hasMatch(username)) {
      return 'Только латиница, цифры, _ и .';
    }
    return null;
  }

  Future<void> _persist() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _storageKey,
        jsonEncode(<String, Object>{
          'name': _name,
          'username': _username,
          if (_avatarPath != null) 'avatarPath': _avatarPath!,
          if (_bannerPath != null) 'bannerPath': _bannerPath!,
        }),
      );
    } catch (_) {
      // Изменения остаются в памяти, если хранилище недоступно.
    }
  }

  /// Сохраняет имя и юзернейм. Возвращает false при некорректных данных.
  Future<bool> updateIdentity({
    required String name,
    required String username,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName.length > maxNameLength) return false;
    if (validateUsername(username) != null) return false;
    _name = cleanName;
    _username = normalizeUsername(username);
    notifyListeners();
    await _persist();
    return true;
  }

  Future<void> setAvatar(String? path) async {
    if (path == _avatarPath) return;
    final previous = _avatarPath;
    _avatarPath = path;
    notifyListeners();
    await _persist();
    await ImageStore.delete(previous);
  }

  Future<void> setBanner(String? path) async {
    if (path == _bannerPath) return;
    final previous = _bannerPath;
    _bannerPath = path;
    notifyListeners();
    await _persist();
    await ImageStore.delete(previous);
  }
}
