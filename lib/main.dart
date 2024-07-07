import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ApiService apiService = ApiService();

  MyApp() {
    initializeApp();
  }

  void initializeApp() async {
    await apiService.fetchAndStorePlayers();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fussball App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}
