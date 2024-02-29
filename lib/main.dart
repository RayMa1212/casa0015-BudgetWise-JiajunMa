import 'package:flutter/material.dart';
import 'package:BudgetWise/pages/home_page.dart';
import 'package:BudgetWise/pages/signup_page.dart';
import 'package:BudgetWise/pages/splash_screen.dart'; // Ensure you have this file in your project.
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter绑定已初始化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 使用生成的配置
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudgetWise',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
            toolbarHeight: 50.0
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0x00ccecd4)),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'BudgetWise'),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            // 获取用户数据
            User? user = snapshot.data;
            // 如果User为null，我们可以假定用户已登出
            if (user == null) {
              return SignUpPage(); // 用户未登录，显示登录页面
            }
            return MyHomePage(title: 'BudgetWise',); // 用户已登录，显示主页面
          }
          // 正在检查认证状态，显示加载指示器
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}
