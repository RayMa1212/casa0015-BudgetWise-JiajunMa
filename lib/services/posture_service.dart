import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudService {
  final StreamController<bool> controller = StreamController<bool>.broadcast();
  Timer? _timer;

  Future<void> callPostureFunction() async {
    try {
      var url = Uri.parse('https://europe-west2-heliosrise2.cloudfunctions.net/function-result');
      var response = await http.get(url, headers: {
        'Posture': '',
      });

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        // 解析boolean_data为布尔值
        bool booleanData = data['boolean_value'] == 'true';
        controller.add(booleanData);
      } else {
        print('Failed to call function: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling cloud function: $e');
    }
  }

  void startPolling() {
    _timer = Timer.periodic(Duration(seconds: 100), (timer) {
      callPostureFunction();
    });
  }

  void stopPolling() {
    _timer?.cancel();
  }

  void dispose() {
    controller.close();
  }
}
