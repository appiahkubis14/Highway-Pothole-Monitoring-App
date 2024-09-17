// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:async';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:fl_chart/fl_chart.dart';
import 'package:animated_snack_bar/animated_snack_bar.dart'; // Assuming you have an animated_snack_bar package

class DetectionOnFrames extends StatefulWidget {
  final FlutterVision vision;
  const DetectionOnFrames({super.key, required this.vision});

  @override
  State<DetectionOnFrames> createState() => _DetectionOnFramesState();
}

class _DetectionOnFramesState extends State<DetectionOnFrames> {
  List<List<Map<String, dynamic>>> yoloResults = [];
  List<File>? imageFiles;
  List<Map<String, int>> imageDimensions = [];
  bool isLoaded = false;
  bool _isLoading = false;
  bool _showGraphs = false;

  @override
  void initState() {
    super.initState();
    loadYoloModel().then((value) {
      setState(() {
        isLoaded = true;
      });
    });
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
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned(
              child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/images/Background.jpg"),
                    fit: BoxFit.cover,
                    opacity: 0.3)),
          )),
          SingleChildScrollView(
            child: Column(
              children: [
                if (!_showGraphs) ...[
                  if (imageFiles != null && imageFiles!.isNotEmpty)
                    ...imageFiles!.asMap().entries.map((entry) {
                      int index = entry.key;
                      File imageFile = entry.value;

                      if (index >= imageDimensions.length) {
                        // Avoid accessing before dimensions are available
                        return const SizedBox();
                      }

                      double aspectRatio = imageDimensions[index]['width']! /
                          imageDimensions[index]['height']!;
                      double height = size.width / aspectRatio;

                      return SizedBox(
                        height: height,
                        width: size.width,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              imageFile,
                              fit: BoxFit.contain,
                            ),
                            if (index < yoloResults.length)
                              ...displayBoxesAroundRecognizedObjects(
                                  size, index),
                          ],
                        ),
                      );
                    }),
                ] else ...[
                  const SizedBox(
                    height: 40,
                  ),
                  const Text('Number of detected food in each image'),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      height: 150,
                      child: BarChart(
                        BarChartData(
                          barGroups: _create2DData(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    children: [
                      const Text('Individual detections as points on a graph'),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                            height: 150,
                            child: LineChart(
                              LineChartData(
                                lineBarsData: _createAreaData(),
                              ),
                            )),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                          'Percentage distribution of detections across all images'),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: _createPieChartData(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    children: [
                      const Text('Trend of detections across the images'),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 150,
                          child: LineChart(
                            LineChartData(
                              lineBarsData: _createLineData(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    children: [
                      const Text('Individual detections as points on a graph'),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 150,
                          child: ScatterChart(
                            ScatterChartData(
                              scatterSpots: _createScatterData(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                          'Percentage distribution of detections across all images'),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              barGroups: _createHistogramData(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CupertinoActivityIndicator(
                radius: 20,
              ),
            ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            left: 25,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.only(right: 280),
              child: SpeedDial(
                label: const Text("OPEN",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                icon: Icons.open_in_full,
                activeIcon: Icons.close,
                backgroundColor: const Color.fromARGB(31, 87, 12, 226),
                foregroundColor: const Color.fromARGB(255, 240, 243, 243),
                activeBackgroundColor: const Color.fromARGB(255, 236, 11, 11),
                activeForegroundColor: Colors.white,
                switchLabelPosition: true,
                visible: true,
                closeManually: false,
                curve: Curves.decelerate,
                overlayColor: Colors.black,
                overlayOpacity: 0.5,
                buttonSize: const Size(50.0, 50.0),
                children: [
                  SpeedDialChild(
                      // shape: const CircleBorder(),
                      child: const Icon(Icons.download),
                      backgroundColor: const Color.fromARGB(255, 243, 33, 243),
                      foregroundColor: Colors.white,
                      label: 'Export Results',
                      onTap: () => exportDetectedImages(context)),
                  SpeedDialChild(
                      // shape: const CircleBorder(),
                      child: const Icon(Icons.restart_alt_outlined),
                      backgroundColor: const Color.fromARGB(255, 95, 54, 244),
                      foregroundColor: Colors.white,
                      label: 'Start Recognition',
                      onTap: () => yoloOnImages(context)),
                  SpeedDialChild(
                      // shape: const CircleBorder(),
                      child: const Icon(Icons.upload),
                      backgroundColor: const Color.fromARGB(255, 78, 180, 172),
                      foregroundColor: Colors.white,
                      label: 'Upload Foods',
                      onTap: () => pickImages(context)),
                  SpeedDialChild(
                    // shape: const CircleBorder(),
                    child: const Icon(Icons.bar_chart),
                    backgroundColor: const Color.fromARGB(255, 216, 178, 9),
                    foregroundColor: Colors.white,
                    label: 'Detection Graphs',
                    onTap: () {
                      setState(() {
                        _showGraphs = !_showGraphs;
                      });
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadYoloModel() async {
    await widget.vision.loadYoloModel(
      labels: 'assets/models/labels.txt',
      modelPath: 'assets/models/best_float32.tflite',
      modelVersion: "yolov8",
      quantization: false,
      numThreads: 2,
      useGpu: false,
    );
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> pickImages(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    final ImagePicker picker = ImagePicker();
    final List<XFile> photos = await picker.pickMultiImage();
    if (photos.isNotEmpty) {
      setState(() {
        imageFiles = photos.map((photo) => File(photo.path)).toList();
        imageDimensions.clear();
        yoloResults.clear();
      });

      for (File imageFile in imageFiles!) {
        Uint8List byte = await imageFile.readAsBytes();
        final image = await decodeImageFromList(byte);
        imageDimensions.add({"width": image.width, "height": image.height});
      }

      setState(() {
        imageDimensions = imageDimensions;
      });
    }
    yoloOnImages(context);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> yoloOnImages(BuildContext context) async {
    AnimatedSnackBar.material(
      'Detection on each image has begun. This may take some time...',
      type: AnimatedSnackBarType.success,
    ).show(context);

    setState(() {
      _isLoading = true;
    });
    if (imageFiles == null || imageFiles!.isEmpty) return;

    List<List<Map<String, dynamic>>> allResults = [];

    for (File imageFile in imageFiles!) {
      Uint8List byte = await imageFile.readAsBytes();
      final image = await decodeImageFromList(byte);
      final result = await widget.vision.yoloOnImage(
        bytesList: byte,
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.8,
        confThreshold: 0.4,
        classThreshold: 0.5,
      );

      print(result); // Debug print
      allResults.add(result);
    }

    setState(() {
      yoloResults = allResults;
      _isLoading = false;
    });

    AnimatedSnackBar.material(
      'Detection done successfully !!!.',
      type: AnimatedSnackBarType.success,
    ).show(context);
  }

  Future<void> exportDetectedImages(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    AnimatedSnackBar.material(
      'Exporting in progress...',
      type: AnimatedSnackBarType.info,
    ).show(context);
    final directory = await getExternalStorageDirectory();
    for (int index = 0; index < imageFiles!.length; index++) {
      final imageFile = imageFiles![index];
      final result = yoloResults[index];

      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes)!;

      for (var detection in result) {
        final x = detection['box'][0];
        final y = detection['box'][1];
        final width = detection['box'][2];
        final height = detection['box'][3];
      }

      final fileName = basename(imageFile.path).replaceAll('.', '_detected.');
      final path = '${directory!.path}/$fileName';
      await File(path).writeAsBytes(Uint8List.fromList(img.encodeJpg(image)));
    }
    AnimatedSnackBar.material(
      'Detection results successfully exported !!!',
      type: AnimatedSnackBarType.success,
    ).show(context);
    setState(() {
      _isLoading = false;
    });
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen, int index) {
    if (yoloResults.isEmpty || index >= yoloResults.length) return [];

    double factorX = screen.width / imageDimensions[index]["width"]!;
    double aspectRatio =
        imageDimensions[index]["width"]! / imageDimensions[index]["height"]!;
    double newWidth = screen.width;
    double newHeight = newWidth / aspectRatio;
    double factorY = newHeight / imageDimensions[index]["height"]!;

    Color colorPick = const Color.fromARGB(255, 233, 16, 45);

    return yoloResults[index].map<Widget>((result) {
      final left = result["box"][0] * factorX;
      final top = result["box"][1] * factorY;
      final right = result["box"][2] * factorX;
      final bottom = result["box"][3] * factorY;
      final double factor = 29.526773834228514;

      final width = (right - left);
      final height = bottom - top;

      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2.0),
              ),
            ),
          ),
          Positioned(
            left: left,
            top: top - 18,
            width: width,
            height: height,
            child: Text(
              "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                  backgroundColor: colorPick,
                  color: Colors.white,
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      );
    }).toList();
  }

  List<BarChartGroupData> _create2DData() {
    List<int> counts = yoloResults.map((result) => result.length).toList();

    return counts.asMap().entries.map((entry) {
      int index = entry.key;
      int count = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: Colors.blue,
            width: 10,
          ),
        ],
      );
    }).toList();
  }

  List<LineChartBarData> _createLineData() {
    List<FlSpot> spots = [];
    for (int i = 0; i < yoloResults.length; i++) {
      spots.add(FlSpot(i.toDouble(), yoloResults[i].length.toDouble()));
    }

    return [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        barWidth: 4,
        color: Colors.red,
      ),
    ];
  }

  List<ScatterSpot> _createScatterData() {
    List<ScatterSpot> spots = [];
    for (int i = 0; i < yoloResults.length; i++) {
      spots.add(ScatterSpot(i.toDouble(), yoloResults[i].length.toDouble(),
          dotPainter: FlDotCirclePainter(
              color: Color.fromARGB(255, 248, 252, 26), radius: 5),
          show: true));
    }

    return spots;
  }

  List<PieChartSectionData> _createPieChartData() {
    List<int> counts = yoloResults.map((result) => result.length).toList();
    int totalCount = counts.fold(0, (sum, count) => sum + count);

    return counts.asMap().entries.map((entry) {
      int index = entry.key;
      int count = entry.value;
      double percentage = (count / totalCount) * 100;

      return PieChartSectionData(
        value: percentage,
        color: Colors.primaries[index % Colors.primaries.length],
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<ScatterSpot> _createBubbleData() {
    List<ScatterSpot> spots = [];
    for (int i = 0; i < yoloResults.length; i++) {
      spots.add(ScatterSpot(i.toDouble(), yoloResults[i].length.toDouble(),
          // radius: (yoloResults[i].length * 2).toDouble(), // Adjust the multiplier as needed
          show: true,
          dotPainter: FlDotSquarePainter(
            color: Colors.blue,
            size: 10,
          )));
    }

    return spots;
  }

  List<ScatterSpot> _createHeatMapData() {
    List<ScatterSpot> spots = [];
    for (int i = 0; i < yoloResults.length; i++) {
      spots.add(ScatterSpot(i.toDouble(), yoloResults[i].length.toDouble(),
          dotPainter: FlDotSquarePainter(
            size: yoloResults[i].length.toDouble(),
            color: _getColorBasedOnValue(yoloResults[i].length),
          ),
          show: true));
    }

    return spots;
  }

  Color _getColorBasedOnValue(int value) {
    if (value < 10) {
      return Color.fromARGB(255, 6, 252, 6);
    } else if (value < 20) {
      return Color.fromARGB(255, 45, 228, 219);
    } else if (value < 30) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  List<BarChartGroupData> _createHistogramData() {
    List<int> counts = yoloResults.map((result) => result.length).toList();
    Map<int, int> frequencyMap = {};

    for (int count in counts) {
      if (!frequencyMap.containsKey(count)) {
        frequencyMap[count] = 0;
      }
      frequencyMap[count] = frequencyMap[count]! + 1;
    }

    return frequencyMap.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.purple,
            width: 10,
          ),
        ],
      );
    }).toList();
  }

  List<LineChartBarData> _createAreaData() {
    List<FlSpot> spots = [];
    for (int i = 0; i < yoloResults.length; i++) {
      spots.add(FlSpot(i.toDouble(), yoloResults[i].length.toDouble()));
    }

    return [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        barWidth: 2,
        color: Colors.orange,
        belowBarData: BarAreaData(
          show: true,
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
    ];
  }
}
