import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Выбор фото из галереи и сохранение копии во внутреннее хранилище
/// приложения, чтобы картинка не пропала вместе с кэшем галереи/пикера.
class ImageStore {
  const ImageStore._();

  /// Открывает галерею и возвращает путь к сохранённой копии.
  /// null — пользователь ничего не выбрал. Ошибки пробрасываются выше.
  static Future<String?> pickAndStore({
    required String prefix,
    double maxWidth = 1600,
    double maxHeight = 1600,
  }) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: 88,
    );
    if (picked == null) return null;

    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/images');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final dot = picked.path.lastIndexOf('.');
    final rawExtension = dot < 0 ? '' : picked.path.substring(dot + 1);
    final extension = RegExp(r'^[A-Za-z0-9]{2,5}$').hasMatch(rawExtension)
        ? rawExtension.toLowerCase()
        : 'jpg';
    final target = File(
      '${directory.path}/$prefix-${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await File(picked.path).copy(target.path);
    return target.path;
  }

  /// Удаляет сохранённую картинку; отсутствие файла не считается ошибкой.
  static Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Остатки файла безвредны, поэтому тихо игнорируем.
    }
  }
}

/// Выбор фото с показом понятного сообщения при ошибке.
/// Возвращает путь к сохранённой копии или null.
Future<String?> pickImageWithFeedback(
  BuildContext context, {
  required String prefix,
  double maxWidth = 1600,
  double maxHeight = 1600,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    return await ImageStore.pickAndStore(
      prefix: prefix,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  } catch (_) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Не удалось выбрать фото')),
      );
    return null;
  }
}

/// Картинка из локального файла с безопасным запасным виджетом.
class FileImageBox extends StatelessWidget {
  const FileImageBox({
    super.key,
    required this.path,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final String path;
  final Widget fallback;
  final BoxFit fit;

  /// Ширина декодирования в пикселях: уменьшает расход памяти на превью.
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) => Image.file(
        File(path),
        fit: fit,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
      );
}
