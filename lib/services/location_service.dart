// location_service.dart
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  final Location _location = Location();

  Future<LatLng?> getCurrentLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    try {
      print("xxxx");
      final LocationData _currentLocation = await _location.getLocation();
      print("Current position: $_currentLocation");
      return LatLng(_currentLocation.latitude!, _currentLocation.longitude!);
    } catch (e) {
      // 处理获取位置失败的情况
      return null;
    }
  }

  Marker createLocationMarker(LatLng position, {String markerId = 'current_location'}) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: "Current Location",
        snippet: "This is your current location.",
      ),
      icon: BitmapDescriptor.defaultMarker,
    );
  }

  Future<LatLng?> findPlace(String placeName) async {
    final String apiKey = 'AIzaSyCX9ex1CusxAHeDGsEAvBWZ6AQUE9yrAFU';
    final String url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$placeName&inputtype=textquery&fields=geometry&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['candidates'].isNotEmpty) {
          final location = result['candidates'][0]['geometry']['location'];
          final LatLng placeLocation = LatLng(location['lat'], location['lng']);
          print("Location: ${placeLocation.latitude}, ${placeLocation.longitude}");
          return placeLocation;
        } else {
          print('No results found.');
          return null;
        }
      } else {
        print('Failed to find place.');
        return null;
      }
    } catch (e) {
      print('Exception caught: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getRouteData(LatLng start, LatLng destination) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${destination.latitude},${destination.longitude}&key=AIzaSyCX9ex1CusxAHeDGsEAvBWZ6AQUE9yrAFU';
    // print(url);
    final http.Response response = await http.get(Uri.parse(url));
    // print('Status code: ${response.statusCode}');
    // print('Headers: ${response.headers}');
    // print('Body: ${response.body}');
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data;
  }

  Future<Map<String, dynamic>> getRouteDataWithMode(LatLng start, LatLng destination, mode) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$mode&key=AIzaSyCX9ex1CusxAHeDGsEAvBWZ6AQUE9yrAFU';
    // print(url);
    final http.Response response = await http.get(Uri.parse(url));
    // print('Status code: ${response.statusCode}');
    // print('Headers: ${response.headers}');
    // print('Body: ${response.body}');
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data;
  }


  Future<int> getTravelTime(Map<String, dynamic> data) async {
    if (data['status'] == 'OK') {
      // 获取预计旅行时间（秒）
      final int durationInSeconds = data['routes'][0]['legs'][0]['duration']['value'];
      print("get travel time successfully!");
      return durationInSeconds;
    } else {
      throw Exception('Failed to load directions');
    }
  }


  Future<String> getRouteCoordinates(Map<String, dynamic> data) async {
    if (data['status'] == 'OK') {
      final String encodedPath = data['routes'][0]['overview_polyline']['points'] as String;
      return encodedPath;
    } else {
      print('Failed to fetch route');
      throw Exception('Failed to fetch route');
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      LatLng p = LatLng(lat / 1E5, lng / 1E5);
      points.add(p);
    }
    return points;
  }







}
