import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsTab extends StatefulWidget {
  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String sessionId = '';
  String csrfToken = '';

  @override
  void initState() {
    super.initState();
    _loadInstagramSessionData();
  }

  Future<void> _loadInstagramSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sessionId = prefs.getString('instagram_session_id') ?? 'No session ID found';
      csrfToken = prefs.getString('instagram_csrf_token') ?? 'No CSRF token found';
    });
  }

  Future<void> _clearInstagramSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('instagram_session_id');
    await prefs.remove('instagram_csrf_token');
    setState(() {
      sessionId = 'No session ID found';
      csrfToken = 'No CSRF token found';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Settings Page',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF22223B), // Your company color
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(
              'Log Out',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await _clearInstagramSessionData();
              // Navigate to the Instagram login page or perform other actions as needed
              Navigator.pushReplacementNamed(context, '/instagram_login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF22223B), // Your company color
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(
              'Log Out of Instagram',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Session ID:',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 10),
          Text(
            sessionId,
            style: TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            'CSRF Token:',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 10),
          Text(
            csrfToken,
            style: TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
