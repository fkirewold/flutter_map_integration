import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_integration/core/constants/url_constant.dart';
import 'package:flutter_map_integration/core/placeservice/place_service.dart';
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
  LatLng? initialPosition;
  final PlaceService _placeService = PlaceService();

  bool isLoading =true; 
  List<Map<String,dynamic>> _suggestions=[];
  LatLng? destinationPosition;
  final TextEditingController _locationTextController=TextEditingController();
  ValueNotifier<String> textNotifier=ValueNotifier('');
  @override
  void initState() {
    super.initState();
    setInitialPostion();
    _locationTextController.addListener((){
      textNotifier.value=_locationTextController.text;
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _locationTextController.dispose();
    textNotifier.dispose();
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
                initialCenter: isLoading?LatLng(9.00, 38.7):initialPosition!,
                minZoom: 3,
              ),
              children: [
                TileLayer(
                  urlTemplate: '$baseOpenStreetMapUrl/{z}/{x}/{y}.png',
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
         if(isLoading)Center(child: CircularProgressIndicator(color: Colors.blue,),),
         Column(
           children: [
             Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   margin: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(30),
                     boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
                     ],
                   ),
                   child: ValueListenableBuilder<String>(
                     valueListenable: textNotifier,
                     builder: (context,value,child) {
              return TextField(
                controller: _locationTextController,
                textInputAction:TextInputAction.search,
                decoration: InputDecoration(
                  hintText: "Search here...",
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  suffixIcon: value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black),
                          onPressed: () {
                            _locationTextController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                ),
                onChanged: (place){
                },
                onTapOutside: (event){
                  FocusScope.of(context).unfocus();
                },
                onSubmitted: (value) {},
                   
              );
                     }
                   ),
                 ),
             
           ],
         ),

              
        ],
      ),
    );
  }

  Future<void> setInitialPostion() async {
    final Position? pos = await _initLocation();
    if(pos!=null){
     await Future.delayed(const Duration(seconds: 3));
        setState(() {
        initialPosition = LatLng(pos.latitude, pos.longitude);
        isLoading=false;
      });
      _mapController.move(initialPosition!, 12);
    }
    else{
      setState(() {
        isLoading=false;
      });
    }
 
  }
  Future<void> setDestinationPostion({required String destinationPlace}) async{
    destinationPosition=await _placeService.destinationCalculator(destination: destinationPlace);
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
