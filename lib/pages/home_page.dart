import 'package:flutter/material.dart';
import 'package:BudgetWise/pages/signup_page.dart';
import './login_page.dart'; // Import the login form screen


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // Adjust the _selectTab method
  void _selectTab(int index) {
    if (index == 3) {
      // For Profile tab, navigate to LoginForm and do not update _selectedIndex
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpPage()),
      );
    } else {
      // For all other tabs, update the _selectedIndex to show the corresponding tab content
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Update _buildTabItem to not require onPressed for Profile anymore
  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String text,
  }) {
    Color color = _selectedIndex == index
        ? Theme.of(context).colorScheme.secondary // Use secondary color for selected tab
        : Colors.grey; // Use grey for unselected tab

    return InkWell(
      onTap: () => _selectTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // Display dynamic content based on the selected tab
        child: _getTabContent(_selectedIndex),
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

  // Method to decide which content to show based on the selected index
  Widget _getTabContent(int index) {
    switch (index) {
      case 0:
        return Text('Schedule');
      case 1:
        return Text('Chart');
      case 2:
        return Text('Reminder');
      case 3:
        return Container(); // Placeholder for the Profile tab which navigates away
      default:
        return Text('Unknown');
    }
  }
}
