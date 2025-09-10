import 'dart:async';

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

  bool isLoading = true;
  List<Map<String, dynamic>> _suggestions = [];
  LatLng? destinationPosition;
  final TextEditingController _locationTextController = TextEditingController();
  ValueNotifier<String> textNotifier = ValueNotifier('');
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    setInitialPostion();
    _locationTextController.addListener(() {
      textNotifier.value = _locationTextController.text;
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
                  initialCenter:
                      isLoading ? LatLng(9.00, 38.7) : initialPosition!,
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
            if (isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.only(left: 12,right: 12, top: 6, bottom: 6),
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
                        builder: (context, value, child) {
                          return TextField(
                            controller: _locationTextController,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: "Search here...",
                              prefixIcon:
                                  const Icon(Icons.search, color: Colors.blue),
                              suffixIcon: value.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: Colors.black),
                                      onPressed: () {
                                        _locationTextController.clear();
                                        setState(() => _suggestions = []);
                                        _debounce?.cancel();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                            ),
                            onChanged: _onSearchChanged,
                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                            },
                            onSubmitted: (value) async {
                              if (value.isNotEmpty) {
                                final LatLng? latLng = await _placeService
                                    .destinationCalculator(destination: value);
                                if (latLng != null) {
                                  _mapController.move(latLng, 10);
                                }
                              }
                            },
                          );
                        }),
                  ),
                  if (_suggestions.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final place = _suggestions[index];
                          final fullName = place['display_name'] as String;
                          // Split by comma to separate main name from details
                          final parts = fullName.split(',');
                          final title =
                              parts.isNotEmpty ? parts.first.trim() : fullName;
                          final subtitle = parts.length > 1
                              ? parts.sublist(1).join(',').trim()
                              : '';
                          return ListTile(
                            leading: const Icon(Icons.location_on,color: Colors.grey,),
                              title: highlightMatch(title, _locationTextController.text),
                            subtitle: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _onSuggestionTap(place),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: () {},
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
            size: 30,
          ),
        ));
  }
  Widget highlightMatch(String text, String query) {
  if (query.isEmpty) return Text(text);

  final queryLower = query.toLowerCase();
  final textLower = text.toLowerCase();

  final startIndex = textLower.indexOf(queryLower);
  if (startIndex == -1) return Text(text); // no match found

  final endIndex = startIndex + query.length;

  return RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: text.substring(0, startIndex),
          style: const TextStyle(color: Colors.black),
        ),
        TextSpan(
          text: text.substring(startIndex, endIndex),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold, // highlight
          ),
        ),
        TextSpan(
          text: text.substring(endIndex),
          style: const TextStyle(color: Colors.black),
        ),
      ],
    ),
  );
}


  void _onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final results = await _placeService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
        });
      }
    });
  }

  void _onSuggestionTap(Map<String, dynamic> place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final position = LatLng(lat, lon);
    _mapController.move(position, 12);

    setState(() {
      _suggestions = [];
      _locationTextController.text = place['display_name'];
      initialPosition = position;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> setInitialPostion() async {
    final Position? pos = await _initLocation();
    if (pos != null) {
      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        initialPosition = LatLng(pos.latitude, pos.longitude);
        isLoading = false;
      });
      _mapController.move(initialPosition!, 12);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> setDestinationPostion({required String destinationPlace}) async {
    destinationPosition = await _placeService.destinationCalculator(
        destination: destinationPlace);
  }

  Future<Position?> _initLocation() async {
    bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
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
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
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
