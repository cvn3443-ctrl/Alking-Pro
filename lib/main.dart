import 'package:flutter/material.dart';
import 'screens/activation_screen.dart';

void main() {
  runApp(const AlkingProApp());
}

class AlkingProApp extends StatelessWidget {
  const AlkingProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alking Pro',
      theme: ThemeData.dark(),
      home: const ActivationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
