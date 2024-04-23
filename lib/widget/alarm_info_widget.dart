import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:helios_rise/info/alarm_info.dart';
import 'package:intl/intl.dart';

class AlarmInfoWidget extends StatefulWidget {
  final AlarmInfo alarmInfo;
  final Map<String, dynamic> travelTimes;

  const AlarmInfoWidget({
    Key? key,
    required this.alarmInfo,
    required this.travelTimes
  }) : super(key: key);

  @override
  _AlarmInfoWidgetState createState() => _AlarmInfoWidgetState();
}

class _AlarmInfoWidgetState extends State<AlarmInfoWidget> {
  String? adjustedAlarmTime;

  @override
  void initState() {
    super.initState();
    calculateAdjustedAlarmTime();
  }

  void calculateAdjustedAlarmTime() {
    DateTime timeToArrive = DateFormat('HH:mm').parse(widget.alarmInfo.timeToArrive);
    int washingTime = widget.alarmInfo.washingTime;
    int? travelTimeForPriorityZero = widget.travelTimes.entries
        .where((entry) => entry.value['priority'] == 0)
        .map((entry) => entry.value['duration'])
        .first;

    DateTime adjustedTime = timeToArrive.subtract(Duration(minutes: travelTimeForPriorityZero! + washingTime));
    setState(() {
      adjustedAlarmTime = DateFormat('HH:mm').format(adjustedTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Destination: ${widget.alarmInfo.destination}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Adjusted Wake Up Time: ${adjustedAlarmTime ?? "Calculating..."}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildInfoRow('Time to Arrive:', widget.alarmInfo.timeToArrive),
              _buildInfoRow('Preferred Travel Methods:', widget.alarmInfo.travelMethods[0]),
              _buildInfoRow('Wake Up Policy:', widget.alarmInfo.wakeUpPolicy),
              _buildInfoRow('Washing Time:', '${widget.alarmInfo.washingTime} minutes'),
              Divider(),
              _buildLocationInfo(widget.alarmInfo),
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
        SizedBox(width: 8),
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
