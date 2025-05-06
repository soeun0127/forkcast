import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

late List<CameraDescription> _cameras;

Future<void> initCameraModule() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 권한 요청
  await Permission.camera.request();

  // 카메라 초기화
  _cameras = await availableCameras();
}

class CameraApp extends StatefulWidget {
  const CameraApp({super.key});

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController _controller;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _controller = CameraController(_cameras[0], ResolutionPreset.high, enableAudio: false);

    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _isCameraReady = true);
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized) return;

    try {
      final XFile file = await _controller.takePicture();

      // 앱 전용 저장소 경로 가져오기
      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/my_images';  // 여기서 파일 경로 설정
      await Directory(path).create(recursive: true);  // 폴더 생성

      // 파일을 새 경로로 저장
      await File(file.path).copy('$path/${file.name}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to $path/${file.name}')),
      );
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: _takePicture,
                child: const Icon(Icons.camera_alt, size: 70, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
