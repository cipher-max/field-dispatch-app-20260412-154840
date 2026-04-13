import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/models/job.dart';

class ProofExportService {
  Future<List<String>> buildExportBundle(Job job) async {
    final temp = await getTemporaryDirectory();
    final folderName =
        'proof_export_${job.id}_${DateTime.now().millisecondsSinceEpoch}';
    final bundleDir = Directory(p.join(temp.path, folderName));
    await bundleDir.create(recursive: true);

    final copiedPhotoPaths = <String>[];
    for (final source in [...?job.proofPhotoUrls]) {
      final file = File(source);
      if (!await file.exists()) continue;
      final target = p.join(bundleDir.path, p.basename(source));
      final copied = await file.copy(target);
      copiedPhotoPaths.add(copied.path);
    }

    final manifest = {
      'jobId': job.id,
      'customerName': job.customerName,
      'address': job.address,
      'jobType': job.jobType,
      'status': job.status,
      'completionNotes': job.completionNotes,
      'customerSignatureName': job.customerSignatureName,
      'proofPhotoCount': job.proofPhotoCount ?? copiedPhotoPaths.length,
      'exportedAt': DateTime.now().toIso8601String(),
      'files': copiedPhotoPaths.map((e) => p.basename(e)).toList(),
    };

    final manifestPath = p.join(bundleDir.path, 'proof_manifest.json');
    await File(
      manifestPath,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));

    return [manifestPath, ...copiedPhotoPaths];
  }
}
