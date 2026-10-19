import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStore {
  ImageStore({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<Directory> _imageDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'diary_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<String>> pickImages({int limit = 9}) async {
    final files = await _picker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (files.isEmpty) return const [];
    final dir = await _imageDir();
    final saved = <String>[];
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < files.length && saved.length < limit; i++) {
      final file = files[i];
      final ext = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path).toLowerCase();
      final target = p.join(dir.path, 'diary_${stamp}_$i$ext');
      try {
        await File(file.path).copy(target);
        saved.add(target);
      } catch (_) {
        // Skip files that cannot be copied (e.g. permission revoked mid-flow).
      }
    }
    return saved;
  }

  Future<void> deleteFiles(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best effort — an orphan image is harmless.
      }
    }
  }

  /// Copies the bundled demo photographs into the diary image directory.
  /// Only used by demo builds (--dart-define=DEMO_MODE=true).
  Future<List<String>> copyDemoImages() async {
    const assets = ['assets/demo/demo_dusk.jpg', 'assets/demo/demo_sea.jpg'];
    final dir = await _imageDir();
    final result = <String>[];
    for (var i = 0; i < assets.length; i++) {
      try {
        final data = await rootBundle.load(assets[i]);
        final file = File(p.join(dir.path, 'demo_$i.jpg'));
        await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
        result.add(file.path);
      } catch (_) {
        // Demo images are decorative; the app works without them.
      }
    }
    return result;
  }
}
