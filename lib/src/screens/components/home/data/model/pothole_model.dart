// pothole_model.dart
class Pothole {
  final String id;
  final String aiDescription;
  final String alternateDescription;
  final String image;
  final String video;
  final double locationLat;
  final double locationLon;

  Pothole({
    required this.id,
    required this.aiDescription,
    required this.alternateDescription,
    required this.image,
    required this.video,
    required this.locationLat,
    required this.locationLon,
  });

  factory Pothole.fromJson(Map<String, dynamic> json) {
    return Pothole(
      id: json['id'],
      aiDescription: json['ai_description'],
      alternateDescription: json['alternate_description'],
      image: json['image'],
      video: json['video'],
      locationLat: json['location_lat'],
      locationLon: json['location_lon'],
    );
  }
}
