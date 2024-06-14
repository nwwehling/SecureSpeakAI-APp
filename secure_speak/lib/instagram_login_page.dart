import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InstagramLoginPage extends StatefulWidget {
  @override
  _InstagramLoginPageState createState() => _InstagramLoginPageState();
}

class _InstagramLoginPageState extends State<InstagramLoginPage> {
  final String clientId = '446444214698013';
  final String clientSecret = '5aa4803916a0d6417b50fd300c158ec7';
  final String redirectUri = 'https://speakapp-945c5.firebaseapp.com/__/auth/handler';

  final flutterWebviewPlugin = FlutterWebviewPlugin();

  @override
  void initState() {
    super.initState();

    flutterWebviewPlugin.onUrlChanged.listen((String url) async {
      if (url.startsWith(redirectUri)) {
        var code = Uri.parse(url).queryParameters['code'];

        if (code != null) {
          await _getAccessToken(code);
        }
      }
    });
  }

  Future<void> _getAccessToken(String code) async {
    final tokenUrl = 'https://api.instagram.com/oauth/access_token';
    final response = await http.post(Uri.parse(tokenUrl), body: {
      'client_id': clientId,
      'client_secret': clientSecret,
      'grant_type': 'authorization_code',
      'redirect_uri': redirectUri,
      'code': code,
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final accessToken = data['access_token'];

      // Save access token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('instagram_access_token', accessToken);

      // Get cookies from the webview
      final cookies = await flutterWebviewPlugin.evalJavascript("document.cookie");
      print("Cookies: $cookies"); // Debugging line to print cookies

      String sessionId = '';
      String csrfToken = '';
      if (cookies != null) {
        final cookieList = cookies.split('; ');
        for (var cookie in cookieList) {
          if (cookie.startsWith('sessionid=')) {
            sessionId = cookie.split('=')[1];
          } else if (cookie.startsWith('csrftoken=')) {
            csrfToken = cookie.split('=')[1];
          }
        }
      }

      print("Session ID: $sessionId"); // Debugging line to print session ID
      print("CSRF Token: $csrfToken"); // Debugging line to print CSRF token

      await prefs.setString('instagram_session_id', sessionId);
      await prefs.setString('instagram_csrf_token', csrfToken);

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print('Failed to authenticate with Instagram');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUrl =
        'https://api.instagram.com/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&scope=user_profile,user_media&response_type=code';

    return WebviewScaffold(
      url: authUrl,
      appBar: AppBar(
        title: Text('Instagram Login'),
      ),
      withJavascript: true,
      clearCookies: false,
      clearCache: false,
    );
  }
}
