import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _botActive = false;
  int _winStreak = 0;
  int _lossStreak = 0;
  int _totalTrades = 0;
  int _todayTrades = 0;
  int _maxTradesPerDay = 50;
  int _targetTrades = 5;
  
  String _selectedPair = 'EUR/USD';
  final TextEditingController _amountController = TextEditingController(text: '10');
  String _selectedDuration = '5';
  String _selectedAccount = 'تجريبي';
  bool _isPercentage = false;
  
  List<String> _availableAssets = [];
  List<Map<String, dynamic>> _tradeLog = [];
  int _currentTab = 0;
  late final WebViewController _webViewController;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadSettings();
    _loadTradeLog();
    _loadAssets();
    _checkSavedSession();
    _startStatusPolling();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://qxbroker.com'));
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('quotex_email');
    if (email != null) setState(() => _isLoggedIn = true);
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('الرجاء إدخال البريد الإلكتروني وكلمة السر');
      return;
    }
    setState(() => _isLoading = true);
    final result = await ApiService.login(email, password);
    if (result['status'] == 'success') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('quotex_email', email);
      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
      });
      _showSnackbar('✅ تم تسجيل الدخول بنجاح');
      await _loadAssets();
    } else {
      _showSnackbar(result['message'] ?? '❌ فشل تسجيل الدخول');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssets() async {
    final assets = await ApiService.getAssets();
    setState(() => _availableAssets = assets);
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (_isLoggedIn) {
        final status = await ApiService.getStatus();
        setState(() {
          _botActive = status['active'] ?? false;
          _winStreak = status['win_streak'] ?? 0;
          _lossStreak = status['loss_streak'] ?? 0;
          _totalTrades = status['total_trades'] ?? 0;
        });
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pair', _selectedPair);
    await prefs.setString('amount', _amountController.text);
    await prefs.setString('duration', _selectedDuration);
    await prefs.setString('account', _selectedAccount);
    await prefs.setBool('isPercentage', _isPercentage);
    await prefs.setInt('maxTradesPerDay', _maxTradesPerDay);
    await prefs.setInt('targetTrades', _targetTrades);
    _showSnackbar('تم حفظ الإعدادات ✅');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPair = prefs.getString('pair') ?? 'EUR/USD';
      _amountController.text = prefs.getString('amount') ?? '10';
      _selectedDuration = prefs.getString('duration') ?? '5';
      _selectedAccount = prefs.getString('account') ?? 'تجريبي';
      _isPercentage = prefs.getBool('isPercentage') ?? false;
      _maxTradesPerDay = prefs.getInt('maxTradesPerDay') ?? 50;
      _targetTrades = prefs.getInt('targetTrades') ?? 5;
    });
  }

  Future<void> _loadTradeLog() async {
    final prefs = await SharedPreferences.getInstance();
    final int? savedTrades = prefs.getInt('todayTrades');
    setState(() => _todayTrades = savedTrades ?? 0);
    // تحميل سجل الصفقات من SharedPreferences (مبسط)
    final String? logString = prefs.getString('tradeLog');
    if (logString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(logString);
        setState(() => _tradeLog = decoded.map((e) => Map<String, dynamic>.from(e)).toList());
      } catch (e) {}
    }
  }

  Future<void> _saveTradeLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('todayTrades', _todayTrades);
    await prefs.setString('tradeLog', jsonEncode(_tradeLog));
  }

  void _addTrade(String pair, String result, double amount, String duration) {
    setState(() {
      _tradeLog.insert(0, {
        'pair': pair,
        'result': result,
        'amount': amount,
        'duration': duration,
        'time': DateTime.now().toString().substring(11, 16),
      });
    });
    _saveTradeLog();
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _toggleBot() async {
    if (!_isLoggedIn) {
      _showSnackbar('الرجاء تسجيل الدخول أولاً');
      return;
    }
    if (_botActive) {
      await ApiService.stopTrading();
      _showSnackbar('⏹️ تم إيقاف البوت');
    } else {
      final double amount = _isPercentage ? 0.0 : double.parse(_amountController.text);
      final result = await ApiService.startTrading(
        pair: _selectedPair,
        amount: amount,
        duration: int.parse(_selectedDuration),
        accountType: _selectedAccount,
        targetTrades: _targetTrades,
        maxTradesPerDay: _maxTradesPerDay,
      );
      if (result['status'] == 'started') {
        _showSnackbar('🚀 تم تشغيل البوت');
        // إضافة صفقة تجريبية فورية (لاختبار واجهة المستخدم)
        _addTrade(_selectedPair, 'صفقة اختبار (محاكاة)', amount, _selectedDuration);
      } else {
        _showSnackbar('❌ فشل تشغيل البوت: ${result['message']}');
      }
    }
  }

  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBottomSheet) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
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
                Row(
                  children: [
                    const Text('عدد الصفقات:'),
                    Expanded(
                      child: Slider(
                        value: _targetTrades.toDouble(),
                        min: 1, max: 10, divisions: 9,
                        onChanged: (v) {
                          setStateBottomSheet(() => _targetTrades = v.toInt());
                          setState(() => _targetTrades = v.toInt());
                        },
                      ),
                    ),
                    Text('$_targetTrades'),
                  ],
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
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'المبلغ الثابت (دولار)', border: OutlineInputBorder()),
                  ),
                if (_isPercentage)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('2% من رصيد الحساب', style: TextStyle(color: Colors.green)),
                  ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedDuration,
                  items: ['1', '5', '15'].map((e) => DropdownMenuItem(value: e, child: Text('$e دقيقة'))).toList(),
                  onChanged: (v) => setState(() => _selectedDuration = v!),
                  decoration: const InputDecoration(labelText: 'المدة'),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedAccount,
                  items: ['تجريبي', 'حقيقي'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _selectedAccount = v!),
                  decoration: const InputDecoration(labelText: 'نوع الحساب'),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Text('الحد اليومي:'),
                    Expanded(
                      child: Slider(
                        value: _maxTradesPerDay.toDouble(),
                        min: 1, max: 100, divisions: 99,
                        onChanged: (v) => setState(() => _maxTradesPerDay = v.toInt()),
                      ),
                    ),
                    Text('$_maxTradesPerDay'),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _saveSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('حفظ'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alking Pro'),
        centerTitle: true,
        actions: [
          if (_isLoggedIn) IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsPanel),
        ],
      ),
      body: _isLoggedIn
          ? IndexedStack(
              index: _currentTab,
              children: [
                WebViewWidget(controller: _webViewController),
                _buildReportsTab(),
              ],
            )
          : _buildLoginScreen(),
      bottomNavigationBar: _isLoggedIn
          ? BottomNavigationBar(
              currentIndex: _currentTab,
              onTap: (index) => setState(() => _currentTab = index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'تداول'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
              ],
            )
          : null,
      floatingActionButton: _isLoggedIn && _currentTab == 1
          ? FloatingActionButton(
              onPressed: _toggleBot,
              backgroundColor: _botActive ? Colors.red : Colors.green,
              child: Icon(_botActive ? Icons.stop : Icons.play_arrow),
            )
          : null,
    );
  }

  Widget _buildLoginScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text('تسجيل الدخول إلى Quotex', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة السر', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _login,
              icon: const Icon(Icons.login),
              label: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    final remainingTarget = _targetTrades - (_totalTrades % _targetTrades);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('الحالة:'), Text(_botActive ? 'نشط ✅' : 'غير نشط')]),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('صفقات اليوم:'), Text('$_todayTrades / $_maxTradesPerDay')]),
                  if (_botActive) ...[
                    const SizedBox(height: 5),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const Text('المتبقي:'), Text('$remainingTarget / $_targetTrades')]),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Text('الزوج: $_selectedPair'),
                        Text('المبلغ: ${_isPercentage ? "2%" : "${_amountController.text} دولار"}'),
                        Text('المدة: $_selectedDuration دقيقة'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.history, size: 20),
              const SizedBox(width: 8),
              const Text('سجل الصفقات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _tradeLog.clear();
                    _todayTrades = 0;
                  });
                  _saveTradeLog();
                },
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('مسح الكل'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _tradeLog.isEmpty
                ? const Center(child: Text('لا توجد صفقات بعد'))
                : ListView.builder(
                    itemCount: _tradeLog.length,
                    itemBuilder: (context, index) {
                      final trade = _tradeLog[index];
                      return ListTile(
                        leading: Icon(
                          trade['result'] == 'فوز 🟢' ? Icons.arrow_upward : Icons.arrow_downward,
                          color: trade['result'] == 'فوز 🟢' ? Colors.green : Colors.red,
                        ),
                        title: Text('${trade['pair']} - ${trade['result']}'),
                        subtitle: Text('${trade['amount']} دولار | ${trade['duration']} دقيقة'),
                        trailing: Text(trade['time']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
