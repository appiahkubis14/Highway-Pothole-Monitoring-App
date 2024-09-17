// ignore_for_file: prefer_const_constructors, collection_methods_unrelated_type, depend_on_referenced_packages, unused_element

import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
// import 'package:map_camera_flutter_2/map_camera_flutter_2.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:pothole/src/screens/auth/login.dart';
import 'package:pothole/src/screens/components/home/report/screens/report.dart';
import 'package:pothole/src/screens/components/models/on_frame.dart';
import 'package:pothole/src/screens/components/models/on_photos.dart';
import 'package:text_scroll/text_scroll.dart';

enum Options { none, imagev8, frame, calibration, graph, onVideo, logout }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FlutterVision vision;
  Options option = Options.none;

  final List<String> imgList = [
    'assets/images/1.jpg',
    'assets/images/2.jpg',
    'assets/images/3.jpg',
    'assets/images/4.jpg',
    'assets/images/5.jpg',
    'assets/images/6.jpg',
    'assets/images/7.jpg',
    'assets/images/8.jpg',
    'assets/images/9.jpg',
    'assets/images/10.jpg',
    'assets/images/11.jpg',
    'assets/images/12.jpg',
    'assets/images/13.png',
  ];

  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
  }

  @override
  void dispose() async {
    super.dispose();
    await vision.closeYoloModel();
  }

  final Box _boxLogin = Hive.box("login");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextScroll(
          'GHANA ROAD POTHOLE DETECTION AND REPORTER ',
          mode: TextScrollMode.endless,
          fadedBorder: true,
          textDirection: TextDirection.rtl,
          fadeBorderVisibility: FadeBorderVisibility.auto,
          intervalSpaces: 2,
          fadeBorderSide: FadeBorderSide.both,
          velocity: Velocity(pixelsPerSecond: Offset(150, 0)),
          delayBefore: Duration(milliseconds: 500),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            // fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.right,
          selectable: true,
        ),
      ),
      body: task(option),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.menu,
      label: Text(
        'MENU',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      activeIcon: Icons.close,
      backgroundColor: Color.fromARGB(179, 10, 106, 233),
      foregroundColor: Color.fromARGB(255, 240, 243, 243),
      activeBackgroundColor: Color.fromARGB(255, 236, 11, 11),
      activeForegroundColor: Colors.white,
      visible: true,
      useRotationAnimation: true,
      closeManually: false,
      curve: Curves.decelerate,
      renderOverlay: true,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      buttonSize:
          const Size(50.0, 50.0), // Increased button size for the SpeedDial
      children: [
        SpeedDialChild(
          child: Container(
            width: 70, // Increased width
            height: 70, // Increased height
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color.fromARGB(255, 10, 33, 241),
                  Color.fromARGB(255, 236, 6, 113),
                ], // Define your gradient colors
                begin: Alignment.topLeft, // Start of the gradient
                end: Alignment.bottomRight, // End of the gradient
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 25, 29, 28)
                      .withOpacity(0.5), // Shadow color with opacity
                  blurRadius: 1, // Amount of blur for the shadow
                  offset: Offset(4, 8), // Position of the shadow
                  spreadRadius: 1, // Spread radius
                ),
              ],
            ),
            child: Icon(Icons.logout_rounded,
                color: Colors.white, size: 30), // Adjusted icon size
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          label: 'Logout',
          onTap: () {
            setState(() {
              option = Options.logout;
            });
          },
          onLongPress: () => exit(0),
        ),
        SpeedDialChild(
          child: Container(
            width: 70, // Increased width
            height: 70, // Increased height
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color.fromARGB(255, 209, 245, 4),
                  Color.fromARGB(255, 190, 6, 236),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 25, 29, 28)
                      .withOpacity(0.5), // Shadow color with opacity
                  blurRadius: 1, // Amount of blur for the shadow
                  offset: Offset(4, 8), // Position of the shadow
                  spreadRadius: 1, // Spread radius
                ),
              ],
            ),
            child: Icon(Icons.home,
                color: Colors.white, size: 30), // Adjusted icon size
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          label: 'Home | Exit',
          onTap: () {
            setState(() {
              option = Options.graph;
            });
          },
          onLongPress: () => exit(0),
        ),
        // SpeedDialChild(
        //   child: Container(
        //     width: 70, // Increased width
        //     height: 70, // Increased height
        //     decoration: BoxDecoration(
        //       gradient: LinearGradient(
        //         colors: const [
        //           Color.fromARGB(255, 255, 140, 0),
        //           Color.fromARGB(255, 0, 255, 234),
        //         ],
        //         begin: Alignment.topLeft,
        //         end: Alignment.bottomRight,
        //       ),
        //       shape: BoxShape.circle,
        //       boxShadow: [
        //         BoxShadow(
        //           color: Colors.black.withOpacity(0.3),
        //           blurRadius: 10,
        //           offset: Offset(0, 5),
        //           spreadRadius: 2,
        //         ),
        //       ],
        //     ),
        //     child: Icon(Icons.restaurant_menu,
        //         color: Colors.white, size: 30), // Adjusted icon size
        //   ),
        //   backgroundColor: Colors.transparent,
        //   foregroundColor: Colors.white,
        //   label: 'Single Detector',
        //   onTap: () {
        //     setState(() {
        //       option = Options.calibration;
        //     });
        //   },
        // ),
        SpeedDialChild(
          child: Container(
            width: 70, // Increased width
            height: 70, // Increased height
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color.fromARGB(255, 123, 31, 162),
                  Color.fromARGB(255, 229, 104, 32),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.camera,
                color: Colors.white, size: 30), // Adjusted icon size
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          label: 'Multi  Detector    ',
          onTap: () {
            setState(() {
              option = Options.imagev8;
            });
          },
        ),
        SpeedDialChild(
          child: Container(
            width: 70, // Increased width
            height: 70, // Increased height
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color.fromARGB(255, 255, 1, 234),
                  Color.fromARGB(255, 14, 238, 201),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.video_call,
                color: Colors.white, size: 30), // Adjusted icon size
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          label: 'Real-Time Detector   ',
          onTap: () {
            setState(() {
              option = Options.frame;
            });
          },
        ),
        SpeedDialChild(
          child: Container(
            width: 70, // Increased width
            height: 70, // Increased height
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color.fromARGB(255, 1, 39, 255),
                  Color.fromARGB(255, 14, 238, 201),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.report,
                color: Colors.white, size: 30), // Adjusted icon size
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          label: 'Send Us Pothole Report  ',
          onTap: () {
            setState(() {
              option = Options.calibration;
            });
          },
        ),
      ],
    );
  }

  Widget task(Options option) {
    if (option == Options.frame) {
      return YoloVideo(
        vision: vision,
      );
    }
    if (option == Options.imagev8) {
      return DetectionOnFrames(vision: vision);
    }
    if (option == Options.onVideo) {
      return YoloVideo(
        vision: vision,
      );
    }
    if (option == Options.calibration) {
      return PotholeForm();
    }
    if (option == Options.logout) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _boxLogin.clear();
        _boxLogin.put("loginStatus", false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const Login();
            },
          ),
        );
      });
    }

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Positioned(
                  child: Container(
                    height: MediaQuery.of(context).size.height - 80,
                    child: Image.asset(
                      'assets/images/sp.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0, // Ensures the indicator is centered horizontally
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: 400,
                            aspectRatio: 16 / 9,
                            viewportFraction: 1,
                            initialPage: 0,
                            enableInfiniteScroll: true,
                            reverse: false,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 3),
                            autoPlayAnimationDuration:
                                Duration(milliseconds: 1000),
                            autoPlayCurve: Curves.decelerate,
                            enlargeCenterPage: true,
                            scrollDirection: Axis.horizontal,
                            onPageChanged: (index, reason) {
                              setState(() {});
                            },
                          ),
                          items: imgList.map((i) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: Image.asset(
                                    i,
                                    fit: BoxFit.fitHeight,
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
