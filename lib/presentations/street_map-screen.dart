import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class StreetMap extends StatefulWidget {
  const StreetMap({super.key});

  @override
  State<StreetMap> createState() => _StreetMapState();
}

class _StreetMapState extends State<StreetMap> {
  final MapController _mapController = MapController();
  LatLng? initialPostion;
  bool isLoading =true; 
  @override
  void initState() {
    super.initState();
    setInitialPostion();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

// void _centerMapOnUser() {
//   Geolocator.getPositionStream(
//     locationSettings: const LocationSettings(
//       accuracy: LocationAccuracy.high,
//       distanceFilter: 10, // updates only if user moves 10 meters
//     ),
//   ).listen((Position position) {
//     print("Lat: ${position.latitude}, Lon: ${position.longitude}");
//     _mapController.move(
//       LatLng(position.latitude, position.longitude), // new center
//       _mapController.camera.center.latitude, // keep current zoom
//     );
//     setState(() {}); // triggers FlutterMap redraw
//   });
// }
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
                initialCenter: isLoading?LatLng(9.00, 38.7):initialPostion!,
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
                      child: Icon(Icons.location_pin, color: Colors.white),
                    ),
                    markerSize: Size(30, 30),
                    markerDirection: MarkerDirection.heading,
                  
                  ),
                ),
              ]),
              if(isLoading)Center(child: CircularProgressIndicator(color: Colors.blue,),)
              
        ],
      ),
    );
  }

  Future<void> setInitialPostion() async {
    final Position? pos = await _initLocation();
    if(pos!=null){
     await Future.delayed(const Duration(seconds: 3));
        setState(() {
        initialPostion = LatLng(pos.latitude, pos.longitude);
        isLoading=false;
      });
      _mapController.move(initialPostion!, 12);
    }
    else{
      setState(() {
        isLoading=false;
      });
    }
 
  }

  Future<Position?> _initLocation() async {
    bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    print(isServiceEnabled);
    if (!isServiceEnabled) {
      await showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text(
                'Enable Location',
              ),
              content: const Text(
                  'Location Service are Disable,Please enable GPS to continue.'),
              actions: [
                TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Geolocator.openAppSettings();
                    },
                    child: const Text('Open Settings')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'))
              ],
            );
          });
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    print(permission);
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print(permission);
      if (permission == LocationPermission.denied) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Location permission denied. Cannot show current location."),
          ),
        );
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Permission Required"),
          content: const Text(
              "Location permission is permanently denied. Please enable it in app settings."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openAppSettings(); // Opens app settings
              },
              child: const Text("Open Settings"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      );
      return null;
    }
    return Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.best, distanceFilter: 10));
  }
}
