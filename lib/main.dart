import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
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
              text: '日程',
            ),
            _buildTabItem(
              index: 1,
              icon: const Icon(Icons.show_chart),
              text: '图表',
            ),
            const SizedBox(width: 48), // 为浮动按钮腾出空间
            _buildTabItem(
              index: 2,
              icon: const Icon(Icons.notifications),
              text: '提醒',
            ),
            _buildTabItem(
              index: 3,
              icon: const Icon(Icons.person),
              text: '我的',
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
