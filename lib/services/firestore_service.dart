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
    required String dayOfWeek, // Add a parameter to specify the day of the week
    required bool status,
  }) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // Create a unique ID, for example using a timestamp
    String documentId = '${DateTime.now().millisecondsSinceEpoch}';


    DocumentReference docRef = _firestore
        .collection('user_data')
        .doc(userId)
        .collection(dayOfWeek)
        .doc(documentId); // Use day of week as document ID

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
      // Get all alarms for that day
      QuerySnapshot snapshot = await alarmsCollection.get();

      for (var doc in snapshot.docs) {
        // Set the status of all alarm clocks to false
        batch.update(doc.reference, {'status': false});
      }

      // Submit batch operation
      await batch.commit();
    } catch (e) {
      print(e); // handling errors
    }

    await FirebaseFirestore.instance
        .collection('user_data')
        .doc(userId)
        .collection(day)
        .doc(alarm.id) // Use the document ID stored in AlarmInfo
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
        // Set status to false for all alarms except the one currently being updated
        if (doc.id != updatedAlarm.id) {
          batch.update(doc.reference, {'status': false});
        }
      }

      // Update target alarm information
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
        // Update other necessary fields
      });

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

    // 获取按星期几组织的闹钟数据
    Map<String, AlarmInfo> activeAlarmsByDay = await fetchActiveAlarmsByDay();

    // 获取当前时间和明天的日期
    DateTime now = DateTime.now();
    DateTime tomorrow = DateTime(now.year, now.month, now.day).add(Duration(days: 1));
    String tomorrowDayOfWeek = DateFormat('EEEE').format(tomorrow);

    // 通过枚举出来的明天的日期，判断是否有对应的闹钟
    if (activeAlarmsByDay.containsKey(tomorrowDayOfWeek)) {
      AlarmInfo? alarm = activeAlarmsByDay[tomorrowDayOfWeek];
      if (alarm != null) {
        // 如果明天有设置闹钟，返回这个闹钟信息
        return alarm;
      } else {
        // 如果明天没有闹钟信息
        return null;
      }
    } else {
      // 如果明天不在闹钟映射中，表示没有设置闹钟
      return null;
    }
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
