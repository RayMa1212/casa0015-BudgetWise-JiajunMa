import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:helios_rise/info/alarm_info.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:intl/intl.dart';



class FirestoreService {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitEveningData({
    required String destination,
    required List<String> travelMethods,
    required String wakeUpPolicy,
    // required bool allowLaterThanSet,
    required String timeToArrive,
    required LatLng currentPosition,
    required LatLng destinationPosition,
    required int washingTime,
    required String dayOfWeek, // 添加一个参数来指定星期几
    required bool status,
  }) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // 创建唯一ID，例如使用时间戳
    String documentId = '${DateTime.now().millisecondsSinceEpoch}';


    DocumentReference docRef = _firestore
        .collection('user_data')
        .doc(userId)
        .collection(dayOfWeek)
        .doc(documentId); // 使用星期几作为文档ID

    return await docRef.set({
      'destination': destination,
      'travelMethod': travelMethods,
      'wakeUpPolicy': wakeUpPolicy,
      // 'allowLaterThanSet': allowLaterThanSet,
      'timeToArrive': timeToArrive,
      'timestamp': FieldValue.serverTimestamp(),
      'currentPosition': {
        'latitude': currentPosition.latitude,
        'longitude': currentPosition.longitude
      },
      'destinationPosition': {
        'latitude': destinationPosition.latitude,
        'longitude': destinationPosition.longitude
      },
      'washingTime': washingTime,
      'status':status,
    }, SetOptions(merge: true));
  }

  Future<List<AlarmInfo>> fetchAlarms(day) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    QuerySnapshot snapshot = await _firestore
        .collection('user_data')
        .doc(userId)
        .collection(day)
        .get();

    List<AlarmInfo> alarms = snapshot.docs
        .map((doc) => AlarmInfo.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    return alarms;
  }

  Future<void> updateAlarm(AlarmInfo alarm, bool isEnabled, day) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    CollectionReference alarmsCollection = FirebaseFirestore.instance
        .collection('user_data')
        .doc(userId)
        .collection(day);

    WriteBatch batch = FirebaseFirestore.instance.batch();

    try {
      // 获取该日所有闹钟
      QuerySnapshot snapshot = await alarmsCollection.get();

      for (var doc in snapshot.docs) {
        // 将所有闹钟的status设置为false
        batch.update(doc.reference, {'status': false});
      }

      // 提交批处理操作
      await batch.commit();
    } catch (e) {
      print(e); // 处理错误
    }

    await FirebaseFirestore.instance
        .collection('user_data')
        .doc(userId)
        .collection(day)
        .doc(alarm.id) // 使用存储在AlarmInfo中的文档ID
        .update({'status': isEnabled})
        .catchError((error) => print("Error updating alarm enabled status: $error"));
  }

  Future<void> updateAlarmInfo(AlarmInfo updatedAlarm, String day) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      print("User not logged in");
      return;
    }

    CollectionReference alarmsCollection = FirebaseFirestore.instance
        .collection('user_data')
        .doc(userId)
        .collection(day);

    WriteBatch batch = FirebaseFirestore.instance.batch();

    try {
      // 获取该日所有闹钟
      QuerySnapshot snapshot = await alarmsCollection.get();

      for (var doc in snapshot.docs) {
        // 将所有闹钟的status设置为false，除了当前要更新的闹钟
        if (doc.id != updatedAlarm.id) {
          batch.update(doc.reference, {'status': false});
        }
      }

      // 更新目标闹钟的信息
      DocumentReference targetAlarmRef = alarmsCollection.doc(updatedAlarm.id);
      batch.update(targetAlarmRef, {
        'destination': updatedAlarm.destination,
        'timeToArrive': updatedAlarm.timeToArrive,
        'washingTime': updatedAlarm.washingTime,

        'travelMethod': updatedAlarm.travelMethods,
        'wakeUpPolicy': updatedAlarm.wakeUpPolicy,
        // 'allowLaterThanSet': updatedAlarm.allowLaterThanSet,

        'timestamp': FieldValue.serverTimestamp(),

        'destinationPosition': {
          'latitude': updatedAlarm.destinationPosition.latitude,
          'longitude': updatedAlarm.destinationPosition.longitude
        },
        // 更新其他必要的字段
      });

      // 提交批处理操作
      await batch.commit();
    } catch (e) {
      print("Error updating alarms: $e");
    }
  }



  Future<Map<String, AlarmInfo>> fetchActiveAlarmsByDay() async {
    Map<String, AlarmInfo> activeAlarmsByDay = {};
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    // 假设我们有一个包含所有星期几名称的列表
    List<String> daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    for (String day in daysOfWeek) {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('user_data')
          .doc(userId)
          .collection(day)
          .where('status', isEqualTo: true)
          .get();

      // 假设我们对于每一天只关心一个闹钟，所以我们尝试获取第一个
      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        AlarmInfo alarm = AlarmInfo.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        activeAlarmsByDay[day] = alarm;
      }
    }

    return activeAlarmsByDay;
  }

  Future<void> deleteAlarmFromFirestore(String docId, String day) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    // 确保用户已经登录
    if (userId == null) {
      throw Exception('User not logged in');
    }

    await _firestore
        .collection('user_data')
        .doc(userId)
        .collection(day)
        .doc(docId)
        .delete();
  }


  Future<AlarmInfo?> fetchNextActiveAlarm() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    Map<String, AlarmInfo> activeAlarmsByDay = await fetchActiveAlarmsByDay();
    DateTime now = DateTime.now();
    String today = DateFormat('EEEE').format(now);
    List<String> daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    int todayIndex = daysOfWeek.indexOf(today);
    List<String> queryDays = [
      daysOfWeek[todayIndex], // today
      daysOfWeek[(todayIndex + 1) % daysOfWeek.length] // next day
    ];

    for (String day in queryDays) {
      if (!activeAlarmsByDay.containsKey(day)) continue; // Skip if no alarm for the day
      AlarmInfo? alarm = activeAlarmsByDay[day];

      if (alarm == null) continue; // If no alarm info available, continue to next

      // For today, check if the alarm time is later than now
      if (day == today) {
        DateTime alarmTimeToday = DateFormat('HH:mm').parse(alarm.timeToArrive);
        DateTime fullAlarmTimeToday = DateTime(now.year, now.month, now.day, alarmTimeToday.hour, alarmTimeToday.minute);
        if (fullAlarmTimeToday.isAfter(now)) {
          return alarm;
        }
      } else {
        // For the next day, return the first alarm found
        return alarm;
      }
    }

    return null; // No valid alarms found if loop completes
  }










// Future<List<Map<String, dynamic>>> fetchData() async {
//   // 确保用户已经登录
//   String? userId = FirebaseAuth.instance.currentUser?.uid;
//   if (userId == null) {
//     print('User not logged in');
//     return [];
//   }
//
//
//
//   // 获取当前用户的 evening_entries 集合中的所有文档
//   QuerySnapshot querySnapshot = await _firestore
//       .collection('user_data')
//       .doc(userId)
//       .collection('evening_entries')
//       .get();
//
//   // Create a list to hold the data from each document
//   List<Map<String, dynamic>> documentsData = [];
//
//   // Iterate over each document
//   for (var doc in querySnapshot.docs) {
//     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//     // Add the document's data to the list
//     documentsData.add(data);
//   }
//
//   // Return the list of documents' data
//   return documentsData;
//
// }



}
