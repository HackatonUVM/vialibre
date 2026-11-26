import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SanitizedImage {
  const SanitizedImage({
    required this.filePath,
    required this.bytes,
    required this.base64Data,
  });

  final String filePath;
  final Uint8List bytes;
  final String base64Data;
}

/// Elimina metadatos EXIF (`keepExif: false`) y comprime a < 1.5 MB para Vercel.
class ImageSanitizer {
  ImageSanitizer._();

  static const int maxBytes = 1450 * 1024;

  static Future<SanitizedImage> sanitizeForUpload(File sourceFile) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      'vialibre_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    int quality = 82;
    Uint8List? compressed = await FlutterImageCompress.compressWithFile(
      sourceFile.absolute.path,
      minWidth: 1600,
      minHeight: 1600,
      quality: quality,
      keepExif: false,
      format: CompressFormat.jpeg,
    );

    while (compressed != null && compressed.length > maxBytes && quality > 35) {
      quality -= 15;
      compressed = await FlutterImageCompress.compressWithFile(
        sourceFile.absolute.path,
        minWidth: 1280,
        minHeight: 1280,
        quality: quality,
        keepExif: false,
        format: CompressFormat.jpeg,
      );
    }

    final finalBytes = compressed ?? await sourceFile.readAsBytes();
    final outFile = File(targetPath);
    await outFile.writeAsBytes(finalBytes, flush: true);

    return SanitizedImage(
      filePath: outFile.path,
      bytes: finalBytes,
      base64Data: base64Encode(finalBytes),
    );
  }
}
