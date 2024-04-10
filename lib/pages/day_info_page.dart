import 'dart:core';
import 'package:flutter/material.dart';
import 'package:helios_rise/pages/add_alarm_page.dart';
import 'package:helios_rise/info/alarm_info.dart';
import 'package:helios_rise/services/firebase_service.dart';
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
      // 更新被切换的闹钟状态
      toggledAlarm.status = newValue;
      // 将其他所有闹钟的状态设置为false
      _alarms.where((alarm) => alarm.id != toggledAlarm.id).forEach((alarm) {
        alarm.status = false;
      });
    });

    // 调用Firestore服务更新数据库
    FirestoreService().updateAlarm(toggledAlarm, newValue, widget.day);
  }

  Future<void> _fetchAndStoreAlarms() async {
    List<AlarmInfo> fetchedAlarms = await FirestoreService().fetchAlarms(widget.day);
    setState(() {
      _alarms = fetchedAlarms; // 更新本地列表
    });
  }

  void _deleteItem(day, index) {
    FirestoreService().deleteAlarmFromFirestore(index, day);
    setState(() {
      _alarms.removeWhere((alarm) => alarm.id == index); // 删除特定索引的元素
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
            // 在这里执行返回操作
            // 通常是调用 Navigator.pop(context)
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
              // 显示一个 Snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Clock dismissed')),
              );
            },
            background: Container(color: Colors.red),
            child: ListTile(
              title: Text(alarm.destination),
              subtitle: Text('Arrive by: ${alarm.timeToArrive}, Washing Time: ${alarm.washingTime} minutes'),
              trailing: Switch(
                key: Key(alarm.id), // 使用唯一的Key
                value: alarm.status,
                onChanged: (bool newValue) {
                  _handleSwitchChange(alarm, newValue, _alarms);
                },
              ),
            ),
          );ListTile(
            title: Text(alarm.destination),
            subtitle: Text('Arrive by: ${alarm.timeToArrive}, Washing Time: ${alarm.washingTime} minutes'),
            trailing: Switch(
              key: Key(alarm.id), // 使用唯一的Key
              value: alarm.status,
              onChanged: (bool newValue) {
                _handleSwitchChange(alarm, newValue, _alarms);
              },
            ),
          );
        },
      )

    );
  }
}
