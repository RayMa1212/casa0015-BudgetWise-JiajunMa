// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
//
// import 'package:audioplayers/audioplayers.dart';
//
//
// AudioPlayer audioPlayer = AudioPlayer();
// String localAsset = 'alarm2.mp3';
//
// void playSound() async {
//
//   audioPlayer.onPlayerStateChanged.listen((state) {
//     if(state == PlayerState.stopped) {
//       print("Playback stopped");
//     } else if(state == PlayerState.paused) {
//       print("Playback paused");
//     }
//   });
//   // 设置音频播放模式为循环
//   await audioPlayer.setReleaseMode(ReleaseMode.loop);
//
//   // 播放音频
//   await audioPlayer.play(AssetSource(localAsset));
// }
//
// void stopSound() async {
//   await audioPlayer.stop();
// }
//
//
// Future<void> setOneShotAlarm() async {
//   // 使用当前时间加上延迟时间来计算闹钟触发的确切时间
//   DateTime now = DateTime.now();
//   DateTime alarmTime = now.add(Duration(seconds: 5)); // 例如，5秒后触发闹钟
//
//   // 设置一次性闹钟
//   await AndroidAlarmManager.oneShot(
//     Duration(seconds: 5), // 延迟时间
//     0, // 唯一标识符
//     playSound, // 顶层回调函数
//     alarmClock: true, // 是否显示在时钟应用中
//     allowWhileIdle: true, // 是否在Doze模式时触发
//     exact: true, // 是否精确触发
//     wakeup: true, // 是否唤醒设备
//     rescheduleOnReboot: true, // 设备重启后是否重新调度
//   );
// }


// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:audioplayers/audioplayers.dart';
//
// final AudioPlayer audioPlayer = AudioPlayer(); // 全局音频播放器
//
//
// void playSound() async {
//   await audioPlayer.setReleaseMode(ReleaseMode.loop);
//   await audioPlayer.play(AssetSource('alarm2.mp3'));
// }
//
// void stopSound() async {
//   await audioPlayer.stop();
// }
//
//
// Future<void> setOneShotAlarm() async {
//   DateTime now = DateTime.now();
//   DateTime alarmTime = now.add(Duration(seconds: 1)); // 设定闹钟时间，这里是5秒后
//
//   await AndroidAlarmManager.oneShotAt(
//     alarmTime,
//     0, // 唯一标识符
//     playSound, // 播放音乐的函数
//     exact: true,
//     wakeup: true,
//   );
// }

