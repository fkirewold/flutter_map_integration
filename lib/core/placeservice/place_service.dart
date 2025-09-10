import 'package:dio/dio.dart';
import 'package:flutter_map_integration/core/constants/url_constant.dart';
import 'package:latlong2/latlong.dart';

class PlaceService {
  final _dio = Dio();
  Future<LatLng?> destinationCalculator({required String destination}) async {
    try {
      final encodedName = Uri.encodeComponent(destination.trim());
      final response = await _dio.get(
          '$baseOpenStreetMapUrl/search?q=$encodedName&format=json&limit=1',
          options: Options(headers: {
            'User-Agent': 'com.example.flutter_map_integration/1.0.0'
          }));
      if (response.statusCode == 200) {
        final List data = response.data;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return LatLng(lat, lon);
        }
      }
    } on Exception catch (e) {
      throw Exception(e.toString());
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url =
        'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=13';
    final response = await _dio.get(url,
        options: Options(
          headers: {'User-Agent': 'com.example.flutter_map_integration/1.0.0'},
        ));
    if (response.statusCode == 200 && response.data.isNotEmpty) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    return [];
  }

  Future<List<LatLng>> getBestRoutePoints({
    required LatLng initialPosition,
    required LatLng destinationPosition,
    required String routeMode,
  }) async {
   final url =
    'https://router.project-osrm.org/route/v1/$routeMode/${initialPosition.longitude},${initialPosition.latitude};${destinationPosition.longitude},${destinationPosition.latitude}?overview=full&geometries=geojson&steps=true';


    try {
      final response = await _dio.get(url);
      final data = response.data;

      if (data['routes'] == null || data['routes'].isEmpty) return [];

      final coordinates = (data['routes'][0]['geometry']['coordinates'] as List)
          .cast<List<dynamic>>();


      return coordinates
          .map((coord) => LatLng(coord[1] as double, coord[0] as double))
          .toList();
    } catch (e) {
  
      return [];
    }
  }
}
