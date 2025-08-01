import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:wasteapptest/Presentasion_page/page/dashboard_section/dashboard.dart';
import 'package:wasteapptest/main.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  bool _isDetecting = false;
  bool _isTorchOn = false;
  late AnimationController _scanAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      // App is inactive
      _turnOffTorch();
    } else if (state == AppLifecycleState.resumed) {
      // App is resumed
      if (_isTorchOn) {
        _turnOnTorch();
      }
    } else if (state == AppLifecycleState.paused) {
      // App is in background
      _turnOffTorch();
    }
  }

  Future<void> _turnOffTorch() async {
    try {
      if (_isTorchOn) {
        await _controller?.setFlashMode(FlashMode.off);
        setState(() => _isTorchOn = false);
      }
    } catch (e) {
      print('Error turning off torch: $e');
    }
  }

  Future<void> _turnOnTorch() async {
    try {
      await _controller?.setFlashMode(FlashMode.torch);
      setState(() => _isTorchOn = true);
    } catch (e) {
      print('Error turning on torch: $e');
    }
  }

  Future<void> _toggleTorch() async {
    try {
      if (_isTorchOn) {
        await _turnOffTorch();
      } else {
        await _turnOnTorch();
      }
    } catch (e) {
      print('Error toggling torch: $e');
      _showErrorDialog(
        title: 'Torch Error',
        message:
            'Gagal mengubah mode lampu senter. Pastikan kamera berfungsi dengan baik.',
      );
    }
  }

  void _initializeAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pulseAnimationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _pulseAnimationController.forward();
        }
      });

    _pulseAnimationController.forward();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      _showErrorDialog(
        title: 'No Camera Found',
        message: 'Tidak ada kamera yang tersedia pada perangkat ini.',
      );
      return;
    }

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
      _showErrorDialog(
        title: 'Camera Error',
        message:
            'Gagal menginisialisasi kamera. Pastikan kamera berfungsi dengan baik.',
      );
      return;
    }
  }

  Future<void> _captureAndDetect() async {
  if (_controller == null ||
      !_controller!.value.isInitialized ||
      _isDetecting) {
    return;
  }

  setState(() {
    _isDetecting = true;
  });

  final startTime = DateTime.now();
  _scanAnimationController.repeat();

  try {
    final XFile imageFile = await _controller!.takePicture();
    final File file = File(imageFile.path);
    final result = await _sendImageForDetection(file, startTime);

    _scanAnimationController.stop();

    if (result != null) {
      // Calculate total processing time
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime).inMilliseconds;
      result['total_processing_time'] = processingTime;

      // Navigate to result screen regardless of detection results
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            imagePath: imageFile.path,
            detectionResult: result,
          ),
        ),
      );
    } else {
      _showErrorDialog(
        title: 'Detection Error',
        message: 'Gagal memproses deteksi. '
            'Pastikan koneksi internet stabil dan coba lagi.',
      );
    }
  } catch (e) {
    _scanAnimationController.stop();
    _showErrorDialog(
      title: 'Error',
      message: 'Gagal mengambil gambar atau mengirim untuk deteksi. '
          'Pastikan kamera berfungsi dengan baik dan koneksi internet stabil.',
    );
  } finally {
    setState(() {
      _isDetecting = false;
    });
  }
}

  Future<Map<String, dynamic>?> _sendImageForDetection(
      File imageFile, DateTime startTime) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final resized = img.copyResize(
        image,
        width: 640,
        height: (640 * image.height / image.width).round(),
      );

      final optimizedBytes = img.encodeJpg(resized, quality: 85);
      final base64Image = base64Encode(optimizedBytes);

      // Prepare request body with thresholds
      final requestBody = {
        'image_base64': base64Image,
        'confidence_threshold': 0.25,
        'unknown_threshold': 0.45,
      };

      final response = await http.post(
        Uri.parse('https://typicalsleepingboy.my.id/api/yolo/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Add scan start time for backward compatibility
        jsonResponse['scan_start_time'] = startTime.toIso8601String();
        if (jsonResponse['detections'] != null) {
          final detections = jsonResponse['detections'] as List;
          for (var detection in detections) {
            // Add percentage confidence for display
            if (detection['confidence'] != null) {
              detection['confidence_percentage'] =
                  (detection['confidence'] * 100).toStringAsFixed(1);
            }

            if (detection['class_name'] == 'unknown') {
              print('Unknown detection: ${detection['original_class_name']} '
                  '(${detection['confidence_percentage']}%) - ${detection['reason']}');
            }
          }
        }

        return jsonResponse;
      }

      return null;
    } catch (e) {
      print('Error sending image: $e');
      return null;
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  title.contains('Error')
                      ? Icons.error_outline
                      : Icons.info_outline,
                  size: 48,
                  color: title.contains('Error')
                      ? Colors.red
                      : const Color(0xFF2cac69),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: title.contains('Error')
                        ? Colors.red
                        : const Color(0xFF2cac69),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: title.contains('Error')
                        ? Colors.red
                        : const Color(0xFF2cac69),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child:
                      const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2cac69),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Camera Preview with rounded corners
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: AspectRatio(
                  aspectRatio: _controller?.value.aspectRatio ?? 1,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),

            // Modern Top Bar
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () async {
                        await _turnOffTorch();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardScreen(),
                          ),
                        );
                      },
                    ),
                    const Text(
                      'Scan Sampah',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                      onPressed: _toggleTorch,
                    ),
                  ],
                ),
              ),
            ),

            // Scanning Frame
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF2cac69),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2cac69).withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Instruction Text
            Positioned(
              bottom: 200,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isDetecting
                        ? 'Sedang mendeteksi...'
                        : 'Arahkan kamera ke sampah dan tekan tombol scan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Scan Button
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isDetecting ? null : _captureAndDetect,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isDetecting ? 70 : 80,
                    height: _isDetecting ? 70 : 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isDetecting
                          ? Colors.grey.withOpacity(0.5)
                          : const Color(0xFF2cac69),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2cac69).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: _isDetecting
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 32,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _turnOffTorch();
    _controller?.dispose();
    _scanAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }
}
