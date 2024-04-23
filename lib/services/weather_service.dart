import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '810ec5ab21fd0f91563f5c550ac2000e';
  final StreamController<Map> controller = StreamController<Map>.broadcast();
  Timer? _timer;

  void startPolling() {
    Uri url = Uri.parse('http://api.openweathermap.org/data/3.0/onecall?lat=51.5074&lon=-0.1278&exclude=minutely,hourly,daily,alerts&units=metric&appid=$apiKey');

    _timer = Timer.periodic(Duration(seconds: 100000), (timer) async {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        controller.add(data);
      } else {
        print('Failed to load weather data: ${response.statusCode}');
      }
    });
  }

  void stopPolling() {
    _timer?.cancel();
  }

  void dispose() {
    controller.close();
  }
}
