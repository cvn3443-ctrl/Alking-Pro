import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // متغيرات البوت
  bool _botActive = false;
  int _todayTrades = 0;
  int _maxTradesPerDay = 50;
  int _targetTrades = 5;      // عدد الصفقات المطلوب (أنت تختاره)
  int _completedTrades = 0;
  int _lossCount = 0;          // عدد الخسائر المتتالية
  int _winCount = 0;           // عدد الأرباح المتتالية
  
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
  
  // متغيرات API
  String? _ssid;
  bool _isLoggedIn = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadTradeLog();
    _loadSsid();
  }

  Future<void> _loadSsid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ssid = prefs.getString('ssid');
      _isLoggedIn = _ssid != null;
    });
  }

  Future<void> _saveSsid(String ssid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ssid', ssid);
    setState(() {
      _ssid = ssid;
      _isLoggedIn = true;
    });
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('أدخل البريد الإلكتروني وكلمة السر');
      return;
    }
    
    setState(() => _isLoggedIn = false);
    
    final ssid = await ApiService.login(email, password);
    if (ssid != null) {
      await _saveSsid(ssid);
      _showSnackbar('✅ تم تسجيل الدخول بنجاح');
      
      final assets = await ApiService.getAssets(ssid);
      setState(() {
        _availableAssets.clear();
        _availableAssets.addAll(assets);
      });
    } else {
      _showSnackbar('❌ فشل تسجيل الدخول');
      setState(() => _isLoggedIn = true);
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

  Future<void> _executeTradeLogic() async {
    if (_ssid == null) return;
    
    final amount = _isPercentage ? 0.0 : double.parse(_amountController.text);
    final duration = int.parse(_selectedDuration);
    
    // 🔥 هنا التحليل (مؤقتاً نستخدم BUY فقط، سيتم إضافة التحليل الحقيقي لاحقاً)
    final action = 'BUY';
    
    final success = await ApiService.executeTrade(
      ssid: _ssid!,
      action: action,
      pair: _selectedPair,
      amount: amount,
      duration: duration,
    );
    
    if (success) {
      _addTrade(_selectedPair, 'فوز 🟢', amount, _selectedDuration);
      _winCount++;
      _lossCount = 0;
    } else {
      _addTrade(_selectedPair, 'خسارة 🔴', amount, _selectedDuration);
      _lossCount++;
      _winCount = 0;
    }
    
    _completedTrades++;
    _todayTrades++;
    await _saveTradeLog();
    setState(() {});
  }

  void _startTrading() async {
    _completedTrades = 0;
    _winCount = 0;
    _lossCount = 0;
    setState(() {});
    
    while (_botActive && _completedTrades < _targetTrades) {
      // شرط الإيقاف: خسارتين متتاليتين
      if (_lossCount >= 2) {
        _stopBot('خسارتين متتاليتين ⚠️');
        return;
      }
      
      // شرط الإيقاف: ربح خمس صفقات متتالية
      if (_winCount >= 5) {
        _stopBot('5 أرباح متتالية 🏆');
        return;
      }
      
      // التحقق من الحد اليومي
      if (_todayTrades >= _maxTradesPerDay) {
        _stopBot('تم الوصول للحد الأقصى اليومي');
        return;
      }
      
      // تنفيذ الصفقة
      await _executeTradeLogic();
      
      // إذا لم تكن آخر صفقة، انتظر وقت عشوائي بين 5-15 دقيقة
      if (_completedTrades < _targetTrades && _botActive) {
        int waitMinutes = 5 + (DateTime.now().second % 11);
        int waitSeconds = waitMinutes * 60;
        
        _showSnackbar('⏳ انتظار $waitMinutes دقيقة قبل الصفقة التالية');
        
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
      _showSnackbar('سجل الدخول أولاً');
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
                  
                  // اختيار الزوج
                  DropdownButtonFormField<String>(
                    value: _selectedPair,
                    items: _availableAssets.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedPair = v!),
                    decoration: const InputDecoration(labelText: 'الزوج'),
                  ),
                  const SizedBox(height: 15),
                  
                  // عدد الصفقات (من 1 إلى 10)
                  Row(
                    children: [
                      const Text('عدد الصفقات:'),
                      Expanded(
                        child: Slider(
                          value: _targetTrades.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '$_targetTrades صفقة',
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
                  
                  // نسبة مئوية / مبلغ ثابت
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
                      child: Text('2% من رصيد الحساب', style: TextStyle(color: Colors.green)),
                    ),
                  const SizedBox(height: 15),
                  
                  // مدة الصفقة
                  DropdownButtonFormField<String>(
                    value: _selectedDuration,
                    items: ['1', '5', '15'].map((e) => DropdownMenuItem(value: e, child: Text('$e دقيقة'))).toList(),
                    onChanged: (v) => setState(() => _selectedDuration = v!),
                    decoration: const InputDecoration(labelText: 'المدة'),
                  ),
                  const SizedBox(height: 15),
                  
                  // نوع الحساب
                  DropdownButtonFormField<String>(
                    value: _selectedAccount,
                    items: ['تجريبي', 'حقيقي'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedAccount = v!),
                    decoration: const InputDecoration(labelText: 'نوع الحساب'),
                  ),
                  const SizedBox(height: 15),

                  // الحد اليومي
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
      body: _isLoggedIn
          ? Row(
              children: [
                // الجزء الأيسر: سجل الصفقات
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.grey[900],
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الحالة:'),
                                  Text(_botActive ? 'نشط ✅' : 'غير نشط', style: TextStyle(color: _botActive ? Colors.green : Colors.grey)),
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
                                    const Text('المتبقي:'),
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
                        const Divider(),
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('سجل الصفقات', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                      label: const Text('مسح'),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _tradeLog.isEmpty
                                    ? const Center(child: Text('لا صفقات بعد'))
                                    : ListView.builder(
                                        itemCount: _tradeLog.length,
                                        itemBuilder: (context, index) {
                                          final trade = _tradeLog[index];
                                          return ListTile(
                                            dense: true,
                                            leading: Icon(
                                              trade['result'] == 'فوز 🟢' ? Icons.arrow_upward : Icons.arrow_downward,
                                              color: trade['result'] == 'فوز 🟢' ? Colors.green : Colors.red,
                                              size: 16,
                                            ),
                                            title: Text('${trade['pair']} - ${trade['result']}', style: const TextStyle(fontSize: 12)),
                                            subtitle: Text('${trade['amount']} \$ | ${trade['duration']} د', style: const TextStyle(fontSize: 10)),
                                            trailing: Text(trade['time'], style: const TextStyle(fontSize: 10)),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // الجزء الأيمن: معلومات API
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.api, size: 80, color: Colors.green),
                        const SizedBox(height: 20),
                        const Text(
                          'API Mode Active',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        const Text('تم تسجيل الدخول بنجاح'),
                        const SizedBox(height: 10),
                        Text('الزوج الحالي: $_selectedPair'),
                        Text('المبلغ: ${_isPercentage ? "2%" : "${_amountController.text} \$"}'),
                        Text('المدة: $_selectedDuration دقيقة'),
                        const SizedBox(height: 20),
                        if (!_botActive)
                          ElevatedButton.icon(
                            onPressed: _toggleBot,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('بدء التداول'),
                          ),
                        if (_botActive)
                          const Text('البوت يعمل...', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text('تسجيل الدخول إلى حساب Quotex', style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة السر',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _login,
                      icon: const Icon(Icons.login),
                      label: const Text('تسجيل الدخول'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
