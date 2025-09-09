import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: StreetMap(),
  ));
}

class StreetMap extends StatefulWidget {
  const StreetMap({super.key});

  @override
  State<StreetMap> createState() => _StreetMapState();
}

class _StreetMapState extends State<StreetMap> {
  MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Street Map'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(0, 0),
                minZoom: 3,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  //userAgentPackageName: 'com.example.flutter_map_integration',
                ),
                CurrentLocationLayer(
                  style: const LocationMarkerStyle(
                    marker: DefaultLocationMarker(
                      child: Icon(Icons.location_pin,color: Colors.white,),
                    ),
                    markerSize: Size(35, 35),
                    markerDirection: MarkerDirection.heading
                  ),
                ),
              ]),
        ],
      ),
    );
  }
}
