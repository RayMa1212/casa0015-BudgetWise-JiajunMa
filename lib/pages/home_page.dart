import 'dart:async';
import 'dart:core';

// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:helios_rise/pages/feedback_page.dart';
import 'package:helios_rise/services/firestore_service.dart';
import 'package:helios_rise/services/location_service.dart';
import 'package:helios_rise/pages/day_info_page.dart';
import 'package:helios_rise/info/alarm_info.dart';
import 'package:helios_rise/services/notification_service.dart';
import 'package:helios_rise/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:helios_rise/services/weather_service.dart';
import 'package:helios_rise/widget/alarm_info_widget.dart';
import 'package:helios_rise/widget/add_alarm_widget.dart';
import 'package:helios_rise/services/firebase_auth_service.dart';
import 'package:helios_rise/services/clock_service.dart';
import 'dart:math';

import 'package:helios_rise/services/clock_service.dart';
import '../services/posture_service.dart';
import '../services/travel_service.dart';
import 'edit_profile_page.dart';

enum DisplaySelection {morning, evening, map, user }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DisplaySelection _selection = DisplaySelection.evening;
  List<String> daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  AlarmInfo? nextAlarmInfo;

  void _setMorning() {
    setState(() {
      _selection = DisplaySelection.morning;
    });
  }


  void _setEvening() {
    setState(() {
      _selection = DisplaySelection.evening;
    });
  }

  void _setMap() {
    setState(() {
      _selection = DisplaySelection.map;
    });
  }

  void _setUser() {
    setState(() {
      _selection = DisplaySelection.user;
    });
  }

  Set<Marker> _markers = {};
  LatLng? destinationLatLng;
  late GoogleMapController _mapController;
  int estimatedTime = 0;

  void addDestinationMarker(int estimatedTime) async {
    if (destinationLatLng != null) {
      final LatLng safeDestinationLatLng = destinationLatLng!; // 使用 ! 断言非空，并赋值给本地变量
      print ("safeDestinationLatLng: $safeDestinationLatLng");
      final Marker destinationLocationMarker = Marker(
        markerId: MarkerId("destination_marker"),
        position: safeDestinationLatLng, // 使用本地变量
        infoWindow: InfoWindow(
          title: "Destination",
          snippet: "Estimated travel time: $estimatedTime",

        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
      setState(() {
        _markers.add(destinationLocationMarker);
      });
    }
  }

  static final CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(51.5, 0.13),
    zoom: 12,
  );

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {});
    showRoute();
  }

  Set<Polyline> _polylines = {};

  Future<void> _fitRoute(_mapController) async {
    if (_mapController == null || _markers.isEmpty || _polylines.isEmpty) return;

    var minLat = _markers.first.position.latitude;
    var maxLat = _markers.first.position.latitude;
    var minLng = _markers.first.position.longitude;
    var maxLng = _markers.first.position.longitude;

    for (var marker in _markers) {
      minLat = min(minLat, marker.position.latitude);
      maxLat = max(maxLat, marker.position.latitude);
      minLng = min(minLng, marker.position.longitude);
      maxLng = max(maxLng, marker.position.longitude);
    }

    for (var polyline in _polylines) {
      for (var point in polyline.points) {
        minLat = min(minLat, point.latitude);
        maxLat = max(maxLat, point.latitude);
        minLng = min(minLng, point.longitude);
        maxLng = max(maxLng, point.longitude);
      }
    }

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    final CameraUpdate update = CameraUpdate.newLatLngBounds(bounds, 100);
    await _mapController.animateCamera(update);
    print("Fit the route successfully!");
  }


  Future<void> showRoute() async {
    if (nextAlarmInfo == null) {
      print("Next alarm info not loaded yet.");
      return;
    }
    List<LatLng>? points = await getRouteCoordinates(nextAlarmInfo);
    await getRouteCoordinatesWithMode(nextAlarmInfo, 'trasit');
    if (points != null && points.isNotEmpty) {
      final PolylineId routePolylineId = PolylineId('route');
      setState(() {
        _polylines.clear(); // 清除旧的路线
        _polylines.add(Polyline(
          polylineId: routePolylineId,
          width: 5,
          color: Colors.blue,
          points: points,
        ));
        addDestinationMarker(estimatedTime);
      });
      await _fitRoute(_mapController);
    } else {
      print("Unable to fetch route coordinates.");
    }
  }


  Future<List<LatLng>?> getRouteCoordinatesWithMode(nextAlarmInfo, mode) async {
    final LatLng? currentPosition = await LocationService().getCurrentLocation();
    // List<Map<String, dynamic>> documentData = await FirestoreService().fetchNextActiveAlarm();
    String destination = nextAlarmInfo.destination;
    if (currentPosition != null && destination.isNotEmpty) {
      try {
        destinationLatLng = await LocationService().findPlace(destination);
        final LatLng safeDestinationLatLng = destinationLatLng!; // 使用 ! 断言非空，并赋值给本地变量
        if (safeDestinationLatLng != null) {
          Map<String, dynamic> data = await LocationService().getRouteDataWithMode(currentPosition, safeDestinationLatLng, mode);
          printRouteDetails(data);
        }
      } catch (e) {
        // 处理异常，给用户适当的反馈
        print('Error fetching route: $e');
      }
    }
    return null; // 在无法获取路线数据的情况下返回 null
  }

  void printRouteDetails(Map<String, dynamic> data) {
    if (data['status'] == 'OK') {
      var routes = data['routes'];
      if (routes.isNotEmpty) {
        var route = routes[0];
        var leg = route['legs'][0];
        var distance = leg['distance']['text'];
        var duration = leg['duration']['text'];
        var startAddress = leg['start_address'];
        var endAddress = leg['end_address'];

        print('Route from $startAddress to $endAddress');
        print('Distance: $distance');
        print('Duration: $duration');

        // Optionally, print step-by-step instructions
        print('Steps:');
        var steps = leg['steps'];
        for (var step in steps) {
          var htmlInstructions = step['html_instructions'].replaceAll(RegExp(r'<[^>]*>'), '');
          var stepDistance = step['distance']['text'];
          print('$htmlInstructions ($stepDistance)');
        }
      } else {
        print('No routes available.');
      }
    } else {
      print('Error fetching route: ${data['status']}');
    }
  }





  Future<List<LatLng>?> getRouteCoordinates(nextAlarmInfo) async {
    final LatLng? currentPosition = await LocationService().getCurrentLocation();
    // List<Map<String, dynamic>> documentData = await FirestoreService().fetchNextActiveAlarm();
    String destination = nextAlarmInfo.destination;
    if (currentPosition != null && destination.isNotEmpty) {
      try {
        destinationLatLng = await LocationService().findPlace(destination);
        final LatLng safeDestinationLatLng = destinationLatLng!; // 使用 ! 断言非空，并赋值给本地变量
        if (safeDestinationLatLng != null) {
          Map<String, dynamic> data = await LocationService().getRouteData(currentPosition, safeDestinationLatLng);
          String encodedPath = await LocationService().getRouteCoordinates(data);
          estimatedTime = await LocationService().getTravelTime(data);
          List<LatLng> points = LocationService().decodePolyline(encodedPath);
          return points; // 返回路线点的列表
        }
      } catch (e) {
        // 处理异常，给用户适当的反馈
        print('Error fetching route: $e');
      }
    }
    return null; // 在无法获取路线数据的情况下返回 null
  }


  Map<String, AlarmInfo> activeAlarmsByDay = {};

  Future<void> _fetchActiveAlarms() async {
    Map<String, AlarmInfo> fetchedAlarms = await FirestoreService().fetchActiveAlarmsByDay();
    setState(() {
      activeAlarmsByDay = fetchedAlarms; // 更新本地列表
    });
  }

  Future<void> navigateAndRefresh(day) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DayInfoScreen(day: day)),
    );

    // 检查从 DetailsPage 返回的结果
    if (result == true) {
      // 刷新 MainPage 的数据
      _fetchActiveAlarms();
    }
  }

  Future<void> _fetchNextActiveAlarm() async {
    try {
      nextAlarmInfo = await FirestoreService().fetchNextActiveAlarm();
      if (mounted) setState(() {});
    } catch (e) {
      print('Failed to fetch next active alarm: $e');
    }
  }

  String? userId = FirebaseAuth.instance.currentUser?.uid;
  CollectionReference user_info = FirebaseFirestore.instance.collection('user_info');

  final CloudService _cloudService = CloudService();
  final WeatherService _weatherService = WeatherService();
  late Future<Map<String, dynamic>> travelTimes;
  final TravelService _travelService = TravelService();

  void printTravelTimes() async {
    try {
      Map<String, dynamic> travelTimes = await _travelService.getTravelTimes(nextAlarmInfo!);
      travelTimes.forEach((key, value) {
        print('$key travel time: ${value['duration']} minutes');
      });
    } catch (e) {
      print('Error getting travel times: $e');
    }
  }

  Future<void> _fetchTravelTime() async {
    try {
      nextAlarmInfo = await FirestoreService().fetchNextActiveAlarm();
      if (nextAlarmInfo != null && mounted) {
        setState(() {
          travelTimes = _travelService.getTravelTimes(nextAlarmInfo!);
          printTravelTimes();
        });
      } else {
        print("nextAlarmInfo is null");
      }
    } catch (e) {
      print('Failed to fetch next active alarm: $e');
    }
  }

  // late Future<Map<String, dynamic>?> routeFuture;

  // Future<Map<String, dynamic>?> getRouteCoordinatesWithMode2(AlarmInfo nextAlarmInfo, String mode) async {
  //   final LatLng? currentPosition = await LocationService().getCurrentLocation();
  //   String destination = nextAlarmInfo.destination;
  //
  //   if (currentPosition == null || destination.isEmpty) {
  //     print("Current position or destination is not available.");
  //     return null; // 提前返回，避免深层嵌套
  //   }
  //
  //   try {
  //     LatLng? destinationLatLng = await LocationService().findPlace(destination);
  //     if (destinationLatLng == null) {
  //       print("Destination not found.");
  //       return null;
  //     }
  //
  //     Map<String, dynamic> data = await LocationService().getRouteDataWithMode(currentPosition, destinationLatLng, mode);
  //     if (data.isEmpty) {
  //       print("No route data available.");
  //       return null;
  //     }
  //     return data;
  //   } catch (e) {
  //     print('Error fetching route data: $e');
  //     return null; // 在捕获异常时返回null
  //   }
  // }


  @override
  void initState() {
    super.initState();
    // Initialize with an empty map to avoid initial null error before pressing the button
    _fetchNextActiveAlarm();
    _fetchActiveAlarms();
    _cloudService.startPolling();
    _weatherService.startPolling();
    _fetchTravelTime();
    // routeFuture = getRouteCoordinatesWithMode2(nextAlarmInfo!, 'transit');
  }



  @override
  void dispose() {
    _cloudService.stopPolling();
    _cloudService.dispose();
    _weatherService.stopPolling();
    _weatherService.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_selection) {
      case DisplaySelection.evening:
        bodyContent = ListView.builder(
          itemCount: daysOfWeek.length,
          itemBuilder: (BuildContext context, int index) {
            // 获取当前天的名称
            String day = daysOfWeek[index];
            // 尝试从activeAlarmsByDay中获取当前天的闹钟
            AlarmInfo? alarmOfTheDay = activeAlarmsByDay[day];

            // 基于获取到的闹钟信息构造一个描述性的副标题
            String subtitleText = "No alarm set";
            if (alarmOfTheDay != null) {
              subtitleText = 'Destination: ${alarmOfTheDay.destination}, Arrive by: ${alarmOfTheDay.timeToArrive}, Washing Time: ${alarmOfTheDay.washingTime} minutes';
            }

            return Card(
              elevation: 2, // Add a little shadow to each card
              child: ListTile(
                title: Text(
                  day,
                  style: TextStyle(
                    fontSize: 24, // Adjusted for readability
                  ),
                ),
                // 在这里添加副标题以显示闹钟的详细信息
                subtitle: Text(
                  subtitleText, // 显示的文本根据上面的逻辑确定
                  style: TextStyle(
                    fontSize: 16, // Adjust the font size if necessary
                  ),
                ),
                onTap: () {
                  navigateAndRefresh(day);
                },
              ),
            );
          },
        );

        break;
      case DisplaySelection.morning:
        String alarmDetails = nextAlarmInfo != null
            ? 'Next Alarm at ${nextAlarmInfo!.timeToArrive}'
            : 'No upcoming alarms set';

        bodyContent = Column(
          children: [
            SizedBox(height: 16),
            Icon(Icons.wb_sunny, size: 100, color: Colors.orange),
            Text(
              'Good Morning!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 16),
            Expanded(
              child: PageView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: nextAlarmInfo != null
                        ? FutureBuilder<Map<String, dynamic>>(
                      future: _travelService.getTravelTimes(nextAlarmInfo!),  // 获取旅行时间
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasData) {
                            Map<String, dynamic> travelTimes = snapshot.data!;
                            return AlarmInfoWidget(
                              alarmInfo: nextAlarmInfo!,
                              travelTimes: travelTimes,
                            );
                          } else if (snapshot.hasError) {
                            return Text('Error fetching travel times: ${snapshot.error}');
                          }
                        }
                        return CircularProgressIndicator();  // 加载中显示进度指示器
                      },
                    )
                        : Center(child: Text("No upcoming alarms.", style: TextStyle(fontSize: 18))),
                  )

                ],
              ),
            ),
          ],
        );
        break;
      case DisplaySelection.map:
        bodyContent = GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: initialCameraPosition,
                    myLocationEnabled: true, // 显示当前位置
                    myLocationButtonEnabled: true, // 显示移动到当前位置的按钮
                    markers: _markers,
                    polylines: _polylines,
                    padding: EdgeInsets.only(top: 0, right: 0, bottom: 0, left: 0),
                  );


                // ElevatedButton(
                //   onPressed: (){
                //     stopSound();
                //   },
                //   child: Text('Stop Alarm')
                // ),
                // ElevatedButton(
                //   onPressed: setOneShotAlarm,
                //   child: Text('Set One Shot Alarm'),
                // ),
                // FutureBuilder<Map<String, dynamic>?>(
                //   future: routeFuture,
                //   builder: (context, snapshot) {
                //     if (snapshot.connectionState == ConnectionState.done) {
                //       if (snapshot.hasData && snapshot.data != null) {
                //         return SingleChildScrollView(
                //           child: Padding(
                //             padding: EdgeInsets.all(16.0),
                //             child: Column(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: <Widget>[
                //                 Text("Distance: ${snapshot.data!['routes'][0]['legs'][0]['distance']['text']}", style: TextStyle(fontSize: 18)),
                //                 Text("Duration: ${snapshot.data!['routes'][0]['legs'][0]['duration']['text']}", style: TextStyle(fontSize: 18)),
                //                 // 可以添加更多细节
                //               ],
                //             ),
                //           ),
                //         );
                //       } else if (snapshot.hasError) {
                //         return Text("Error: ${snapshot.error}");
                //       }
                //     }
                //     return Center(child: CircularProgressIndicator());
                //   },
                // ),


        break;
      case DisplaySelection.user:
        if (userId == null) {
          // User is not logged in
          bodyContent = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No user is currently signed in.', style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  ),
                  child: Text('Go to Login Page'),
                ),
              ],
            ),
          );
        } else {
          // User is logged in, show user info
          bodyContent = FutureBuilder<DocumentSnapshot>(
            future: user_info.doc(userId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Something went wrong: ${snapshot.error}"));
              }
              if (snapshot.hasData && snapshot.data!.exists) {
                Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                return ListView(
                  padding: EdgeInsets.all(16.0),
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(
                        data['avatar_url'] ?? 'https://via.placeholder.com/150',
                      ),
                    ),
                    Divider(height: 20, thickness: 2),
                    ListTile(
                      title: Text('Name'),
                      subtitle: Text(data['full_name']),
                      trailing: Icon(Icons.edit),
                      onTap: () {
                        // Handle edit name
                      },
                    ),
                    ListTile(
                      title: Text('Email'),
                      subtitle: Text(data['email']),
                      trailing: Icon(Icons.edit),
                      onTap: () {
                        // Handle edit name
                      },
                    ),
                    ListTile(
                      title: Text('Tell Us About Yourself'),
                      subtitle: Text(data['bio'] ?? 'Not provided'), // Add 'bio' field to your Firestore
                      trailing: Icon(Icons.edit),
                      onTap: () {
                        // Handle edit name
                      },
                    ),
                    // ElevatedButton(
                    //   onPressed: () {
                    //     Navigator.of(context).pushReplacement(
                    //       MaterialPageRoute(builder: (context) => EditProfilePage()),
                    //     );
                    //   },
                    //   child: const Text('Edit'),
                    // ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => FeedbackPage()),
                        );
                      },
                      child: const Text('Feedback'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Authservice().signOut(context);
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                );
              }
              return Center(child: Text("User not found"));
            },
          );
          break;
        }
    }

    Color selectedColor = Theme.of(context).colorScheme.primary;
    Color unselectedColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          StreamBuilder<Map>(
            stream: _weatherService.controller.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var temperature = snapshot.data!['current']['temp'].toString();
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$temperature°C",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return Text(
                  "Failed to get data",
                  style: TextStyle(color: Colors.red, fontSize: 24),
                );
              }
              return CircularProgressIndicator(); // 加载中
            },
          ),


          StreamBuilder<Map>(
            stream: _weatherService.controller.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var weather = snapshot.data!['current']['weather'][0]['main'].toString();
                IconData iconData = Icons.sunny;
                switch (weather) {
                  case 'Clear':
                    iconData = Icons.sunny;
                    break;
                  case 'Clouds':
                    iconData = Icons.cloud;
                    break;
                  case 'Thunderstorm':
                    iconData = Icons.thunderstorm;
                    break;
                  case 'Drizzle':
                  case 'Rain':
                    iconData = Icons.cloudy_snowing;
                    break;
                  case 'Snow':
                    iconData = Icons.snowing;
                    break;
                  case 'Mist':
                  case 'Smoke':
                  case 'Haze':
                  case 'Dust':
                  case 'Fog':
                  case 'Sand':
                  case 'Ash':
                  case 'Squall':
                  case 'Tornado':
                    iconData = Icons.foggy;
                    break;
                  default:
                    iconData = Icons.sunny;
                }
                return IconButton(
                  icon: Icon(iconData),
                  onPressed: () => print("Weather Icon pressed!"),
                );
              } else if (snapshot.hasError) {
                return IconButton(
                  icon: Icon(Icons.error),
                  onPressed: () => print("Error in weather data"),
                );
              }
              return CircularProgressIndicator();
            },
          ),
          StreamBuilder<bool>(
            stream: _cloudService.controller.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                // 根据布尔值选择图标
                IconData iconData = snapshot.data! ? Icons.bed : Icons.accessibility;
                return IconButton(
                  icon: Icon(iconData),
                  onPressed: () {
                    // 可以在这里添加点击图标后的操作
                    print("Icon pressed!");
                  },
                );
              } else if (snapshot.hasError) {
                // 处理错误情况
                return Text("Err!");
              }
              // 默认情况下显示一个循环指示器
              return CircularProgressIndicator();
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: bodyContent,
      ),
      floatingActionButton: FloatingActionButton(

        onPressed: () {
          showAddAlarmSheet(context);
        },

        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.nights_stay),
              color: _selection == DisplaySelection.evening ? selectedColor : unselectedColor,
              onPressed: _setEvening,
              tooltip: 'Evening View',
            ),
            IconButton(
              icon: Icon(Icons.wb_sunny),
              color: _selection == DisplaySelection.morning ? selectedColor : unselectedColor,
              onPressed: _setMorning,
              tooltip: 'Morning View',
            ),
            IconButton(
              icon: Icon(Icons.location_on),
              color: _selection == DisplaySelection.map ? selectedColor : unselectedColor,  // 根据当前的选择改变颜色
              onPressed: _setMap,
              tooltip: 'Map View',
            ),
            IconButton(
              icon: Icon(Icons.person),
              color: _selection == DisplaySelection.user ? selectedColor : unselectedColor,  // 根据当前的选择改变颜色
              onPressed: _setUser,
              tooltip: 'User View',
            ),
          ],
        ),
      ),
    );
  }
}

