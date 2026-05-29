import 'package:flutter/foundation.dart' hide debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../services/camera_service.dart';
import '../services/qr_detector.dart';
import '../utils/dbg.dart';
import '../widgets/init_progress_overlay.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> with WidgetsBindingObserver {
  final _camera = CameraService();
  final _detector = QrDetector();

  late final List<InitStep> _steps = [
    InitStep('Camera permission'),
    InitStep('Start camera'),
  ];

  QrResult? _lastResult;
  bool _initDone = false;
  bool _useFrontCamera = false;
  bool _detecting = false;
  double _lastDetectionMs = 0;

  void _begin(int i) => setState(() => _steps[i].state = InitStepState.running);
  void _finish(int i, int ms) => setState(() {
        _steps[i].state = InitStepState.done;
        _steps[i].elapsedMs = ms;
      });
  void _fail(int i, String msg) => setState(() {
        _steps[i].state = InitStepState.error;
        _steps[i].errorMsg = msg;
      });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) WakelockPlus.enable();
    });
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      WakelockPlus.disable();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _camera.stop();
    super.dispose();
  }

  Future<void> _init() async {
    await _stepPermissions();
    await _stepStartCamera();
    if (_camera.isRunning) {
      setState(() => _initDone = true);
    }
  }

  Future<void> _stepPermissions() async {
    dbg('[INIT] → permissions');
    _begin(0);
    final sw = Stopwatch()..start();
    if (!kIsWeb) await [Permission.camera].request();
    _finish(0, sw.elapsedMilliseconds);
  }

  Future<void> _stepStartCamera() async {
    dbg('[INIT] → camera');
    _begin(1);
    final sw = Stopwatch()..start();
    try {
      await _camera.start(
        useFrontCamera: _useFrontCamera,
        onFrame: _onFrame,
      );
      _finish(1, sw.elapsedMilliseconds);
    } on CameraInUseException catch (e) {
      dbg('[INIT] ✗ camera busy: $e');
      _fail(1, 'Camera busy — close other apps using the camera');
      _showRetrySnackbar();
    } catch (e) {
      dbg('[INIT] ✗ camera: $e');
      _fail(1, e.toString().split('\n').first);
    }
  }

  void _showRetrySnackbar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Camera is busy. Close other apps and tap Retry.'),
          duration: const Duration(seconds: 15),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () async {
              await _camera.stop();
              await _stepStartCamera();
              if (_camera.isRunning) setState(() => _initDone = true);
            },
          ),
        ),
      );
    });
  }

  void _onFrame(frame) {
    if (_detecting) return;
    _detecting = true;
    Future(() => _detector.detect(frame)).then((result) {
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _lastResult = result;
          _lastDetectionMs = result.detectionMs;
        });
      }
    }).catchError((e) {
      dbg('[QR] error: $e');
    }).whenComplete(() {
      _detecting = false;
    });
  }

  Future<void> _toggleCamera() async {
    _useFrontCamera = !_useFrontCamera;
    await _camera.stop();
    await _stepStartCamera();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_initDone) return InitProgressOverlay(steps: _steps);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_camera.renderer != null)
            RTCVideoView(
              _camera.renderer!,
              mirror: _useFrontCamera,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          _buildHud(),
          if (_lastResult != null) _buildResultBanner(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'switch_cam',
        onPressed: _toggleCamera,
        child: const Icon(Icons.flip_camera_ios),
      ),
    );
  }

  Widget _buildHud() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _chip('Scanning'),
          if (_lastDetectionMs > 0)
            _chip('${_lastDetectionMs.toStringAsFixed(0)} ms'),
        ],
      ),
    );
  }

  Widget _buildResultBanner() {
    return Positioned(
      bottom: 32,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => setState(() => _lastResult = null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QR detected',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _lastResult!.text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap to dismiss',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
