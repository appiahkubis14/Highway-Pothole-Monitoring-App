// ignore_for_file: use_build_context_synchronously, sized_box_for_whitespace, non_constant_identifier_names, library_private_types_in_public_api, deprecated_member_use, unused_element

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pothole/src/screens/components/home/data/model/pothole_model.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class PotholeForm extends StatefulWidget {
  const PotholeForm({super.key});

  @override
  _PotholeFormState createState() => _PotholeFormState();
}

class _PotholeFormState extends State<PotholeForm> {
  File? _image;
  File? _video;
  final TextEditingController _aiDescriptionController = TextEditingController();
  final TextEditingController _alternateDescriptionController = TextEditingController();
  final TextEditingController _origin = TextEditingController();
  final TextEditingController _destination = TextEditingController();
  final TextEditingController _town_name = TextEditingController();
  final TextEditingController _road_type = TextEditingController();
  final TextEditingController _road_name = TextEditingController();

  Position? _position;
  VideoPlayerController? _videoController;
  late GoogleMapController mapController;
  List<Pothole> potholes = [];
  Set<Marker> markers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePosition();
  }

  Future<void> _initializePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _position = position;
      _addBlinkingMarker(LatLng(_position!.latitude, _position!.longitude)); // Trigger blinking marker
      isLoading = false;
    });

    // Move the camera to the user's location
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_position!.latitude, _position!.longitude),
        18.0,
      ),
    );
  }

// Function to add a blinking marker
  void _addBlinkingMarker(LatLng position) {
    BitmapDescriptor markerIcon;
    bool isMarkerVisible = true;

    // Load the custom marker icon for blinking effect
    BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(30, 30)), 'assets/images/map.png')
        .then((value) {
      markerIcon = value;

      // Start a timer to toggle marker visibility (blinking effect)
      Timer.periodic(const Duration(milliseconds: 500), (timer) {
        setState(() {
          // Toggle the marker visibility
          isMarkerVisible = !isMarkerVisible;

          markers.removeWhere((marker) => marker.markerId.value == 'Found Pothole Location'); // Remove old marker

          if (isMarkerVisible) {
            // Add the marker if visible
            markers.add(Marker(
                draggable: true,
                markerId: const MarkerId('Found Pothole Location'),
                position: position,
                infoWindow: const InfoWindow(title: 'Found Pothole Location'),
                icon: BitmapDescriptor.defaultMarker,
                consumeTapEvents: true // Custom blinking icon
                ));
          }
        });
      });
    });
  }

  void _refreshMap() {
    setState(() {
      // Example: updating the camera position to current position
      if (_position != null) {
        mapController.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_position!.latitude, _position!.longitude),
          ),
        );
      }

      markers.clear();
      if (_position != null) {
        markers.add(
          Marker(
            markerId: const MarkerId("Pothole Location Found"),
            position: LatLng(_position!.latitude, _position!.longitude),
          ),
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
    _generateDescription(_image as Uint8List);
  }

  Future<void> requestPermissions() async {
    await [
      Permission.camera,
      Permission.storage,
    ].request();
  }

  Future<void> _recordVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _video = File(pickedFile.path);
        _videoController = VideoPlayerController.file(_video!)
          ..initialize().then((_) {
            setState(() {});
            _videoController!.setLooping(true);
          });
      });
    }
  }

  Future<void> _generateDescription(Uint8List imageBytes) async {
    if (_position == null) {}

    // Show loader
    _showLoaderDialog('Generating AI Description...');

    const apiKey = 'AIzaSyD9T_7POkcxT4SxV9rgXXoANyWhzecKnmY'; // Replace with your actual API key
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest', // Correct model for text generation
      apiKey: apiKey,
    );

    try {
      final prompt = """if you find pothole in the image : Generate detail description for the pothole at
           ${_position!.latitude} ,${_position!.longitude} and display the 
           coordinates as well else describe what you see in the image""";

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      if (response.text != null) {
        setState(() {
          _aiDescriptionController.text = response.text!;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate description')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      // Dismiss loader
      Navigator.pop(context);
    }
  }

  Future<void> _submitPothole() async {
    if (_image == null && _video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo or video')),
      );
      return;
    }
    _showLoaderDialog('Sending Pothole Report...');

    final dio = Dio();
    try {
      // Construct FormData for submission
      final formData = FormData.fromMap({
        'ai_description': _aiDescriptionController.text.isNotEmpty ? _aiDescriptionController.text : 'N/A',
        'alternate_description':
            _alternateDescriptionController.text.isNotEmpty ? _alternateDescriptionController.text : 'N/A',
        'location_lat': _position?.latitude.toString() ?? '',
        'location_lon': _position?.longitude.toString() ?? '',
        'town_name': _town_name.text.isNotEmpty ? _town_name.text : 'Unknown Town',
        'road_type': _road_type.text.isNotEmpty ? _road_type.text : 'Unknown Road Type',
        'road_name': _road_name.text.isNotEmpty ? _road_name.text : 'Unnamed Road',
        'origin': _origin.text,
        'destination': _destination.text,
        if (_image != null)
          'image_url': await MultipartFile.fromFile(_image!.path,
              filename: 'pothole_${DateTime.now().millisecondsSinceEpoch}.jpg'),
        if (_video != null)
          'video_url': await MultipartFile.fromFile(_video!.path,
              filename: 'pothole_${DateTime.now().millisecondsSinceEpoch}.mp4'),
      });

      // Send POST request to the API
      final response = await dio.post('http://192.168.3.218:8000/api/pothole-reports/', data: formData);

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');

      if (response.statusCode == 201) {
        _aiDescriptionController.clear();
        _alternateDescriptionController.clear();
        _destination.clear();
        _origin.clear();
        _road_name.clear();
        _road_type.clear();
        _town_name.clear();
        setState(() {
          _image = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pothole report submitted successfully')),
        );
      } else {
        throw Exception('Pothole submission failed with status code ${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
      if (kDebugMode) {
        print('Error: $error');
      }
    } finally {
      Navigator.pop(context); // Hide loader
    }
  }

  void _showLoaderDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black38,
      appBar: AppBar(
        title: const TextScroll(
          'GHANA ROAD POTHOLE DETECTION AND REPORTER ',
          mode: TextScrollMode.endless,
          fadedBorder: true,
          textDirection: TextDirection.rtl,
          fadeBorderVisibility: FadeBorderVisibility.auto,
          intervalSpaces: 2,
          fadeBorderSide: FadeBorderSide.both,
          velocity: Velocity(pixelsPerSecond: Offset(150, 0)),
          delayBefore: Duration(milliseconds: 800),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            // fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.right,
          selectable: true,
        ),
        elevation: 20,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                const SizedBox(
                  height: 30,
                ),
                _image == null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text('Take Photo'),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.only(left: 10, right: 10),
                        height: 400,
                        width: MediaQuery.of(context).size.width,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                          ),
                        )),
                _image != null
                    ? Positioned(
                        right: 0,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _image = null;
                            });
                            _aiDescriptionController.clear();
                            _alternateDescriptionController.clear();
                          },
                          icon: const Icon(Icons.delete),
                          color: Colors.deepOrange,
                        ))
                    : Container(
                        height: 63,
                        width: MediaQuery.of(context).size.width - 60,
                        child: ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text('Take Photo'),
                        ),
                      ),
              ],
            ),

            const SizedBox(height: 20),
            const Text(
              'COMMENT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width - 20,
              child: TextField(
                maxLines: 10,
                controller: _aiDescriptionController,
                readOnly: true,
                decoration: const InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            // Generate AI Description Button
            Container(
              width: MediaQuery.of(context).size.width - 120,
              height: 63,
              child: ElevatedButton(
                onPressed: () async {
                  if (_image != null) {
                    // Read the file as bytes
                    Uint8List imageBytes = await _image!.readAsBytes();
                    // Pass the bytes to the _generateDescription function
                    await _generateDescription(imageBytes);
                  }
                },
                child: const Text('Create Comment'),
              ),
            ),

            const SizedBox(height: 30),
            Divider(),
            // Alternate Description Text Field
            const Text(
              'USER COMMENT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width - 40,
              child: TextField(
                maxLines: 2,
                controller: _alternateDescriptionController,
                decoration: const InputDecoration(
                  hintText: 'comment',
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              height: 50,
              width: MediaQuery.of(context).size.width - 40,
              child: TextField(
                controller: _road_name,
                decoration: const InputDecoration(
                  hintText: 'road name',
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              height: 50,
              width: MediaQuery.of(context).size.width - 40,
              child: TextField(
                controller: _origin,
                decoration: const InputDecoration(
                  hintText: 'origin',
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),

            Container(
              height: 50,
              width: MediaQuery.of(context).size.width - 40,
              child: TextField(
                controller: _destination,
                decoration: const InputDecoration(
                  hintText: 'destinaltion',
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),

            Container(
              height: 50,
              width: MediaQuery.of(context).size.width - 40,
              child: TextField(
                controller: _town_name,
                decoration: const InputDecoration(
                  hintText: 'town name',
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),

            Container(
              height: 50,
              width: MediaQuery.of(context).size.width - 40,
              child: TextField(
                controller: _road_type,
                decoration: const InputDecoration(
                  hintText: 'road type',
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),

            // const SizedBox(height: 50),
            const SizedBox(height: 30),

            Center(
              child: Container(
                decoration:
                    BoxDecoration(border: Border.all(width: 2), borderRadius: BorderRadius.all(Radius.circular(20))),
                width: MediaQuery.of(context).size.width - 40,
                height: 300,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: GoogleMap(
                    mapType: MapType.satellite,
                    initialCameraPosition: CameraPosition(
                      target: _position != null
                          ? LatLng(_position!.latitude, _position!.longitude)
                          : const LatLng(0, -0), // Default position
                      zoom: 8.0,
                    ),
                    markers: markers,
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Stack(
              alignment: Alignment.center,
              children: [
                // _video != null && _videoController != null
                //     ? FutureBuilder(
                //         future: _videoController?.initialize(),
                //         builder: (context, snapshot) {
                //           if (snapshot.connectionState == ConnectionState.done) {
                //             return ClipRRect(
                //               borderRadius: BorderRadius.circular(20),
                //               child: Container(
                //                 height: 400,
                //                 width: MediaQuery.of(context).size.width - 40,
                //                 child: AspectRatio(
                //                   aspectRatio: _videoController!.value.aspectRatio,
                //                   child: VideoPlayer(_videoController!),
                //                 ),
                //               ),
                //             );
                //           } else {
                //             return const CircularProgressIndicator();
                //           }
                //         },
                //       )
                //     : Container(
                //         height: 63,
                //         width: MediaQuery.of(context).size.width - 60,
                //         child: ElevatedButton(
                //           onPressed: _recordVideo, // Trigger recording
                //           child: const Text('Record Video'),
                //         ),
                //       ),
                // if (_videoController != null &&
                //     (_videoController!.value.isInitialized && !_videoController!.value.isPlaying))
                //   GestureDetector(
                //     child: IconButton(
                //       icon: const Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                //       onPressed: () {
                //         _videoController?.play();
                //         setState(() {});
                //       },
                //     ),
                //     onTap: () {
                //       _videoController?.play();
                //       setState(() {});
                //     },
                //   ),
                // if (_videoController != null &&
                //     _videoController!.value.isInitialized &&
                //     _videoController!.value.isPlaying)
                //   Positioned(
                //     bottom: 10,
                //     left: 10,
                //     right: 10,
                //     child: VideoProgressIndicator(
                //       _videoController!,
                //       allowScrubbing: true,
                //       colors: const VideoProgressColors(
                //         playedColor: Colors.red,
                //       ),
                //     ),
                //   ),
                // _video != null
                //     ? Positioned(
                //         right: 0,
                //         child: IconButton(
                //           onPressed: () {
                //             setState(() {
                //               _video = null;
                //               _videoController?.dispose();
                //               _videoController = null;
                //             });
                //           },
                //           icon: const Icon(Icons.delete),
                //           color: Colors.deepOrange,
                //         ),
                //       )
                //     : Container(),
              ],
            ),

            const SizedBox(height: 30),
            Container(
              width: MediaQuery.of(context).size.width - 40,
              height: 63,
              child: ElevatedButton(
                onPressed: _submitPothole,
                child: const Text('Send Report'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
