import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'instagram_login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FlutterDownloader.initialize(debug: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/instagram-login': (context) => InstagramLoginPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  Future<bool> _hasInstagramSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('instagram_session_id');
    String? csrfToken = prefs.getString('instagram_csrf_token');
    return sessionId != null && csrfToken != null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return FutureBuilder<bool>(
            future: _hasInstagramSession(),
            builder: (context, instagramSnapshot) {
              if (instagramSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (instagramSnapshot.hasData && instagramSnapshot.data!) {
                return HomePage();
              } else {
                return InstagramLoginPage();
              }
            },
          );
        } else {
          return LoginPage();
        }
      },
    );
  }
}
