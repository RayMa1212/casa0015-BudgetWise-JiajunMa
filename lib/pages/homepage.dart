import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Bottom Navigation Bar Example',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: const MyHomePage(title: 'Home Page'),
//     );
//   }
// }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // Index to track the selected tab

  // Function to handle tab selection
  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String text,
  }) {
    // Check if the current item is selected
    bool isSelected = _selectedIndex == index;

    // Get the theme's secondary color
    Color secondaryColor = Theme.of(context).colorScheme.secondary;

    // Make the selected color darker
    Color color = isSelected
        ? secondaryColor // Making the selected color darker
        : Colors.grey; // Color for unselected tab

    return InkWell(
      onTap: () => _selectTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color), // Apply the color to the icon
          Text(text, style: TextStyle(color: color)), // Apply the color to the text
        ],
      ),
    );
  }


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
      body: Center(
        // Display content based on the selected tab
        child: Text('Tab $_selectedIndex content'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildTabItem(
              index: 0,
              icon: Icons.menu,
              text: 'Schedule',
            ),
            _buildTabItem(
              index: 1,
              icon: Icons.show_chart,
              text: 'Chart',
            ),
            const SizedBox(width: 48), // Space for the floating button
            _buildTabItem(
              index: 2,
              icon: Icons.notifications,
              text: 'Reminder',
            ),
            _buildTabItem(
              index: 3,
              icon: Icons.person,
              text: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
