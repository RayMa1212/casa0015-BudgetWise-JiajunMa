import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:helios_rise/info/alarm_info.dart';

class AlarmInfoWidget extends StatelessWidget {
  final AlarmInfo alarmInfo;

  const AlarmInfoWidget({Key? key, required this.alarmInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // 允许内容滚动
      child: Card(
        elevation: 4,
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 使Column高度适应内容
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Destination: ${alarmInfo.destination}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildInfoRow('Time to Arrive:', alarmInfo.timeToArrive),
              _buildInfoRow('Travel Methods:', alarmInfo.travelMethods.join(', ')),
              _buildInfoRow('Wake Up Policy:', alarmInfo.wakeUpPolicy),
              _buildInfoRow('Allow Later Arrival:', alarmInfo.allowLaterThanSet ? "Yes" : "No"),
              _buildInfoRow('Washing Time:', '${alarmInfo.washingTime} minutes'),
              Divider(),
              _buildLocationInfo(alarmInfo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(AlarmInfo alarmInfo) {
    return Row(
      children: <Widget>[
        Icon(Icons.location_on, color: Colors.red),
        SizedBox(width: 8), // Add some space between icon and text
        Expanded(
          child: Text(
            'From: (${alarmInfo.currentPosition.latitude}, ${alarmInfo.currentPosition.longitude})\nTo: (${alarmInfo.destinationPosition.latitude}, ${alarmInfo.destinationPosition.longitude})',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
