import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:helios_rise/services/firestore_service.dart';
import 'package:helios_rise/services/location_service.dart';
import 'package:helios_rise/pages/day_info_page.dart';
import 'package:http/http.dart' as http;


class AddAlarmScreen extends StatefulWidget {
  final String day;

  AddAlarmScreen({Key? key, required this.day}) : super(key: key);

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}


class _AddAlarmScreenState extends State<AddAlarmScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final _travelMethods = ['walking', 'driving', 'bicycling', 'transit'];
  final _wakeUpPolicies = ['Adaptive', 'Fixed'];
  String? _wakeUpPolicy;
  // bool allow_later_than_set = false;
  TimeOfDay? _arrivalTime;
  int _washingTime = 0;
  LatLng? destinationLatLng;
  int estimatedTime = 0;
  final FirestoreService _firestoreService = FirestoreService();


  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = _travelMethods.removeAt(oldIndex);
      _travelMethods.insert(newIndex, item);
    });
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

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _arrivalTime) {
      setState(() {
        _arrivalTime = picked;
      });
    }
  }

  // Future<List<LatLng>?> getRouteCoordinates() async {
  //   final LatLng? currentPosition = await LocationService().getCurrentLocation();
  //   List<Map<String, dynamic>> documentData = await FirestoreService().fetchData();
  //   String destination = documentData[0]["destination"];
  //   if (currentPosition != null && destination.isNotEmpty) {
  //     try {
  //       destinationLatLng = await LocationService().findPlace(destination);
  //       final LatLng safeDestinationLatLng = destinationLatLng!; // 使用 ! 断言非空，并赋值给本地变量
  //       if (safeDestinationLatLng != null) {
  //         Map<String, dynamic> data = await LocationService().getRouteData(currentPosition, safeDestinationLatLng);
  //         String encodedPath = await LocationService().getRouteCoordinates(data);
  //         estimatedTime = await LocationService().getTravelTime(data);
  //         List<LatLng> points = LocationService().decodePolyline(encodedPath);
  //         return points; // 返回路线点的列表
  //       }
  //     } catch (e) {
  //       // 处理异常，给用户适当的反馈
  //       print('Error fetching route: $e');
  //     }
  //   }
  //   return null; // 在无法获取路线数据的情况下返回 null
  // }

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


  @override
  void initState() {
    super.initState();
    _destinationController.addListener(() {
      _onSearchChanged(_destinationController.text);
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
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
              // CheckboxListTile(
              //   value: allow_later_than_set,
              //   onChanged: (bool? value) {
              //     setState(() {
              //       allow_later_than_set= value!;
              //     });
              //   },
              //   title: const Text('Allow later than set'),
              // ),


              SizedBox(height: 8),
              const Divider(height: 0),
              SizedBox(height: 8),

              ElevatedButton(
                onPressed: _pickTime,
                child: Text(_arrivalTime == null ? 'Select Time to Arrive' : 'Time: ${_arrivalTime!.format(context)}'),
              ),

              // 添加一个按钮或输入字段以设置洗漱时间
              SizedBox(height: 8),


              TextField(
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

              // Column(
              //   children: [
              //     // 按钮，用于显示和选择重复天数
              //     ListTile(
              //       title: Text('Repeat'),
              //       subtitle: Text(getSelectedDaysText()), // 显示选中的天数
              //       trailing: IconButton(
              //         icon: Icon(Icons.edit),
              //         onPressed: _showRepeatDaysSelection,
              //       ),
              //     ),
              //   ],
              // ),


              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  String _destination = _destinationController.text;
                  if (_destination.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Destination is required')),
                    );
                    return;
                  }
                  if (_wakeUpPolicy == null || _wakeUpPolicy!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a wake-up policy')),
                    );
                    return;
                  }
                  if (_arrivalTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a time to arrive')),
                    );
                    return;
                  }
                  if (_washingTime == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a time to wash')),
                    );
                    return;
                  }

                  final LatLng? currentPosition = await LocationService().getCurrentLocation();
                  print("position:");
                  print(currentPosition);
                  if (currentPosition == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unable to fetch current position')),
                    );
                    return;
                  }

                  // List<Map<String, dynamic>> documentData = await FirestoreService().fetchData();
                  final LatLng? destinationPosition = await LocationService().findPlace(_destination);
                  print("position:");
                  print(destinationPosition);
                  if (destinationPosition == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unable to fetch destination position')),
                    );
                    return;
                  }
                  try {
                    await _firestoreService.submitEveningData(
                      destination: _destinationController.text,
                      travelMethods: _travelMethods,
                      wakeUpPolicy: _wakeUpPolicy ?? '',
                      // allowLaterThanSet: allow_later_than_set,
                      timeToArrive: _arrivalTime?.format(context) ?? '',
                      currentPosition: currentPosition,
                      destinationPosition: destinationPosition,
                      washingTime: _washingTime,
                      dayOfWeek: widget.day,
                      status: false,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Data submitted to Firebase')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error submitting data: $e')),
                    );
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DayInfoScreen(day: widget.day)),
                  );
                  // MyHomePageState().showRoute();
                },

                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }



}