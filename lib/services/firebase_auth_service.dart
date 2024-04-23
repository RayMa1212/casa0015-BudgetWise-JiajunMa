import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:helios_rise/pages/login_page.dart';

class Authservice {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      // 登出成功后，返回登录页面或其他页面
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error signing out: $e")),
      );
    }
  }

}
