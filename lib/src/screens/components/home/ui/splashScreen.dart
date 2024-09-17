// ignore_for_file: prefer_const_constructors_in_immutables, use_key_in_widget_constructors, deprecated_member_use, prefer_const_constructors, avoid_print, unused_field, library_private_types_in_public_api, sized_box_for_whitespace, sort_child_properties_last, unused_local_variable, prefer_const_literals_to_create_immutables, no_leading_underscores_for_local_identifiers, unused_element

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pothole/src/screens/components/home/ui/home.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/images/sp.png',
          fit: BoxFit.fill,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
