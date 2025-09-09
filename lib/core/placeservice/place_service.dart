import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../w/url_constant.dart';

class PlaceService {

final _dio=Dio();
  Future<LatLng?> destinationCalculator({required String destination}) async
{
  try {
  final encodedName=Uri.encodeComponent(destination.trim());
  final response= await _dio.get(
    '$baseOpenStreetMapUrl/search?q=$encodedName&format=json&limit=1',
    options: Options(
      headers: {
        'User-Agent':'com.example.flutter_map_integration/1.0.0'
      }
    )
  );
  if(response.statusCode==200)
  {
    final List data=response.data;
    if(data.isNotEmpty)
   {   final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        return LatLng(lat, lon);
        }
  }
} on Exception catch (e) {
  print('error Fetching Coordinates:${e.toString()}');

}
return null;

}
  Future<List<String>> searchPlaces(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = '$baseOpenStreetMapUrl/search?q=$encodedQuery&format=json&limit=5';
    final response = await _dio.get(url, options: Options(
      headers: {
        'User-Agent':'com.example.flutter_map_integration/1.0.0'
      }
    ));
    if (response.statusCode == 200 && response.data.isNotEmpty) {
      return (response.data as List).map((e) => e['display_name'] as String).toList();
    }
    return [];
  }
}

