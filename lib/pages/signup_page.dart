import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _register() async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // 注册成功
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User registered: ${userCredential.user!.email}")),
      );
    } on FirebaseAuthException catch (e) {
      // 显示错误消息
      var errorMessage = "An error occurred, please try again";
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred, please try again")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Sign Up'),
            ),
            ElevatedButton(
              onPressed: () {
                addUser().then((_) {
                  // 这里可以添加一些用户反馈，比如一个确认消息
                  print('User has been added successfully.');
                }).catchError((error) {
                  // 错误处理
                  print('There was an error adding the user: $error');
                });
              },
              child: Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> addUser() async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  return users
      .add({
    'full_name': "Jane Doe", // John Doe
    'company': "Stokes and Sons",
    'age': 42
  })
      .then((value) => print("User Added"))
      .catchError((error) => print("Failed to add user: $error"));
}
