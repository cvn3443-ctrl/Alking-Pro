import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _botActive = false;
  
  String _selectedPair = 'EUR/USD';
  final TextEditingController _amountController = TextEditingController(text: '10');
  String _selectedDuration = '5';
  String _selectedAccount = 'تجريبي';
  bool _isPercentage = false;
  
  final List<String> _availableAssets = [
    'EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'BTC/USD'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pair', _selectedPair);
    await prefs.setString('amount', _amountController.text);
    await prefs.setString('duration', _selectedDuration);
    await prefs.setString('account', _selectedAccount);
    await prefs.setBool('isPercentage', _isPercentage);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات ✅')),
      );
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
    });
  }

  void _toggleBot() {
    setState(() {
      _botActive = !_botActive;
      if (_botActive) {
        _saveSettings();
      }
    });
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
                  
                  DropdownButtonFormField<String>(
                    value: _selectedDuration,
                    items: ['1', '5', '15']
                        .map((e) => DropdownMenuItem(value: e, child: Text('$e دقيقة'))).toList(),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.trending_up, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Alking Pro',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'الحالة: ${_botActive ? "نشط ✅" : "غير نشط ⏹️"}',
              style: TextStyle(fontSize: 18, color: _botActive ? Colors.green : Colors.grey),
            ),
            const SizedBox(height: 30),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('الزوج: $_selectedPair', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Text('المبلغ: ${_isPercentage ? "2%" : "${_amountController.text} دولار"}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Text('المدة: $_selectedDuration دقيقة', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Text('الحساب: $_selectedAccount', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
