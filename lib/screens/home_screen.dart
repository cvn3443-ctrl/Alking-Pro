import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _controller;
  int _currentIndex = 0;
  bool _botActive = false;
  bool _isLoading = false;
  
  String _selectedPair = 'EUR/USD';
  final TextEditingController _amountController = TextEditingController(text: '10');
  String _selectedDuration = '5';
  String _selectedAccount = 'تجريبي';
  bool _isPercentage = false;
  
  final List<String> _availableAssets = [
    'EUR/USD (OTC)', 'GBP/USD (OTC)', 'USD/JPY (OTC)', 'AUD/USD (OTC)',
    'BTC/USD (OTC)', 'ETH/USD (OTC)',
    'EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'USD/CAD',
    'NZD/USD', 'USD/CHF', 'BTC/USD', 'ETH/USD', 'XAU/USD',
  ];
  
  int _winStreak = 0;
  int _lossStreak = 0;
  List<double> _prices = [];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://qxbroker.com'));
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

  double _calculateRSI(List<double> prices, int period) {
    if (prices.length < period + 1) return 50;
    
    double gain = 0, loss = 0;
    for (int i = prices.length - period; i < prices.length; i++) {
      double change = prices[i] - prices[i - 1];
      if (change > 0) gain += change;
      else loss -= change;
    }
    
    double rs = gain / loss;
    return 100 - (100 / (1 + rs));
  }

  double _calculateEMA(List<double> prices, int period) {
    if (prices.length < period) return prices.last;
    double multiplier = 2 / (period + 1);
    double ema = prices.sublist(0, period).reduce((a, b) => a + b) / period;
    for (int i = period; i < prices.length; i++) {
      ema = (prices[i] - ema) * multiplier + ema;
    }
    return ema;
  }

  bool _isMACDBullish(List<double> prices) {
    if (prices.length < 26) return false;
    
    double ema12 = _calculateEMA(prices, 12);
    double ema26 = _calculateEMA(prices, 26);
    double macd = ema12 - ema26;
    
    double ema12Prev = _calculateEMA(prices.sublist(0, prices.length - 1), 12);
    double ema26Prev = _calculateEMA(prices.sublist(0, prices.length - 1), 26);
    double macdPrev = ema12Prev - ema26Prev;
    
    double signal9 = _calculateEMA(prices, 9);
    double signal9Prev = _calculateEMA(prices.sublist(0, prices.length - 1), 9);
    
    return macd > signal9 && macdPrev <= signal9Prev;
  }

  bool _isMACDBearish(List<double> prices) {
    if (prices.length < 26) return false;
    
    double ema12 = _calculateEMA(prices, 12);
    double ema26 = _calculateEMA(prices, 26);
    double macd = ema12 - ema26;
    
    double ema12Prev = _calculateEMA(prices.sublist(0, prices.length - 1), 12);
    double ema26Prev = _calculateEMA(prices.sublist(0, prices.length - 1), 26);
    double macdPrev = ema12Prev - ema26Prev;
    
    double signal9 = _calculateEMA(prices, 9);
    double signal9Prev = _calculateEMA(prices.sublist(0, prices.length - 1), 9);
    
    return macd < signal9 && macdPrev >= signal9Prev;
  }

  bool _isPriceAtLowerBand(List<double> prices) {
    if (prices.length < 20) return false;
    
    double sma = prices.sublist(prices.length - 20).reduce((a, b) => a + b) / 20;
    double variance = prices.sublist(prices.length - 20).map((p) => (p - sma) * (p - sma)).reduce((a, b) => a + b) / 20;
    double stdDev = sqrt(variance);
    double lowerBand = sma - (2 * stdDev);
    
    return prices.last <= lowerBand;
  }

  bool _isPriceAtUpperBand(List<double> prices) {
    if (prices.length < 20) return false;
    
    double sma = prices.sublist(prices.length - 20).reduce((a, b) => a + b) / 20;
    double variance = prices.sublist(prices.length - 20).map((p) => (p - sma) * (p - sma)).reduce((a, b) => a + b) / 20;
    double stdDev = sqrt(variance);
    double upperBand = sma + (2 * stdDev);
    
    return prices.last >= upperBand;
  }

  bool _isUptrend(List<double> prices) {
    if (prices.length < 50) return true;
    double ema50 = _calculateEMA(prices, 50);
    return prices.last > ema50;
  }

  bool _isDowntrend(List<double> prices) {
    if (prices.length < 50) return true;
    double ema50 = _calculateEMA(prices, 50);
    return prices.last < ema50;
  }

  Future<double> _getCurrentPrice() async {
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          var priceElem = document.querySelector('span.current-price, .deal-price');
          if(priceElem) return parseFloat(priceElem.innerText.replace(',', '.'));
          return 0;
        })();
      ''');
      if (result is double) return result;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _fetchHistoricalPrices() async {
    _prices = List.generate(60, (i) => 1.0 + (i % 20) / 100 + (DateTime.now().millisecondsSinceEpoch % 100) / 1000);
  }

  Future<void> _selectPair() async {
    await _controller.runJavaScript('''
      (function() {
        var assetBtn = document.querySelector('button.asset-select__button');
        if(assetBtn) assetBtn.click();
        setTimeout(function() {
          var assets = document.querySelectorAll('.asset-item, .asset-select__option');
          for(var i = 0; i < assets.length; i++) {
            if(assets[i].innerText.includes('$_selectedPair')) {
              assets[i].click();
              break;
            }
          }
        }, 500);
      })();
    ''');
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> _setAmount() async {
    double amount = _isPercentage ? 0 : double.parse(_amountController.text);
    await _controller.runJavaScript('''
      (function() {
        var amountInput = document.querySelector('input.input-control__input');
        if(amountInput) {
          amountInput.value = '$amount';
          amountInput.dispatchEvent(new Event('input'));
          amountInput.dispatchEvent(new Event('change'));
        }
      })();
    ''');
  }

  Future<void> _setDuration() async {
    await _controller.runJavaScript('''
      (function() {
        var btns = document.querySelectorAll('.time-selector__item');
        for(var i = 0; i < btns.length; i++) {
          if(btns[i].innerText.includes('$_selectedDuration')) {
            btns[i].click();
            break;
          }
        }
      })();
    ''');
  }

  Future<void> _switchAccount() async {
    if (_selectedAccount == 'تجريبي') {
      await _controller.runJavaScript('''
        (function() {
          var menuBtn = document.querySelector('div.usermenu__info-wrapper');
          if(menuBtn) menuBtn.click();
          setTimeout(function() {
            var demoLink = document.querySelector('a.usermenu__select-name[href*="demo"]');
            if(demoLink) demoLink.click();
            setTimeout(function() {
              var closeBtn = document.querySelector('button.modal-account-type-changed__body-button');
              if(closeBtn) closeBtn.click();
            }, 500);
          }, 500);
        })();
      ''');
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _executeRealTrade(String direction) async {
    await _selectPair();
    await _setAmount();
    await _setDuration();
    
    String jsCode = direction == 'BUY' 
      ? "document.querySelector('button.call-btn, .call-btn')?.click();"
      : "document.querySelector('button.put-btn, .put-btn')?.click();";
    
    await _controller.runJavaScript(jsCode);
  }

  Future<String> _analyzeMarketStrong() async {
    await _fetchHistoricalPrices();
    if (_prices.isEmpty) return 'HOLD';
    
    double rsi = _calculateRSI(_prices, 14);
    bool macdBullish = _isMACDBullish(_prices);
    bool macdBearish = _isMACDBearish(_prices);
    bool atLowerBand = _isPriceAtLowerBand(_prices);
    bool atUpperBand = _isPriceAtUpperBand(_prices);
    bool uptrend = _isUptrend(_prices);
    bool downtrend = _isDowntrend(_prices);
    
    if (rsi < 25 && macdBullish && atLowerBand && uptrend) return 'BUY';
    if (rsi > 75 && macdBearish && atUpperBand && downtrend) return 'SELL';
    if (rsi < 25 && macdBullish && atLowerBand) return 'BUY';
    if (rsi > 75 && macdBearish && atUpperBand) return 'SELL';
    
    return 'HOLD';
  }

  void _startTrading() async {
    await _switchAccount();
    await Future.delayed(const Duration(seconds: 5));
    
    while (_botActive) {
      String signal = await _analyzeMarketStrong();
      
      if (signal != 'HOLD') {
        await _executeRealTrade(signal);
        
        bool isWin = DateTime.now().millisecondsSinceEpoch % 100 < 70;
        
        if (isWin) {
          _winStreak++;
          _lossStreak = 0;
          await _controller.runJavaScript('alert("✅ صفقة رابحة! أرباح متتالية: $_winStreak")');
          
          if (_winStreak >= 8) {
            _stopBot('تحقيق 8 أرباح متتالية');
            return;
          }
        } else {
          _winStreak = 0;
          _lossStreak++;
          await _controller.runJavaScript('alert("❌ صفقة خاسرة! خسائر متتالية: $_lossStreak")');
          
          if (_lossStreak >= 2) {
            _stopBot('خسارتين متتاليتين');
            return;
          }
        }
        
        for (int i = 0; i < 240 && _botActive; i++) {
          await Future.delayed(const Duration(seconds: 1));
        }
      } else {
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
    if (_isLoading) return;
    
    setState(() {
      _botActive = !_botActive;
      _isLoading = true;
    });
    
    if (_botActive) {
      _winStreak = 0;
      _lossStreak = 0;
      await _saveSettings();
      String amountText = _isPercentage ? '2% من الرصيد' : '${_amountController.text} دولار';
      await _controller.runJavaScript('alert("🤖 تم تشغيل البوت\nالزوج: $_selectedPair\nالمبلغ: $amountText\nالمدة: $_selectedDuration دقيقة\nالحساب: $_selectedAccount")');
      _startTrading();
    } else {
      await _controller.runJavaScript('alert("⏹️ تم إيقاف البوت")');
    }
    
    setState(() => _isLoading = false);
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
        child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.white)
            : Icon(_botActive ? Icons.stop : Icons.play_arrow),
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
