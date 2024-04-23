import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:helios_rise/info/alarm_info.dart';
import 'package:helios_rise/services/firestore_service.dart';
import 'package:helios_rise/pages/day_info_page.dart';
import 'package:helios_rise/services/location_service.dart';
import 'package:http/http.dart' as http;
import 'dart:core';

class EditAlarmPage extends StatefulWidget {
  final AlarmInfo alarm;
  final String day;

  EditAlarmPage({Key? key, required this.alarm, required this.day}) : super(key: key);

  @override
  _EditAlarmPageState createState() => _EditAlarmPageState();
}

class _EditAlarmPageState extends State<EditAlarmPage> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _currentPositionLatController = TextEditingController();
  final TextEditingController _currentPositionLngController = TextEditingController();
  final TextEditingController _arrivalTimeController = TextEditingController();
  List<String> _selectedTravelMethods = [];
  String? _wakeUpPolicy;
  bool _status = false;
  TimeOfDay? _arrivalTime;
  String? _arrivalTimeString;
  int _washingTime = 0;

  final _travelMethods = ['walking', 'driving', 'bicycling', 'transit'];
  final _wakeUpPolicies = ['Adaptive', 'Fixed'];
  // String? _wakeUpPolicy;
  bool allow_later_than_set = false;
  // TimeOfDay? _arrivalTime;
  // int _washingTime = 0;
  LatLng? destinationLatLng;
  int estimatedTime = 0;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _destinationController.text = widget.alarm.destination;
    _currentPositionLatController.text = widget.alarm.currentPosition.latitude.toString();
    _currentPositionLngController.text = widget.alarm.currentPosition.longitude.toString();
    _arrivalTimeController.text = widget.alarm.timeToArrive;
    _selectedTravelMethods = List.from(widget.alarm.travelMethods);
    _wakeUpPolicy = widget.alarm.wakeUpPolicy;
    _status = widget.alarm.status;
    _washingTime = widget.alarm.washingTime;
    _arrivalTimeString = widget.alarm.timeToArrive;

    _destinationController.addListener(() {
      _onSearchChanged(_destinationController.text);
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _currentPositionLatController.dispose();
    _currentPositionLngController.dispose();
    _arrivalTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _arrivalTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _arrivalTime) {
      setState(() {
        _arrivalTime = picked;
        _arrivalTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _saveAlarm() async {
    try {
      AlarmInfo updatedAlarm = widget.alarm.copyWith(
        destination: _destinationController.text,
        destinationPosition:  await LocationService().findPlace(_destinationController.text),
        travelMethods:  _travelMethods,
        wakeUpPolicy: _wakeUpPolicy!,
        timeToArrive: _arrivalTimeController.text,
        washingTime: _washingTime,
        status: widget.alarm.status,  // Preserve the existing status
      );

      await _firestoreService.updateAlarmInfo(updatedAlarm, widget.day);
      Navigator.pop(context); // Return to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating alarm: $e')));
    }
  }

  List<dynamic> _suggestions = [];

  Future<void> _onSearchChanged(String value) async {
    const String apiKey = 'AIzaSyCX9ex1CusxAHeDGsEAvBWZ6AQUE9yrAFU';
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$value&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          setState(() {
            _suggestions = result['predictions'];
          });
        }
      } else {
        // 错误处理
        print('Failed to fetch suggestions');
      }
    } catch (e) {
      // 错误处理
      print(e.toString());
    }
  }

  Widget _buildSuggestions() {
    // 判断是否有建议并显示，这里简化处理为直接返回一个Container
    // 实际应用中，你可能需要一个更复杂的ListView或者其他布局方式来展示建议
    return Container(
      height: 100.0, // 指定一个高度
      child: ListView.builder(
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            title: Text(suggestion['description']),
            onTap: () {
              _destinationController.text = suggestion['description'];
              setState(() {
                _suggestions = [];
              });
            },
          );
        },
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = _travelMethods.removeAt(oldIndex);
      _travelMethods.insert(newIndex, item);
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Alarm for ${widget.day}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // 在这里执行返回操作
            // 通常是调用 Navigator.pop(context)
            Navigator.pop(context);
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.nights_stay, size: 100, color: Colors.blue),
              Text(
                'Good Evening!',
                style: TextStyle(fontSize: 24),
              ),


              SizedBox(height: 16),


              TextFormField(
                controller: _destinationController, // 关联 TextEditingController
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(),
                ),
              ),

              _buildSuggestions(),




              SizedBox(height: 8),
              const Divider(height: 0),
              SizedBox(height: 8),


              Text('Travel Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _travelMethods.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    key: ValueKey(_travelMethods[index]),
                    title: Text(_travelMethods[index]),
                    leading: Icon(Icons.menu),
                    tileColor: index % 2 == 0 ? Colors.grey[200] : null, // Optional: Zebra striping
                  );
                },
                onReorder: _onReorder,
              ),


              SizedBox(height: 8),
              const Divider(height: 0),
              SizedBox(height: 8),


              const Text('Wake Up Policy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              DropdownButtonFormField(
                value: _wakeUpPolicy,
                onChanged: (String? newValue) {
                  setState(() {
                    _wakeUpPolicy = newValue!;
                  });
                },
                items: _wakeUpPolicies
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Wake-Up Policy',
                  border: OutlineInputBorder(),
                ),
              ),


              SizedBox(height: 8),
              const Divider(height: 0),
              SizedBox(height: 8),

              const Text('Time Infomation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

              SizedBox(height: 8),


              GestureDetector(
                onTap: _pickTime,
                child: AbsorbPointer(
                  child: TextField(
                    controller: TextEditingController(text: _arrivalTimeString),
                    decoration: InputDecoration(
                      labelText: 'Time to Arrive',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),


              SizedBox(height: 8),


              TextField(
                controller: TextEditingController(text: _washingTime.toString()),  // Display washing time
                decoration: InputDecoration(
                  labelText: 'Washing Time (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _washingTime = int.tryParse(value) ?? 0;
                },
              ),


              SizedBox(height: 16),

              ElevatedButton(
                onPressed: _saveAlarm,

                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
