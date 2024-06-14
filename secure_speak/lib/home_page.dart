import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'custom_bottom_nav_bar.dart';
import 'settings_tab.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _videoLinkController = TextEditingController();
  String _result = "";
  int _currentIndex = 0;

  Future<void> _analyzeVideo() async {
    final videoLink = _videoLinkController.text;
    if (videoLink.isEmpty) {
      setState(() {
        _result = "Please enter a video link.";
      });
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('instagram_access_token');
    final csrfToken = prefs.getString('instagram_csrf_token');

    if (sessionId == null || csrfToken == null) {
      setState(() {
        _result = "Session data is missing. Please log in again.";
      });
      return;
    }

    final url = Uri.parse('https://audio-predictor-vfmiaj7avq-uc.a.run.app/process_instagram_reel');
    final headers = {"Content-Type": "application/json"};
    final body = json.encode({
      "reel_url": videoLink,
      "sessionid": sessionId,
      "csrftoken": csrfToken
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _result = "Prediction: ${data['prediction']}, Confidence: ${data['confidence']}%";
        });
      } else {
        setState(() {
          _result = "Error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Exception: $e";
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Home Page' : 'Settings Page'),
        backgroundColor: Color(0xFF22223B),
      ),
      body: _getBody(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return SettingsTab();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _videoLinkController,
              decoration: InputDecoration(
                labelText: "Video Link",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _analyzeVideo,
              child: Text('Analyze'),
            ),
            SizedBox(height: 20),
            Text(
              _result,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
