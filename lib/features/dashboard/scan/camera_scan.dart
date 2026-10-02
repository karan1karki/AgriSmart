import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    // Select the rear camera (usually index 0)
    final firstCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Plant Leaf")),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller!);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller!.takePicture();
            // This is where you will send the image path to your CNN model
            if (mounted) Navigator.pop(context, image.path);
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}