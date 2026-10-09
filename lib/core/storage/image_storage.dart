import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorage {
  ImageStorage._();

  static Future<String> copyToAppStorage(
    String sourcePath, {
    required String subfolder,
  }) async {
    final supportDir = await getApplicationSupportDirectory();
    final targetDir = Directory(p.join(supportDir.path, subfolder));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final extension = p.extension(sourcePath);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final destPath = p.join(targetDir.path, fileName);

    await File(sourcePath).copy(destPath);
    return destPath;
  }
}
