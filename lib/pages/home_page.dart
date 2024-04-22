import 'dart:core';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:helios_rise/services/firebase_service.dart';
import 'package:helios_rise/services/location_service.dart';
import 'package:helios_rise/pages/day_info_page.dart';
import 'package:helios_rise/info/alarm_info.dart';
import 'package:helios_rise/widget/alarm_info_widget.dart';
import 'dart:math';

enum DisplaySelection { morning, evening, map}

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


  @override
  void initState() {
    super.initState();

    _fetchNextActiveAlarm();
    _fetchActiveAlarms();
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
                  // 第一个页面：闹钟信息
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: nextAlarmInfo != null
                        ? AlarmInfoWidget(alarmInfo: nextAlarmInfo!)
                        : Center(child: Text("No upcoming alarms.", style: TextStyle(fontSize: 18))),
                  ),
                ],
              ),
            ),
          ],
        );
        break;
      case DisplaySelection.map:
        bodyContent = SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  height: 300, // 指定高度
                  width: double.infinity, // 宽度尽可能大
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: initialCameraPosition,
                    myLocationEnabled: true, // 显示当前位置
                    myLocationButtonEnabled: true, // 显示移动到当前位置的按钮
                    markers: _markers,
                    polylines: _polylines,
                    padding: EdgeInsets.only(top: 0, right: 0, bottom: 0, left: 0),
                  ),
                ),
              ],
            ),
          ),

        );
        break;
    }

    Color selectedColor = Theme.of(context).colorScheme.primary;
    Color unselectedColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: bodyContent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
              icon: Icon(Icons.map),
              color: _selection == DisplaySelection.map ? selectedColor : unselectedColor,  // 根据当前的选择改变颜色
              onPressed: _setMap,
              tooltip: 'Map View',
            ),
          ],
        ),
      ),
    );
  }
}

