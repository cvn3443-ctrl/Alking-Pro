import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- متغيرات الحالة والإعدادات ---
  bool _botActive = false;
  int _todayTrades = 0;          // عدد الصفقات المنفذة اليوم
  int _maxTradesPerDay = 50;     // الحد الأقصى للصفقات في اليوم
  int _sleepSeconds = 180;        // وقت الانتظار بين الصفقات (بالثواني)
  
  // إعدادات البوت
  String _selectedPair = 'EUR/USD';
  final TextEditingController _amountController = TextEditingController(text: '10');
  String _selectedDuration = '5';
  String _selectedAccount = 'تجريبي';
  bool _isPercentage = false;
  
  // قائمة العملات المتاحة
  final List<String> _availableAssets = [
    'EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'BTC/USD',
    'ETH/USD', 'XAU/USD', 'EUR/GBP', 'USD/CAD', 'NZD/USD'
  ];

  // --- سجل الصفقات (قائمة) ---
  List<Map<String, dynamic>> _tradeLog = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadTradeLog(); // تحميل سجل الصفقات من التخزين المحلي
  }

  // --- تحميل وحفظ الإعدادات وسجل الصفقات ---
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pair', _selectedPair);
    await prefs.setString('amount', _amountController.text);
    await prefs.setString('duration', _selectedDuration);
    await prefs.setString('account', _selectedAccount);
    await prefs.setBool('isPercentage', _isPercentage);
    await prefs.setInt('maxTradesPerDay', _maxTradesPerDay);
    await prefs.setInt('sleepSeconds', _sleepSeconds);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات ✅')),
      );
      _updateUIDisplay(); // تحديث الواجهة لعرض القيم الجديدة
    }
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
      _sleepSeconds = prefs.getInt('sleepSeconds') ?? 180;
    });
  }

  Future<void> _loadTradeLog() async {
    final prefs = await SharedPreferences.getInstance();
    final String? logString = prefs.getString('tradeLog');
    if (logString != null) {
      // تحويل النص المخزن إلى قائمة (تنبيه: هذا مثال بسيط، استخدم jsonEncode لبيانات حقيقية)
      setState(() {
        _tradeLog = [];
      });
    }
    // حساب عدد صفقات اليوم من الـ log
    _todayTrades = _tradeLog.length;
  }

  Future<void> _saveTradeLog() async {
    final prefs = await SharedPreferences.getInstance();
    // تبسيطاً: سنخزن عدد الصفقات فقط. للإصدار المتقدم، استخدم jsonEncode.
    await prefs.setInt('todayTrades', _todayTrades);
  }

  // --- وظائف إدارة البوت وسجل الصفقات ---
  void _addTrade(String pair, String result, double amount, String duration) {
    setState(() {
      _tradeLog.insert(0, {
        'pair': pair,
        'result': result,
        'amount': amount,
        'duration': duration,
        'time': DateTime.now().toString().substring(11, 16), // HH:MM
      });
      _todayTrades++;
    });
    _saveTradeLog();
  }

  void _updateUIDisplay() {
    setState(() {}); // تحديث الواجهة لإظهار الإعدادات الجديدة
  }

  void _toggleBot() async {
    if (_botActive) {
      setState(() => _botActive = false);
      return;
    }
    
    // التحقق من عدد الصفقات المسموح بها
    if (_todayTrades >= _maxTradesPerDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم الوصول للحد الأقصى للصفقات اليوم (${_maxTradesPerDay} صفقة)')),
      );
      return;
    }

    setState(() => _botActive = true);
    await _saveSettings();
    
    // محاكاة الصفقة (للاختبار)
    Future.delayed(const Duration(seconds: 2), () {
      if (_botActive) {
        final amount = _isPercentage ? 0.0 : double.parse(_amountController.text);
        _addTrade(_selectedPair, 'فوز 🟢', amount, _selectedDuration);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم تنفيذ صفقة وهمية بقيمة ${amount.toStringAsFixed(2)} دولار')),
        );
        setState(() => _botActive = false); // إيقاف البوت بعد الصفقة
      }
    });
  }

  // --- واجهة المستخدم ---
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

                  // الحد الأقصى للصفقات اليومية
                  Row(
                    children: [
                      const Text('الحد الأقصى للصفقات:'),
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
                  const SizedBox(height: 5),

                  // وقت الانتظار بين الصفقات (بالثواني)
                  Row(
                    children: [
                      const Text('الانتظار بين الصفقات:'),
                      Expanded(
                        child: Slider(
                          value: _sleepSeconds.toDouble(),
                          min: 60,
                          max: 600,
                          divisions: 10,
                          label: '${(_sleepSeconds / 60).toStringAsFixed(0)} دقيقة',
                          onChanged: (v) => setState(() => _sleepSeconds = v.toInt()),
                        ),
                      ),
                      Text('${(_sleepSeconds / 60).toStringAsFixed(0)} دقيقة'),
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
    final remainingTrades = _maxTradesPerDay - _todayTrades;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alking Pro'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateUIDisplay,
            tooltip: 'تحديث الواجهة',
          ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- بطاقة الحالة والإعدادات الحالية ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الحالة:', style: TextStyle(fontSize: 18)),
                        Text(
                          _botActive ? 'نشط ✅' : 'غير نشط ⏹️',
                          style: TextStyle(fontSize: 18, color: _botActive ? Colors.green : Colors.grey),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الزوج:'),
                        Text(_selectedPair),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ:'),
                        Text(_isPercentage ? "2%" : "${_amountController.text} دولار"),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المدة:'),
                        Text("$_selectedDuration دقيقة"),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الحساب:'),
                        Text(_selectedAccount),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الصفقات المتبقية اليوم:'),
                        Text('$remainingTrades / $_maxTradesPerDay'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- سجل الصفقات ---
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
                          subtitle: Text('المبلغ: ${trade['amount']} دولار | المدة: ${trade['duration']} دقيقة'),
                          trailing: Text(trade['time']),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
