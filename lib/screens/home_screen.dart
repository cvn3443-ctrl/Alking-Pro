import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _controller;
  int _currentIndex = 0;
  bool _botActive = false;

  void _toggleBot() {
    setState(() {
      _botActive = !_botActive;
      if (_botActive) {
        _controller.runJavaScript('alert("Bot Started!")');
      } else {
        _controller.runJavaScript('alert("Bot Stopped!")');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://qxbroker.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleBot,
        backgroundColor: _botActive ? Colors.red : Colors.green,
        child: Icon(_botActive ? Icons.stop : Icons.play_arrow),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          WebViewWidget(controller: _controller),
          const Center(child: Text('شاشة الإعدادات - قيد التطوير')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'تداول'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'إعدادات'),
        ],
      ),
    );
  }
}
