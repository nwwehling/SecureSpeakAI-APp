import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'custom_bottom_nav_bar.dart';  // Import the custom bottom nav bar
import 'results_page.dart';  // Import the results page
import 'settings_tab.dart';  // Import the settings tab

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late StreamSubscription _intentDataStreamSubscription;
  List<SharedMediaFile> _sharedFiles = [];
  int _currentIndex = 0;  // Add current index to manage selected tab
  List<String> _receivedLinks = [];  // List to store received links

  @override
  void initState() {
    super.initState();

    // For receiving intents while the app is in the foreground
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
        if (_sharedFiles.isNotEmpty) {
          _receivedLinks.addAll(_sharedFiles.map((file) => file.path));
        }
      });
    }, onError: (err) {
      print("getMediaStream error: $err");
    });

    // For receiving intents when the app is launched
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
        if (_sharedFiles.isNotEmpty) {
          _receivedLinks.addAll(_sharedFiles.map((file) => file.path));
        }
      });

      // Tell the library that we are done processing the intent
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  // Method to handle tab switching
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        backgroundColor: Color(0xFF22223B),
      ),
      body: _getBody(),  // Get the current body based on selected tab
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  // Method to get the current body based on selected tab
  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return ResultsPage(receivedLinks: _receivedLinks);  // Use ResultsPage
      case 2:
        return SettingsTab();  // Use SettingsTab
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Center(
      child: Text(
        'Welcome to the Home Page!',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
