import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

import '../utils/dbg.dart';

class QrResult {
  final String text;
  final double detectionMs;

  const QrResult({required this.text, required this.detectionMs});
}

class QrDetector {
  final _reader = QRCodeReader();

  /// Returns null if no QR code was found or an error occurred.
  QrResult? detect(img.Image frame) {
    final t0 = DateTime.now().millisecondsSinceEpoch;

    try {
      final pixels = Int32List(frame.width * frame.height);
      for (int i = 0; i < pixels.length; i++) {
        final pixel = frame.getPixel(i % frame.width, i ~/ frame.width);
        pixels[i] = 0xFF000000 |
            (pixel.r.toInt() << 16) |
            (pixel.g.toInt() << 8) |
            pixel.b.toInt();
      }

      final source = RGBLuminanceSource(frame.width, frame.height, pixels);
      final bitmap = BinaryBitmap(HybridBinarizer(source));
      final result = _reader.decode(bitmap);
      final ms = (DateTime.now().millisecondsSinceEpoch - t0).toDouble();
      dbg('[QR] found: "${result.text}"  ms=${ms.toStringAsFixed(0)}');
      return QrResult(text: result.text, detectionMs: ms);
    } catch (_) {
      // NotFoundException is thrown when no QR code is found — that's normal.
      return null;
    }
  }
}
