import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _controller;
  int _currentIndex = 0;
  bool _botActive = false;
  
  // إعدادات البوت
  String _selectedPair = 'EUR/USD';
  String _selectedAmount = '10';
  String _selectedDuration = '5 دقائق';
  String _selectedAccount = 'تجريبي';
  bool _isPercentage = false; // false = مبلغ ثابت, true = نسبة مئوية
  
  List<String> _availableAssets = ['EUR/USD', 'GBP/USD', 'BTC/USD'];
  bool _isLoadingAssets = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://qxbroker.com'));
    _fetchAssets();
  }

  // جلب العملات من المنصة
  Future<void> _fetchAssets() async {
    try {
      final response = await http.get(Uri.parse('https://qxbroker.com/api/assets'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assets = (data['assets'] as List)
            .map((asset) => asset['name'].toString())
            .toList();
        setState(() {
          _availableAssets = assets;
          _isLoadingAssets = false;
        });
      } else {
        setState(() => _isLoadingAssets = false);
      }
    } catch (e) {
      setState(() => _isLoadingAssets = false);
    }
  }

  void _toggleBot() {
    setState(() {
      _botActive = !_botActive;
      String amountText = _isPercentage ? '2% من الرصيد' : '$_selectedAmount $';
      if (_botActive) {
        _controller.runJavaScript('alert("Bot Started!\nالزوج: $_selectedPair\nالمبلغ: $amountText\nالمدة: $_selectedDuration\nالحساب: $_selectedAccount")');
      } else {
        _controller.runJavaScript('alert("Bot Stopped!")');
      }
    });
  }

  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1a1a1a),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('إعدادات البوت', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // اختيار الزوج (يتحدث مع المنصة)
                  if (_isLoadingAssets)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedPair,
                      items: _availableAssets.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _selectedPair = v!),
                      decoration: const InputDecoration(labelText: 'الزوج'),
                    ),
                  const SizedBox(height: 15),
                  
                  // خيار المبلغ (ثابت أو نسبة)
                  SwitchListTile(
                    title: const Text('نسبة مئوية (2%)'),
                    value: _isPercentage,
                    onChanged: (v) {
                      setStateBottomSheet(() => _isPercentage = v);
                      setState(() => _isPercentage = v);
                    },
                  ),
                  
                  if (!_isPercentage)
                    DropdownButtonFormField<String>(
                      value: _selectedAmount,
                      items: ['5', '10', '25', '50', '100']
                          .map((e) => DropdownMenuItem(value: e, child: Text('$e $'))).toList(),
                      onChanged: (v) => setState(() => _selectedAmount = v!),
                      decoration: const InputDecoration(labelText: 'المبلغ الثابت'),
                    ),
                  if (_isPercentage)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('2% من رصيد الحساب', style: TextStyle(color: Colors.green)),
                    ),
                  const SizedBox(height: 15),
                  
                  // اختيار المدة
                  DropdownButtonFormField<String>(
                    value: _selectedDuration,
                    items: ['1 دقيقة', '5 دقائق', '15 دقيقة']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedDuration = v!),
                    decoration: const InputDecoration(labelText: 'المدة'),
                  ),
                  const SizedBox(height: 15),
                  
                  // اختيار نوع الحساب
                  DropdownButtonFormField<String>(
                    value: _selectedAccount,
                    items: ['تجريبي', 'حقيقي']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedAccount = v!),
                    decoration: const InputDecoration(labelText: 'نوع الحساب'),
                  ),
                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alking Pro'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsPanel,
          ),
        ],
      ),
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
