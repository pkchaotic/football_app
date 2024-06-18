import 'package:flutter/material.dart';
import 'player_list_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Player Stats',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PlayerListScreen(),
    );
  }
}
