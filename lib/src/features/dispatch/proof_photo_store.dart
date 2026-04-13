import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ProofPhotoStore {
  Future<String> savePhoto({
    required String sourcePath,
    required String customerName,
    required String jobId,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final customerDirName = _slug(customerName);
    final targetDir = Directory(
      p.join(root.path, 'proof_photos', customerDirName, jobId),
    );
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final extension = p.extension(sourcePath).toLowerCase().isEmpty
        ? '.jpg'
        : p.extension(sourcePath).toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetPath = p.join(targetDir.path, fileName);

    final copied = await File(sourcePath).copy(targetPath);
    return copied.path;
  }

  String _slug(String input) {
    final normalized = input.trim().toLowerCase();
    final cleaned = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return cleaned
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
