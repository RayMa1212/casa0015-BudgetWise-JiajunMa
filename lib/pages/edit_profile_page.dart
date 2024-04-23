import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Replace with user's image URL
            ),
          ),
          ListTile(
            title: Text('Name'),
            subtitle: Text('Test Test'),
            trailing: Icon(Icons.edit),
            onTap: () {
              // Open edit dialog or navigate to the edit name page
            },
          ),
          ListTile(
            title: Text('Phone'),
            subtitle: Text('(208) 206-5039'),
            trailing: Icon(Icons.edit),
            onTap: () {
              // Open edit dialog or navigate to the edit phone page
            },
          ),
          ListTile(
            title: Text('Email'),
            subtitle: Text('test.test@gmail.com'),
            trailing: Icon(Icons.edit),
            onTap: () {
              // Open edit dialog or navigate to the edit email page
            },
          ),
          ListTile(
            title: Text('Tell Us About Yourself'),
            subtitle: Text('Lorem ipsum dolor sit amet...'), // User's about info here
            isThreeLine: true,
            trailing: Icon(Icons.edit),
            onTap: () {
              // Open edit dialog or navigate to the edit about page
            },
          ),
        ],
      ),
    );
  }
}
