import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:helios_rise/info/alarm_info.dart';
import 'package:http/http.dart' as http;

class TravelService {
  FirebaseFirestore db = FirebaseFirestore.instance;
  final String apiKey = 'AIzaSyCX9ex1CusxAHeDGsEAvBWZ6AQUE9yrAFU';


  Future<Map<String, dynamic>> getTravelTimes(AlarmInfo uniqueEntry) async {

    var origin = LatLng(uniqueEntry.currentPosition.latitude, uniqueEntry.currentPosition.longitude);
    var destination = LatLng(uniqueEntry.destinationPosition.latitude, uniqueEntry.destinationPosition.longitude);

    var travelMethods = uniqueEntry.travelMethods;
    var priorities = {for (var i = 0; i < travelMethods.length; i++) travelMethods[i]: i};

    Map<String, dynamic> results = {};
    for (var method in travelMethods) {
      var directionsResult = await http.get(Uri.parse('https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$method&key=$apiKey'));
      var data = json.decode(directionsResult.body);
      var durationSeconds = data['routes'][0]['legs'][0]['duration']['value'];
      var durationMinutes = durationSeconds / 60.0;
      results[method] = {
        'duration': durationMinutes.toInt(),
        'priority': priorities[method],
      };
    }

    var sortedResults = Map.fromEntries(results.entries.toList()..sort((a, b) => a.value['priority'].compareTo(b.value['priority'])));

    return sortedResults;
  }
}
