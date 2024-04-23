import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helios_rise/pages/home_page.dart';

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await FirebaseFirestore.instance.collection('feedback').add({
        'feedback': _feedbackController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        _isLoading = false;
      });
      _feedbackController.clear();
      _showSnackBar('Feedback submitted successfully');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MyHomePage(title: 'HelioRise')),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'We value your feedback',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _feedbackController,
                      decoration: InputDecoration(
                        labelText: 'Enter your feedback',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.feedback),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some feedback';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    _isLoading ? CircularProgressIndicator() : ElevatedButton(
                      onPressed: _submitFeedback,
                      child: Text('Submit'),
                      // style: ElevatedButton.styleFrom(
                      //   primary: Colors.deepPurple,
                      //   onPrimary: Colors.white,
                      //   padding: EdgeInsets.symmetric(vertical: 12),
                      // ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
