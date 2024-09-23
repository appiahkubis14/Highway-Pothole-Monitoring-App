// ignore_for_file: use_build_context_synchronously, sized_box_for_whitespace

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pothole/src/screens/components/home/data/model/pothole_model.dart';
import 'package:pothole/src/screens/components/home/data/model/service.dart';
import 'package:pothole/src/screens/components/home/data/screens/map.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';

class PotholeForm extends StatefulWidget {
  const PotholeForm({Key? key}) : super(key: key);

  @override
  _PotholeFormState createState() => _PotholeFormState();
}

class _PotholeFormState extends State<PotholeForm> {
  File? _image;
  File? _video;
  final TextEditingController _aiDescriptionController =
      TextEditingController();
  final TextEditingController _alternateDescriptionController =
      TextEditingController();

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

  // @override
  // void initState() {
  //   super.initState();
  //   fetchPotholes();
  // }

  // void fetchPotholes() async {
  //   ApiService apiService = ApiService();
  //   try {
  //     List<Pothole> fetchedPotholes = await apiService.fetchPotholes();
  //     setState(() {
  //       potholes = fetchedPotholes;
  //       markers = potholes.asMap().entries.map((entry) {
  //         int index = entry.key + 1;
  //         Pothole pothole = entry.value;

  //         return Marker(
  //           markerId: MarkerId(pothole.id.toString()),
  //           position: LatLng(pothole.locationLat, pothole.locationLon),
  //           infoWindow: InfoWindow(
  //             title: 'Pothole $index',
  //             snippet: pothole.aiDescription,
  //           ),
  //         );
  //       }).toSet();
  //       isLoading = false;
  //     });

  //     // Show snackbar for successful data loading
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Potholes loaded successfully')),
  //     );
  //   } catch (e) {
  //     // Show snackbar for failed data loading
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Failed to load potholes')),
  //     );
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }
  void _refreshMap() {
    setState(() {
      // Example: updating the camera position to current position
      if (_position != null) {
        mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_position!.latitude, _position!.longitude),
          ),
        );
      }

      // Example: updating markers
      markers.clear(); // Clear existing markers
      if (_position != null) {
        markers.add(
          Marker(
            markerId: const MarkerId("currentLocation"),
            position: LatLng(_position!.latitude, _position!.longitude),
          ),
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
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

  Future<void> _initializeVideoController() async {
    if (_video != null) {
      try {
        _videoController = VideoPlayerController.file(_video!)
          ..initialize().then((_) {
            setState(() {});
            _videoController?.play();
          });
      } catch (e) {
        debugPrint("Error initializing video: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load video')),
        );
      }
    }
  }

  Future<void> recordVideo() async {
    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _video = File(pickedFile.path);
        _initializeVideoController();
      }
    });
  }

  Future<void> _getLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _position = position;
    });
  }

  Future<void> _generateDescription(Uint8List imageBytes) async {
    if (_position == null) {
      await _getLocation();
    }

    // Show loader
    _showLoaderDialog('Generating AI Description...');

    const apiKey =
        'AIzaSyD9T_7POkcxT4SxV9rgXXoANyWhzecKnmY'; // Replace with your actual API key
    final model = GenerativeModel(
      model: 'gemini-1.5-pro', // Correct model for text generation
      apiKey: apiKey,
    );

    try {
      const prompt = "Describe the content of the image to the user";

      // Prepare content with both text and image
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg',
              imageBytes), // Send the image bytes along with the prompt
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

    // Show loader
    _showLoaderDialog('Submitting Pothole Report...');

    final dio = Dio();
    final Map<String, dynamic> formDataMap = {
      'ai_description': _aiDescriptionController.text,
      'alternate_description': _alternateDescriptionController.text,
      'location_lat': _position?.latitude,
      'location_lon': _position?.longitude,
      'town_name': _town_name.text,
      'road_type': _road_type.text,
      'road_name': _road_name.text,
      'origin': _origin.text,
      'destination': _destination.text
    };

    try {
      String? imageUrl;
      if (_image != null) {
        final imageFormData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_image!.path,
              filename: 'pothole.jpg'),
        });
        final imageResponse = await dio
            .post('http://10.0.2.2:8000/api/upload/image', data: imageFormData);
        if (imageResponse.statusCode == 200) {
          imageUrl = imageResponse.data['url'];
        } else {
          throw Exception(
              'Image upload failed with status code ${imageResponse.statusCode}');
        }
      }

      String? videoUrl;
      if (_video != null) {
        final videoFormData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_video!.path,
              filename: 'pothole.mp4'),
        });
        final videoResponse = await dio
            .post('http://10.0.2.2:8000/api/upload/video', data: videoFormData);
        if (videoResponse.statusCode == 200) {
          videoUrl = videoResponse.data['url'];
        } else {
          throw Exception(
              'Video upload failed with status code ${videoResponse.statusCode}');
        }
      }

      formDataMap['image_url'] = imageUrl;
      formDataMap['video_url'] = videoUrl;

      final response = await dio.post('http://10.0.2.2:8000/api/potholes/',
          data: formDataMap);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pothole submitted successfully')),
        );
      } else {
        throw Exception(
            'Pothole submission failed with status code ${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
      print(error);
    } finally {
      Navigator.pop(context);
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                _image == null
                    ? ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('Take Photo'),
                      )
                    : Container(
                        margin: const EdgeInsets.only(left: 10, right: 10),
                        height: 300,
                        width: MediaQuery.of(context).size.width,
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
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
              'SYSTEM COMMENT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width - 40,
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
              width: MediaQuery.of(context).size.width - 150,
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
                child: const Text('Comment with AI'),
              ),
            ),

            const SizedBox(height: 20),
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
                maxLines: 3,
                controller: _alternateDescriptionController,
                decoration: const InputDecoration(
                  hintText:
                      'Comment   e.g The road now is severe and needs immediate attention',
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
              width: MediaQuery.of(context).size.width - 40,
              child: TextField(
                controller: _road_name,
                decoration: const InputDecoration(
                  hintText: 'Specify Road Name    e.g Tema Motor Way',
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
              width: MediaQuery.of(context).size.width - 40,
              child: TextField(
                controller: _origin,
                decoration: const InputDecoration(
                  hintText: 'Your Origin    e.g Kumasi',
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
              width: MediaQuery.of(context).size.width - 40,
              child: TextField(
                controller: _destination,
                decoration: const InputDecoration(
                  hintText: 'Your Destinaltion    e.g Cape Coast',
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
              width: MediaQuery.of(context).size.width - 40,
              child: TextField(
                controller: _town_name,
                decoration: const InputDecoration(
                  hintText: 'Specify City | Town Name   e.g Accra',
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
              width: MediaQuery.of(context).size.width - 40,
              child: TextField(
                controller: _road_type,
                decoration: const InputDecoration(
                  hintText: 'Road Type   e.g Highway , Feeder Road',
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

            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: Container(
                width: MediaQuery.of(context).size.width - 40,
                height: 500,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _position != null
                        ? LatLng(_position!.latitude, _position!.longitude)
                        : const LatLng(6.0, -1.0), // Default position
                    zoom: 8.0,
                  ),
                  markers: markers,
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.center,
              children: [
                _video != null && _videoController != null
                    ? FutureBuilder(
                        future: _videoController?.initialize(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                height: 400,
                                width: MediaQuery.of(context).size.width - 40,
                                child: AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                ),
                              ),
                            );
                          } else {
                            return const CircularProgressIndicator();
                          }
                        },
                      )
                    : Container(
                        height: 63,
                        width: MediaQuery.of(context).size.width - 60,
                        child: ElevatedButton(
                          onPressed: recordVideo,
                          child: const Text('Record Video'),
                        ),
                      ),
                // Play button
                if (_videoController != null &&
                    (_videoController!.value.isInitialized &&
                        !_videoController!.value.isPlaying))
                  GestureDetector(
                    child: IconButton(
                      icon: const Icon(Icons.play_circle_fill,
                          size: 64, color: Colors.white),
                      onPressed: () {
                        _videoController?.play();
                        setState(() {});
                      },
                    ),
                    onTap: () {
                      _videoController?.play();
                      setState(() {});
                    },
                  ),
                if (_videoController != null &&
                    _videoController!.value.isInitialized &&
                    _videoController!.value.isPlaying)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.red,
                      ),
                    ),
                  ),
                // Delete button to remove the video
                _video != null
                    ? Positioned(
                        right: 0,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _video = null;
                              _videoController?.dispose();
                              _videoController = null;
                            });
                          },
                          icon: const Icon(Icons.delete),
                          color: Colors.deepOrange,
                        ),
                      )
                    : Container(),
              ],
            ),

            const SizedBox(height: 50),
            // AI Description Text Field

            // Submit Button
            Container(
              width: MediaQuery.of(context).size.width - 60,
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
// this is the flutter side code , implement that and rewrite the complete code 