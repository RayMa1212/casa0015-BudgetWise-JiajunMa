import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';

final AudioPlayer audioPlayer = AudioPlayer(); // 全局音频播放器


void playSound() async {
  await audioPlayer.setReleaseMode(ReleaseMode.loop);
  await audioPlayer.play(AssetSource('alarm2.mp3'));
}

void stopSound() async {
  await audioPlayer.stop();
}


Future<void> setOneShotAlarm(DateTime alarmTime) async {
  await AndroidAlarmManager.oneShotAt(
    alarmTime,
    0, // 唯一标识符
    playSound, // 播放音乐的函数
    exact: true,
    wakeup: true,
  );
}

