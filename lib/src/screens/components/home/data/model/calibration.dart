import 'package:flutter/services.dart';

class CameraCalibration {
  static const platform = MethodChannel('com.example.camera/undistort');

  Future<void> undistortImage(String imagePath) async {
    try {
      final result = await platform.invokeMethod('undistort', {'imagePath': imagePath});
      return result;
    } on PlatformException catch (e) {
      print("Failed to undistort image: ${e.message}");
    }
  }
}
