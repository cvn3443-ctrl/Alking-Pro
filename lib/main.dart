import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/trading_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const AlkingProApp());
}

class AlkingProApp extends StatelessWidget {
  const AlkingProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TradingProvider(),
      child: MaterialApp(
        title: 'Alking Pro',
        theme: ThemeData.dark(),
        home: const LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
