import 'package:flutter/material.dart';
import 'package:helios_rise/pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:helios_rise/pages/login_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter绑定已初始化
  if (!Firebase.apps.any((app) => app.name == Firebase.app().name)) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeliosRise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            // 获取用户数据
            User? user = snapshot.data;
            // 如果User为null，我们可以假定用户已登出
            if (user == null) {
              return LoginPage(); // 用户未登录，显示登录页面
            }
            return MyHomePage(title: 'HeliosRise',); // 用户已登录，显示主页面
          }
          // 正在检查认证状态，显示加载指示器
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}


