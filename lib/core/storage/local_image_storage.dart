import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Picks a photo from the device and copies it into durable app-owned storage.
class LocalImageStorage {
  LocalImageStorage._();

  static Future<String?> pickAndPersistImage({
    required String folder,
  }) async {
    final selected = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (selected == null) return null;

    final appDirectory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory('${appDirectory.path}/$folder');
    await imageDirectory.create(recursive: true);

    final sourceName = selected.name;
    final sourceExtension = sourceName.contains('.')
        ? '.${sourceName.split('.').last.toLowerCase()}'
        : '.jpg';
    const allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.heic'};
    final extension = allowedExtensions.contains(sourceExtension)
        ? sourceExtension
        : '.jpg';
    final target = File(
      '${imageDirectory.path}/${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    await selected.saveTo(target.path);
    return target.path;
  }
}
