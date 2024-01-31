import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mysql_client/mysql_client.dart';

void main() {
  db();
  runApp(const MyApp());
}

Future<void> db() async {
  try {
    final conn = await MySQLConnection.createConnection(
      host: 'localhost',
      port: 3306,
      userName: 'root',
      password: 'Mjj1212?',
      databaseName: 'BudgetWise',
    );

    // 打开连接
    await conn.connect();

    // 查询表
    final result = await conn.execute('SELECT * FROM users');

    // 打印每一行数据
    for (final row in result.rows) {
      print(row.assoc());
    }

    // 关闭连接
    await conn.close();
  } catch (e) {
    // 异常处理
    print('Error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyHomePage(title: 'BudgetWise')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Image.asset('assets/SplashScreen.png',
          fit: BoxFit.cover, //
          width: double.infinity, //
          height: double.infinity, //
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: Text(widget.title),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        elevation: 2.0,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildTabItem(
              index: 0,
              icon: const Icon(Icons.menu),
              text: 'Schedule',
            ),
            _buildTabItem(
              index: 1,
              icon: const Icon(Icons.show_chart),
              text: 'Chart',
            ),
            const SizedBox(width: 48), // 为浮动按钮腾出空间
            _buildTabItem(
              index: 2,
              icon: const Icon(Icons.notifications),
              text: 'Reminder',
            ),
            _buildTabItem(
              index: 3,
              icon: const Icon(Icons.person),
              text: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required Icon icon,
    required String text,
  }) {
    return InkWell(
      onTap: () => _selectTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          icon,
          Text(text),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}


