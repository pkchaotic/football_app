import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'agent_profile_screen.dart'; // Falls benötigt
import 'coach_profile_screen.dart'; // Falls benötigt

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String role = 'agent'; // Default role

  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  void login() async {
    String email = emailController.text;
    String password = passwordController.text;

    final user = await dbHelper.getUser(email, password, role);
    if (user != null) {
      if (user['role'] == 'agent') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgentProfileScreen(userId: user['id']),
          ),
        );
      } else if (user['role'] == 'coach') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoachProfileScreen(userId: user['id']),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid credentials')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            DropdownButton<String>(
              value: role,
              onChanged: (String? newValue) {
                setState(() {
                  role = newValue!;
                });
              },
              items: <String>['agent', 'coach']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
