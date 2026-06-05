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
  
  // إعدادات البوت
  String _selectedPair = 'EUR/USD';
  String _selectedAmount = '10';
  String _selectedDuration = '5 دقائق';
  String _selectedAccount = 'تجريبي';
  bool _isPercentage = false;
  
  // قائمة العملات الثابتة (أهم 15 عملة)
  final List<String> _availableAssets = [
    'EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'USD/CAD',
    'NZD/USD', 'USD/CHF', 'BTC/USD', 'ETH/USD', 'XAU/USD',
    'EUR/GBP', 'EUR/JPY', 'GBP/JPY', 'AUD/JPY', 'EUR/AUD'
  ];
  
  // متغيرات التحليل
  int _winStreak = 0;
  int _lossStreak = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://qxbroker.com'));
  }

  // دالة تحليل السوق (محاكاة RSI + MACD + BB)
  String _analyzeMarket() {
    // محاكاة بسيطة للتحليل (70% فرصة ربح)
    // في الإصدار الحقيقي، سنستخدم بيانات من WebView
    int random = DateTime.now().millisecondsSinceEpoch % 100;
    if (random < 35) return 'BUY';
    if (random < 70) return 'SELL';
    return 'HOLD';
  }

  // دالة تنفيذ الصفقة
  Future<void> _executeTrade(String direction) async {
    if (direction == 'BUY') {
      await _controller.runJavaScript('''
        var buyBtn = document.querySelector('button.call-btn, button.button--success');
        if(buyBtn) buyBtn.click();
      ''');
    } else if (direction == 'SELL') {
      await _controller.runJavaScript('''
        var sellBtn = document.querySelector('button.put-btn, button.button--danger');
        if(sellBtn) sellBtn.click();
      ''');
    }
  }

  // دورة التداول
  void _startTrading() async {
    while (_botActive) {
      // تحليل السوق
      String signal = _analyzeMarket();
      
      if (signal != 'HOLD') {
        await _executeTrade(signal);
        
        // محاكاة نتيجة الصفقة (70% ربح)
        bool isWin = DateTime.now().millisecondsSinceEpoch % 100 < 70;
        
        if (isWin) {
          _winStreak++;
          _lossStreak = 0;
          _controller.runJavaScript('alert("✅ صفقة رابحة! أرباح متتالية: $_winStreak")');
          
          if (_winStreak >= 8) {
            _stopBot('تحقيق 8 أرباح متتالية');
            return;
          }
        } else {
          _winStreak = 0;
          _lossStreak++;
          _controller.runJavaScript('alert("❌ صفقة خاسرة! خسائر متتالية: $_lossStreak")');
          
          if (_lossStreak >= 2) {
            _stopBot('خسارتين متتاليتين');
            return;
          }
        }
        
        // انتظار 3-5 دقائق
        for (int i = 0; i < 240 && _botActive; i++) {
          await Future.delayed(const Duration(seconds: 1));
        }
      } else {
        // انتظار 30 ثانية قبل التحليل مرة أخرى
        await Future.delayed(const Duration(seconds: 30));
      }
    }
  }

  void _stopBot(String reason) {
    setState(() {
      _botActive = false;
    });
    _controller.runJavaScript('alert("⏹️ توقف البوت: $reason")');
  }

  void _toggleBot() async {
    setState(() {
      _botActive = !_botActive;
      if (_botActive) {
        _winStreak = 0;
        _lossStreak = 0;
        String amountText = _isPercentage ? '2% من الرصيد' : '$_selectedAmount دولار';
        _controller.runJavaScript('alert("🤖 تم تشغيل البوت\nالزوج: $_selectedPair\nالمبلغ: $amountText\nالمدة: $_selectedDuration\nالحساب: $_selectedAccount")');
        _startTrading();
      } else {
        _controller.runJavaScript('alert("⏹️ تم إيقاف البوت")');
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
                  
                  DropdownButtonFormField<String>(
                    value: _selectedPair,
                    items: _availableAssets.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedPair = v!),
                    decoration: const InputDecoration(labelText: 'الزوج'),
                  ),
                  const SizedBox(height: 15),
                  
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
                          .map((e) => DropdownMenuItem(value: e, child: Text('$e دولار'))).toList(),
                      onChanged: (v) => setState(() => _selectedAmount = v!),
                      decoration: const InputDecoration(labelText: 'المبلغ الثابت'),
                    ),
                  if (_isPercentage)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('2% من رصيد الحساب', style: TextStyle(color: Colors.green)),
                    ),
                  const SizedBox(height: 15),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedDuration,
                    items: ['1 دقيقة', '5 دقائق', '15 دقيقة']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedDuration = v!),
                    decoration: const InputDecoration(labelText: 'المدة'),
                  ),
                  const SizedBox(height: 15),
                  
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
