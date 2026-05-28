# flutter_webrtc_zxing2

Real-time QR code scanner built with Flutter, using **flutter_webrtc** for camera capture and **zxing2** for decoding.

## How it works

1. `CameraService` opens a WebRTC media stream via `getUserMedia` and polls frames at 15 fps using `VideoTrack.captureFrame()`.
2. Each raw frame is decoded to an `img.Image` and passed to `QrDetector`.
3. `QrDetector` converts the image to an ARGB pixel array, feeds it to `zxing2`'s `QRCodeReader`, and returns the decoded text plus the latency in milliseconds.
4. The result is shown in a bottom banner; the HUD displays live detection latency.

## Features

- Front / back camera toggle
- Wakelock — screen stays on while scanning
- Step-by-step init overlay with per-step timing
- Graceful handling of "camera in use" errors with a Retry snackbar
- Runs on Android, iOS, Web, Windows, macOS, Linux

## Tuning resolution

Camera constraints are set in [camera_service.dart](lib/services/camera_service.dart):

```dart
'width':  {'ideal': 640},
'height': {'ideal': 480},
```

640×480 is intentionally kept low — smaller frames mean faster per-frame QR decoding. For better detection of small or distant QR codes, raise the values (e.g. `1280` × `720` or `1920` × `1080`). Keep in mind that higher resolution increases CPU usage and detection latency proportionally.

## Getting started

```bash
flutter pub get
flutter run
```

Camera permission is requested automatically on first launch (Android/iOS). On the web no permission prompt is required by the browser beforehand.

## Platform notes

| Platform | Notes |
|----------|-------|
| Android  | Requires `CAMERA` permission in `AndroidManifest.xml` (already declared via `permission_handler`) |
| iOS      | `NSCameraUsageDescription` must be set in `Info.plist` |
| Web      | Uses browser `getUserMedia` — works in Chrome/Edge/Firefox over HTTPS or `localhost` |
| Windows / macOS / Linux | Desktop WebRTC via `flutter_webrtc`; camera must not be claimed by another app |

## Dependencies

| Package | Purpose |
|---------|---------|
| [flutter_webrtc](https://pub.dev/packages/flutter_webrtc) `1.4.1` | Camera stream and frame capture |
| [zxing2](https://pub.dev/packages/zxing2) `^0.2.4` | QR code decoding (ZXing port) |
| [image](https://pub.dev/packages/image) `^4.3.0` | Frame decoding / pixel access |
| [permission_handler](https://pub.dev/packages/permission_handler) `^11.3.1` | Runtime camera permission |
| [wakelock_plus](https://pub.dev/packages/wakelock_plus) `^1.2.10` | Prevent screen sleep |

## Project structure

```
lib/
  main.dart                   — app entry point, WebRTC init
  screens/
    qr_screen.dart            — main screen, camera + detection loop
  services/
    camera_service.dart       — WebRTC camera wrapper, frame polling
    qr_detector.dart          — zxing2 QR decoder
  widgets/
    init_progress_overlay.dart — step-by-step startup UI
  utils/
    dbg.dart                  — debug logging helper
```
