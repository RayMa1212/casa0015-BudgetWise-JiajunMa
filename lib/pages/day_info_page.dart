import 'dart:core';
import 'package:flutter/material.dart';
import 'package:helios_rise/pages/add_alarm_page.dart';
import 'package:helios_rise/info/alarm_info.dart';
import 'package:helios_rise/pages/home_page.dart';
import 'package:helios_rise/services/firestore_service.dart';
import 'package:helios_rise/pages/edit_alarm_page.dart';

class DayInfoScreen extends StatefulWidget {
  final String day;

  DayInfoScreen({Key? key, required this.day}) : super(key: key);

  @override
  _DayInfoScreenState createState() => _DayInfoScreenState();
}

class _DayInfoScreenState extends State<DayInfoScreen> {
  List<AlarmInfo> _alarms =[];

  void _handleSwitchChange(AlarmInfo toggledAlarm, bool newValue, alarms) {
    setState(() {
      // Update the status of the toggled alarm clock
      toggledAlarm.status = newValue;
      // Set the status of all other alarms to false
      _alarms.where((alarm) => alarm.id != toggledAlarm.id).forEach((alarm) {
        alarm.status = false;
      });
    });

    // Call the Firestore service to update the database
    FirestoreService().updateAlarm(toggledAlarm, newValue, widget.day);
  }

  Future<void> _fetchAndStoreAlarms() async {
    List<AlarmInfo> fetchedAlarms = await FirestoreService().fetchAlarms(widget.day);
    setState(() {
      _alarms = fetchedAlarms;
    });
  }

  void _deleteItem(day, index) {
    FirestoreService().deleteAlarmFromFirestore(index, day);
    setState(() {
      _alarms.removeWhere((alarm) => alarm.id == index); // Delete elements at a specific index
    });
  }


  @override
  void initState() {
    super.initState();
    _fetchAndStoreAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('${widget.day} Clocks'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {

              Navigator.pop(context, true);
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddAlarmScreen(day: widget.day)),
                );
              },
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: _alarms.length,
          itemBuilder: (context, index) {
            final alarm = _alarms[index];
            return Dismissible(
              key: Key(alarm.id),
              onDismissed: (direction) {
                _deleteItem(widget.day, alarm.id);
                // Show a Snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Clock dismissed')),
                );
              },
              background: Container(color: Colors.red),
              child: ListTile(
                title: Text(alarm.destination),
                subtitle: Text('Arrive by: ${alarm.timeToArrive}, Washing Time: ${alarm.washingTime} minutes'),
                trailing: Switch(
                  key: Key(alarm.id),
                  value: alarm.status,
                  onChanged: (bool newValue) {
                    _handleSwitchChange(alarm, newValue, _alarms);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditAlarmPage(alarm: alarm, day: widget.day),
                    ),
                  ).then((_) => _fetchAndStoreAlarms()); // Refresh alarms after editing
                },
              ),
            );
          },
        )

    );
  }
}
