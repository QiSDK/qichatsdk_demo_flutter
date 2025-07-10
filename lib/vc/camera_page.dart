import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qichatsdk_demo_flutter/vc/preview_page.dart';
import 'dart:io';
import 'dart:async';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  double _currentZoomLevel = 1.0;
  FlashMode _currentFlashMode = FlashMode.off;
  Timer? _timer;
  int _secondsRecorded = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleFlashMode() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    FlashMode newMode;
    switch (_currentFlashMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
    }
    await _controller!.setFlashMode(newMode);
    setState(() {
      _currentFlashMode = newMode;
    });
  }

  Future<void> _setZoomLevel(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    final double minZoom = await _controller!.getMinZoomLevel();
    final double maxZoom = await _controller!.getMaxZoomLevel();
    double newZoom = zoom.clamp(minZoom, maxZoom);
    await _controller!.setZoomLevel(newZoom);
    setState(() {
      _currentZoomLevel = newZoom;
    });
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isRecording){
      _stopVideoRecording();
      return;
    }
    try {
      final XFile file = await _controller!.takePicture();
      final bool? confirmed = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PreviewPage(filePath: file.path, isVideo: false),
        ),
      );
      if (confirmed == true) {
        Navigator.pop(context, file);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    try {
      await _controller!.startVideoRecording();
      _startTimer();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      return;
    }
    try {
      final XFile file = await _controller!.stopVideoRecording();
      _stopTimer();
      setState(() {
        _isRecording = false;
      });
        Navigator.pop(context, file);
    } catch (e) {
      print(e);
    }
  }

  String _getFlashModeIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return 'Flash Off';
      case FlashMode.auto:
        return 'Flash Auto';
      case FlashMode.always:
        return 'Flash On';
      case FlashMode.torch:
        return 'Torch';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: _toggleFlashMode,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getFlashModeIcon(),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          if (_isRecording)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDuration(_secondsRecorded),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildZoomButton(0.5),
                _buildZoomButton(1.0),
                _buildZoomButton(2.0),
                _buildZoomButton(3.0),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onLongPressStart: (_) => _startVideoRecording(),
                  onLongPressEnd: (_) => _stopVideoRecording(),
                  onTap: _takePicture,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Center(
                      child: _isRecording
                          ? const Icon(Icons.stop, color: Colors.red, size: 40)
                          : const Icon(Icons.camera,
                              color: Colors.black, size: 40),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(double zoomLevel) {
    return GestureDetector(
      onTap: () => _setZoomLevel(zoomLevel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _currentZoomLevel == zoomLevel
              ? Colors.blue.withOpacity(0.7)
              : Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${zoomLevel}x',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  void _startTimer() {
    _secondsRecorded = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRecorded++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _secondsRecorded = 0;
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }
}
