import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/activation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // طلب أذن الإنترنت عند بدء التشغيل
  await Permission.internet.request();
  
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
