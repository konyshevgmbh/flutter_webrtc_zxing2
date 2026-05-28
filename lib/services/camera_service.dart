import 'dart:async';

import '../utils/dbg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:image/image.dart' as img;

typedef FrameCallback = void Function(img.Image frame);

class CameraInUseException implements Exception {
  final String message;
  CameraInUseException(this.message);
  @override
  String toString() => message;
}

class CameraService {
  MediaStream? _localStream;
  RTCVideoRenderer? _renderer;
  Timer? _frameTimer;
  FrameCallback? _onFrame;
  bool _isRunning = false;
  bool _capturing = false;

  bool get isRunning => _isRunning;
  RTCVideoRenderer? get renderer => _renderer;

  Future<void> start({
    required FrameCallback onFrame,
    bool useFrontCamera = true,
    int targetFps = 15,
  }) async {
    _onFrame = onFrame;
    _renderer = RTCVideoRenderer();
    await _renderer!.initialize();

    final constraints = <String, dynamic>{
      'audio': false,
      'video': {
        'facingMode': useFrontCamera ? 'user' : 'environment',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
        'frameRate': {'ideal': 30},
      },
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    } on PlatformException catch (e) {
      await _renderer!.dispose();
      _renderer = null;
      if (_isCameraInUseError(e)) {
        throw CameraInUseException(
          'Camera is busy. Close other apps using the camera.\n(${e.message})',
        );
      }
      rethrow;
    } catch (e) {
      await _renderer!.dispose();
      _renderer = null;
      rethrow;
    }

    _renderer!.srcObject = _localStream;
    _isRunning = true;
    dbg('[CAM] started  tracks=${_localStream!.getVideoTracks().length}');

    final interval = Duration(milliseconds: (1000 / targetFps).round());
    _frameTimer = Timer.periodic(interval, (_) => _captureFrame());
  }

  void _captureFrame() {
    if (!_isRunning || _capturing || _onFrame == null) return;
    final tracks = _localStream?.getVideoTracks();
    if (tracks == null || tracks.isEmpty) return;

    _capturing = true;
    dbg('[CAM] captureFrame → calling...');

    Future.any([
      tracks.first.captureFrame(),
      Future.delayed(const Duration(seconds: 2)).then(
        (_) => throw TimeoutException('captureFrame timed out'),
      ),
    ]).then((byteBuffer) {
      if (!_isRunning || _onFrame == null) return;
      final bytes = Uint8List.view(byteBuffer);
      dbg('[CAM] captureFrame ← ${bytes.length} bytes  first4=${bytes.take(4).toList()}');
      final frame = img.decodeImage(bytes);
      dbg('[CAM] decodeImage → ${frame == null ? "null" : "${frame.width}x${frame.height} fmt=${frame.format}"}');
      if (frame != null) _onFrame!(frame);
    }).catchError((e) {
      dbg('[CAM] captureFrame error: $e');
    }).whenComplete(() {
      _capturing = false;
    });
  }

  static bool _isCameraInUseError(PlatformException e) {
    final msg = '${e.code} ${e.message}'.toLowerCase();
    return msg.contains('in use') ||
        msg.contains('notreadable') ||
        msg.contains('could not start') ||
        msg.contains('device busy') ||
        msg.contains('failed to open');
  }

  Future<void> switchCamera() async {
    if (_localStream == null) return;
    final tracks = _localStream!.getVideoTracks();
    if (tracks.isEmpty) return;
    await Helper.switchCamera(tracks.first);
  }

  Future<void> stop() async {
    _isRunning = false;
    _frameTimer?.cancel();
    _frameTimer = null;
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }
    await _renderer?.dispose();
    _renderer = null;
  }
}
