import 'dart:core';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AlarmInfo {
  String destination;
  List<String> travelMethods;
  String wakeUpPolicy;
  bool allowLaterThanSet;
  String timeToArrive;
  LatLng currentPosition;
  LatLng destinationPosition;
  int washingTime;
  bool status;
  String id;

  AlarmInfo({
    required this.destination,
    required this.travelMethods,
    required this.wakeUpPolicy,
    required this.allowLaterThanSet,
    required this.timeToArrive,
    required this.currentPosition,
    required this.destinationPosition,
    required this.washingTime,
    required this.status,
    required this.id,
  });

  factory AlarmInfo.fromMap(Map<String, dynamic> map, String id) {
    return AlarmInfo(
      id: id, // 设置文档ID
      destination: map['destination'],
      travelMethods: List<String>.from(map['travelMethod']),
      wakeUpPolicy: map['wakeUpPolicy'],
      allowLaterThanSet: map['allowLaterThanSet'],
      timeToArrive: map['timeToArrive'],
      currentPosition: LatLng(map['currentPosition']['latitude'], map['currentPosition']['longitude']),
      destinationPosition: LatLng(map['destinationPosition']['latitude'], map['destinationPosition']['longitude']),
      washingTime: map['washingTime'],
      status: map['status'],
    );
  }
}
