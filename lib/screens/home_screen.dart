import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  int _step = 1;
  String? _deviceId;
  int _selectedTab = 0;
  
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _currentLicense;
  String? _verifiedEmail;
  
  bool _botActive = false;
  int _todayTrades = 0;
  int _maxTradesPerDay = 50;
  int _targetTrades = 5;
  int _completedTrades = 0;
  int _lossCount = 0;
  int _winCount = 0;
  
  String _selectedPair = 'EUR/USD';
  final TextEditingController _amountController = TextEditingController(text: '10');
  String _selectedDuration = '5';
  String _selectedAccount = 'تجريبي';
  bool _isPercentage = false;
  
  List<String> _availableAssets = [
    'EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'BTC/USD',
    'ETH/USD', 'XAU/USD', 'EUR/GBP', 'USD/CAD', 'NZD/USD'
  ];
  
  List<Map<String, dynamic>> _tradeLog = [];
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadTradeLog();
    _getDeviceId();
    _checkSavedState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://qxbroker.com'));
  }

  Future<void> _getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    setState(() {
      _deviceId = androidInfo.id;
    });
  }

  Future<void> _checkSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLicense = prefs.getString('license_key');
    final savedEmail = prefs.getString('verified_email');
    
    if (savedLicense != null && savedEmail != null) {
      setState(() {
        _currentLicense = savedLicense;
        _verifiedEmail = savedEmail;
        _step = 3;
        _isLoggedIn = true;
      });
    }
  }

  Future<void> _verifyLicense() async {
    final licenseKey = _licenseController.text.trim();
    final email = _emailController.text.trim();

    if (licenseKey.isEmpty || email.isEmpty) {
      _showSnackbar('الرجاء إدخال كود التفعيل والبريد الإلكتروني');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.verifyLicense(licenseKey, email, _deviceId!);

    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('license_key', licenseKey);
      await prefs.setString('verified_email', email);
      
      setState(() {
        _currentLicense = licenseKey;
        _verifiedEmail = email;
        _step = 2;
        _isLoading = false;
      });
      _showSnackbar('✅ تم التحقق من الكود');
    } else {
      _showSnackbar(result['message'] ?? '❌ فشل التحقق');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginToQuotex() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('الرجاء إدخال البريد الإلكتروني وكلمة السر');
      return;
    }

    if (email != _verifiedEmail) {
      _showSnackbar('❌ البريد الإلكتروني لا يطابق الكود');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.loginToQuotex(email, password);

    if (result['success'] == true) {
      setState(() {
        _step = 3;
        _isLoggedIn = true;
        _isLoading = false;
      });
      _showSnackbar('✅ تم تسجيل الدخول بنجاح');
    } else {
      _showSnackbar(result['message'] ?? '❌ فشل تسجيل الدخول');
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    setState(() {
      _todayTrades = savedTrades ?? 0;
    });
  }

  Future<void> _saveTradeLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('todayTrades', _todayTrades);
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
  }

  void _stopBot(String reason) {
    setState(() {
      _botActive = false;
    });
    _showSnackbar('⏹️ توقف البوت: $reason');
  }

  void _startTrading() async {
    _completedTrades = 0;
    _winCount = 0;
    _lossCount = 0;
    setState(() {});
    
    while (_botActive && _completedTrades < _targetTrades) {
      if (_lossCount >= 2) {
        _stopBot('خسارتين متتاليتين ⚠️');
        return;
      }
      
      if (_winCount >= 5) {
        _stopBot('5 أرباح متتالية 🏆');
        return;
      }
      
      if (_todayTrades >= _maxTradesPerDay) {
        _stopBot('تم الوصول للحد الأقصى اليومي');
        return;
      }
      
      final amount = _isPercentage ? 0.0 : double.parse(_amountController.text);
      _addTrade(_selectedPair, 'فوز 🟢', amount, _selectedDuration);
      
      _completedTrades++;
      _todayTrades++;
      await _saveTradeLog();
      setState(() {});
      
      if (_completedTrades < _targetTrades && _botActive) {
        // ⏰ انتظار عشوائي بين 3 و 5 دقائق
        int waitMinutes = 3 + (DateTime.now().second % 3);
        int waitSeconds = waitMinutes * 60;
        
        _showSnackbar('⏳ انتظار $waitMinutes دقائق قبل الصفقة التالية');
        
        for (int i = 0; i < waitSeconds && _botActive; i++) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    
    if (_botActive && _completedTrades >= _targetTrades) {
      _stopBot('تم $_targetTrades صفقات 🎯');
    }
  }

  void _toggleBot() async {
    if (_botActive) {
      setState(() => _botActive = false);
      return;
    }
    
    if (!_isLoggedIn) {
      _showSnackbar('الرجاء إكمال التفعيل أولاً');
      return;
    }
    
    if (_todayTrades >= _maxTradesPerDay) {
      _showSnackbar('الحد اليومي اكتمل');
      return;
    }

    setState(() => _botActive = true);
    await _saveSettings();
    _startTrading();
  }

  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1a1a1a),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
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
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '$_targetTrades',
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
                      decoration: const InputDecoration(
                        labelText: 'المبلغ الثابت (دولار)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  if (_isPercentage)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('2% من الرصيد', style: TextStyle(color: Colors.green)),
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
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: '$_maxTradesPerDay',
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
                  const SizedBox(height: 20),
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
    final remainingTarget = _targetTrades - _completedTrades;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alking Pro'),
        centerTitle: true,
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsPanel,
            ),
        ],
      ),
      bottomNavigationBar: _isLoggedIn && _step == 3
          ? BottomNavigationBar(
              currentIndex: _selectedTab,
              onTap: (index) => setState(() => _selectedTab = index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'تداول'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
              ],
            )
          : null,
      floatingActionButton: _isLoggedIn && _step == 3 && _selectedTab == 1
          ? FloatingActionButton(
              onPressed: _toggleBot,
              backgroundColor: _botActive ? Colors.red : Colors.green,
              child: Icon(_botActive ? Icons.stop : Icons.play_arrow),
            )
          : null,
      body: _step == 1
          ? _buildStep1()
          : _step == 2
              ? _buildStep2()
              : _selectedTab == 0
                  ? WebViewWidget(controller: _webViewController)
                  : _buildReportsTab(remainingTarget),
    );
  }

  Widget _buildStep1() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vpn_key, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text('الخطوة 1 من 2', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const Text('تفعيل التطبيق', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: _licenseController,
              decoration: const InputDecoration(
                labelText: 'كود التفعيل',
                hintText: 'XXXX-XXXX-XXXX',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني (حساب Quotex)',
                hintText: 'example@email.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyLicense,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('تحقق من الكود', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text('الخطوة 2 من 2', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const Text('تسجيل الدخول إلى Quotex', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة السر',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginToQuotex,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('تسجيل الدخول', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab(int remainingTarget) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // بطاقة الإحصائيات
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الحالة:', style: TextStyle(fontSize: 16)),
                      Text(_botActive ? 'نشط ✅' : 'غير نشط', style: TextStyle(fontSize: 16, color: _botActive ? Colors.green : Colors.grey)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('صفقات اليوم:'),
                      Text('$_todayTrades / $_maxTradesPerDay'),
                    ],
                  ),
                  if (_botActive) ...[
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المتبقي من الهدف:'),
                        Text('$remainingTarget / $_targetTrades'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('أرباح متتالية:'),
                        Text('$_winCount', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('خسائر متتالية:'),
                        Text('$_lossCount', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('الزوج: $_selectedPair', style: const TextStyle(fontSize: 12)),
                        Text('المبلغ: ${_isPercentage ? "2%" : "${_amountController.text} دولار"}', style: const TextStyle(fontSize: 12)),
                        Text('المدة: $_selectedDuration دقيقة', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // سجل الصفقات
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
                    _completedTrades = 0;
                    _winCount = 0;
                    _lossCount = 0;
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
                        subtitle: Text('المبلغ: ${trade['amount']} دولار | المدة: ${trade['duration']} دقيقة'),
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
