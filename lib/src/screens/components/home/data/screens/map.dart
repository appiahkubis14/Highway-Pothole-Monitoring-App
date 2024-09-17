import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pothole/src/screens/components/home/data/model/pothole_model.dart';
import 'package:pothole/src/screens/components/home/data/model/service.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  List<Pothole> potholes = [];
  Set<Marker> markers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPotholes();
  }

  void fetchPotholes() async {
    ApiService apiService = ApiService();
    try {
      List<Pothole> fetchedPotholes = await apiService.fetchPotholes();
      setState(() {
        potholes = fetchedPotholes;
        markers = potholes.asMap().entries.map((entry) {
          int index = entry.key + 1;
          Pothole pothole = entry.value;

          return Marker(
            markerId: MarkerId(pothole.id.toString()),
            position: LatLng(pothole.locationLat, pothole.locationLon),
            infoWindow: InfoWindow(
              title: 'Pothole $index',
              snippet: pothole.aiDescription,
            ),
          );
        }).toSet();
        isLoading = false;
      });

      // Show snackbar for successful data loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Potholes loaded successfully')),
      );
    } catch (e) {
      // Show snackbar for failed data loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load potholes')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pothole Map')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: potholes.isNotEmpty
                    ? LatLng(
                        potholes.first.locationLat, potholes.first.locationLon)
                    : LatLng(6.0, -1.0), // Default position
                zoom: 12.0,
              ),
              markers: markers,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
    );
  }
}
