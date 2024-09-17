// ignore_for_file: unnecessary_null_comparison, non_constant_identifier_names, prefer_typing_uninitialized_variables, depend_on_referenced_packages, use_build_context_synchronously, unused_local_variable

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// ignore: camel_case_types
class food_recognizer {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final DateTime timestamp;

  food_recognizer({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.timestamp,
  });
}

class YoloVideo extends StatefulWidget {
  final FlutterVision vision;
  const YoloVideo({super.key, required this.vision});

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  late CameraController controller;
  List<Map<String, dynamic>> yoloResults = [];
  List<List<dynamic>> detectionRows = [];
  bool isLoaded = false;
  bool isDetecting = false;
  XFile? videoFile;
  late Directory appDirectory;
  late String videoDirectoryPath;
  String? photoDirectoryPath;
  File? image;
  bool isRecordingVideo = false;

  late CameraDescription _camera;

  List<food_recognizer> detectedfood_recognizers = [];
  int food_recognizerCounter = 0;
  List<double> detectionCounts = [];
  Timer? timer;
  int secondsPassed = 0;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        detectionCounts.add(yoloResults.length.toDouble());
        secondsPassed++;
      });
    });
    init();
    // _detectMarkers();
  }

  Future<void> init() async {
    try {
      await _requestPermissions();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No cameras available");
      }
      _camera = cameras.first;
      controller = CameraController(_camera, ResolutionPreset.ultraHigh);
      await controller.initialize();

      bool gpuCompatible = await isGpuCompatible();
      if (gpuCompatible) {
        await loadYoloModel();
      } else {
        await loadYoloModelCpuFallback();
      }

      isLoaded = true;

      setState(() {
        isLoaded = true;
      });
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.accessMediaLocation,
      Permission.appTrackingTransparency,
      Permission.location,
      Permission.locationAlways,
      Permission.systemAlertWindow,
    ].request();
  }

  void _startListeningToLocation() {}

  @override
  void dispose() {
    controller.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: CupertinoActivityIndicator(
            radius: 20,
          ),
        ),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
        ...displayBoxesAroundRecognizedObjects(size, context),
        Positioned(
          bottom: 15,
          right: 40,
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                color: const Color.fromARGB(255, 255, 102, 0),
                icon: isDetecting ? Icons.stop : Icons.play_arrow,
                iconColor: isDetecting ? Colors.red : Colors.white,
                onPressed: isDetecting ? stopDetection : startDetection,
              ),
              const SizedBox(width: 30),
              _buildControlButton(
                color: const Color.fromRGBO(18, 119, 214, 1),
                icon: Icons.camera_alt,
                onPressed: takePhoto,
              ),
              const SizedBox(width: 30),
              _buildControlButton(
                color: const Color.fromARGB(255, 0, 150, 0),
                icon: isRecordingVideo ? Icons.videocam_off : Icons.videocam,
                iconColor: isRecordingVideo ? Colors.red : Colors.white,
                onPressed:
                    isRecordingVideo ? stopVideoRecording : startVideoRecording,
              ),
              const SizedBox(width: 30),
            ],
          ),
        ),
        Positioned(
          bottom: 70,
          child: Container(
            height: 140,
            width: MediaQuery.of(context).size.width,
            child: LineChart(
              LineChartData(
                lineTouchData: const LineTouchData(),
                rangeAnnotations: const RangeAnnotations(),
                backgroundColor: const Color.fromARGB(255, 248, 124, 7),
                showingTooltipIndicators: [],
                minX: 0,
                maxX: detectionCounts.length.toDouble() - 1,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      detectionCounts.length,
                      (index) =>
                          FlSpot(index.toDouble(), detectionCounts[index]),
                    ),
                    isCurved: true,
                    color: const Color.fromARGB(255, 0, 225, 255),
                    belowBarData: BarAreaData(show: true),
                  ),
                ],
                titlesData: const FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameSize: 9,
                    drawBelowEverything: true,
                    sideTitles: SideTitles(showTitles: true, reservedSize: 20),
                  ),
                  leftTitles: AxisTitles(
                    drawBelowEverything: true,
                    sideTitles: SideTitles(showTitles: true, reservedSize: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        color: color,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor),
        iconSize: 30,
      ),
    );
  }

  Future<void> loadYoloModel() async {
    try {
      var gpuDelegateV2;
      try {
        gpuDelegateV2 = GpuDelegateV2(
          options: GpuDelegateOptionsV2(
            inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
            inferencePriority1: TfLiteGpuInferencePriority.minLatency,
            inferencePriority2: TfLiteGpuInferencePriority.auto,
            inferencePriority3: TfLiteGpuInferencePriority.auto,
          ),
        );
        debugPrint('gpu is available');
      } catch (e) {
        debugPrint('Failed to initialize gpu delegate: $e');
      }
      var interpreterOptions = InterpreterOptions();
      if (gpuDelegateV2 != null) {
        interpreterOptions.addDelegate(gpuDelegateV2);
      }

      await widget.vision.loadYoloModel(
        labels: 'assets/models/labels.txt',
        modelPath: 'assets/models/best_float32.tflite',
        modelVersion: "yolov8",
        numThreads: 2,
        quantization: true,
        useGpu: gpuDelegateV2 != null,
      );
      setState(() {
        isLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading YOLO model: $e');
    }
  }

  Future<void> loadYoloModelCpuFallback() async {
    try {
      await widget.vision.loadYoloModel(
        labels: 'assets/models/labels.txt',
        modelPath: 'assets/models/best_float32.tflite',
        modelVersion: "yolov8",
        numThreads: 2,
        quantization: false,
        useGpu: false,
      );
      setState(() {
        isLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading YOLO model with CPU fallback: $e');
      debugPrint('Check the implementations well before running inference');
    }
  }

  Future<bool> isGpuCompatible() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 21;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.systemVersion.compareTo("10.0") >= 0;
    } else {
      return false;
    }
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    try {
      final result = await widget.vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.5,
        confThreshold: 0.5,
      );

      setState(() {
        yoloResults = result;
      });
    } catch (e) {
      debugPrint('Error during YOLO on frame: $e');
    }
  }

  List<Widget> displayBoxesAroundRecognizedObjects(
      Size screen, BuildContext context) {
    if (yoloResults.isEmpty || controller.value.previewSize == null) return [];

    double factorX = screen.width / controller.value.previewSize!.height;
    double factorY = screen.height / controller.value.previewSize!.width;

    return yoloResults.map((result) {
      final box = result["box"];
      final left = box[0] * factorX;
      final right = box[1] * factorY;
      final width = (box[2] - box[0]) * factorX;
      final height = (box[3] - box[1]) * factorY;
      const double factor = 29.526773834228514;
      final double confi = box[4] * 100;
      final String type = result['tag'];

      Color colorPick = Colors.red;
      // takePhoto();
      _startListeningToLocation();
      // _calculateDistance();
      return Stack(
        children: [
          Positioned(
            left: left,
            top: right,
            width: width,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color.fromARGB(255, 235, 42, 17), width: 2.0),
              ),
              child: Text(
                "${result['tag']} ${(box[4] * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  backgroundColor: Colors.red,
                  color: Colors.white,
                  fontSize: 10.0,
                ),
              ),
            ),
          ),
          //
        ],
      );
    }).toList();
  }

  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });

    controller.startImageStream((CameraImage image) async {
      if (!isDetecting) return;
      await yoloOnFrame(image);
    });
    // startVideoRecording();
  }

  Future<void> stopDetection() async {
    // stopVideoRecording();
    setState(() {
      isDetecting = false;
    });
    controller.stopImageStream();
  }

  Future<void> startVideoRecording() async {
    if (controller != null && !controller.value.isRecordingVideo) {
      try {
        final videoDirectory = await getExternalStorageDirectory();
        final videoDirectoryPath =
            join(videoDirectory!.path, 'Videos Recorded');

        // Create the directory if it doesn't exist
        final directory = Directory(videoDirectoryPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final videoPath = join(videoDirectoryPath,
            'detection_video_${DateTime.now().millisecondsSinceEpoch}.mp4');

        await controller.startVideoRecording();
        setState(() {
          isRecordingVideo = true;
        });
        debugPrint('Video recording started.');
      } catch (e) {
        debugPrint('Error starting video recording: $e');
      }
    }
  }

  Future<void> stopVideoRecording() async {
    if (controller != null && controller.value.isRecordingVideo) {
      try {
        final videoFile = await controller.stopVideoRecording();
        final videoDirectory = await getExternalStorageDirectory();
        final videoDirectoryPath =
            join(videoDirectory!.path, 'Videos Recorded');

        // Create the directory if it doesn't exist
        final directory = Directory(videoDirectoryPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final videoPath = join(videoDirectoryPath,
            'detection_video_${DateTime.now().millisecondsSinceEpoch}.mp4');

        await videoFile.saveTo(videoPath);
        setState(() {
          isRecordingVideo = false;
        });
        debugPrint('Video recording stopped and saved to: $videoPath');
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
      }
    }
  }

  Future<void> takePhoto() async {
    try {
      debugPrint('Taking photo...');

      // Ensure the camera controller is initialized and ready
      if (!controller.value.isInitialized) {
        debugPrint('Camera controller is not initialized.');
        return;
      }
      final XFile imageFile = await controller.takePicture();
      debugPrint('Photo taken: ${imageFile.path}');

      setState(() {
        image = File(imageFile.path);
      });
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final photoDirectoryPath = join(directory.path, 'Deection Photos');

        final photoDirectory = Directory(photoDirectoryPath);
        if (!await photoDirectory.exists()) {
          await photoDirectory.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final photoPath = join(photoDirectoryPath, 'photo_$timestamp.jpg');
        await File(imageFile.path).copy(photoPath);
        debugPrint('Photo saved at: $photoPath');
      } else {
        debugPrint('External storage directory not found.');
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }
}
