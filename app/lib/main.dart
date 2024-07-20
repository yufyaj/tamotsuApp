import 'package:flutter/material.dart';
import 'package:app/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAMOTSU',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: const LoginScreen(), // ログイン画面を表示
    );
  }
}