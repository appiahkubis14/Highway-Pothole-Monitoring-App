// ignore_for_file: use_build_context_synchronously, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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
  Position? _position;
  VideoPlayerController? _videoController;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
    _generateDescription();
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

  Future<void> _generateDescription() async {
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
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        setState(() {
          _aiDescriptionController.text = response.text!;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate description')));
      }
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      // Dismiss loader
      Navigator.pop(context);
    }
  }

  Future<void> _submitPothole() async {
    if (_image == null && _video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a photo or video')));
      return;
    }

    // Show loader
    _showLoaderDialog('Submitting Pothole Data...');

    var dio = Dio();
    var formData = FormData.fromMap({
      'ai_description': _aiDescriptionController.text,
      'alternate_description': _alternateDescriptionController.text,
      'image': _image != null
          ? await MultipartFile.fromFile(_image!.path, filename: 'pothole.jpg')
          : null,
      'video': _video != null
          ? await MultipartFile.fromFile(_video!.path, filename: 'pothole.mp4')
          : null,
      'location_lat': _position?.latitude,
      'location_lon': _position?.longitude,
    });

    try {
      var response =
          await dio.post('http://10.0.2.2:8000/api/potholes/', data: formData);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pothole submitted successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission failed'),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
      debugPrint('$error');
    } finally {
      // Dismiss loader
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
                        height: 300,
                        width: MediaQuery.of(context).size.width,
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        )),
                _image != null
                    ? Positioned(
                        right: 0,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _image = null;
                            });
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
                maxLines: 2,
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
                onPressed: _generateDescription,
                child: const Text('Generate Description with AI'),
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
                maxLines: 2,
                controller: _alternateDescriptionController,
                decoration: const InputDecoration(
                  labelText: '',
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
            const SizedBox(height: 50),
            Image.asset(
              "assets/images/map.png",
              scale: 0.7,
              width: MediaQuery.of(context).size.width - 70,
            ),
            Container(
              width: MediaQuery.of(context).size.width - 60,
              height: 63,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapPage(),
                      ));
                },
                child: const Text('View Pothole Location on Map'),
              ),
            ),
            const SizedBox(height: 50),
            Stack(
              alignment: Alignment.center,
              children: [
                _video != null && _videoController != null
                    ? FutureBuilder(
                        future: _videoController?.initialize(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
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
