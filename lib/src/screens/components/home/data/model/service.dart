// api_service.dart
import 'package:dio/dio.dart';
import 'pothole_model.dart';

class ApiService {
  final String baseUrl =
      "http://127.0.0.1:8000/api/fetch_potholes/"; // Use http://localhost:8000/ for iOS
  Dio dio = Dio();

  Future<List<Pothole>> fetchPotholes() async {
    try {
      Response response = await dio.get(baseUrl);
      List<dynamic> data = response.data;

      // Convert the JSON list to a list of Pothole objects
      return data.map((item) => Pothole.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load potholes');
    }
  }
}
