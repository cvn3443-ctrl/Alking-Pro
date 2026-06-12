import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

class QuotexAPI {
  static const String wsUrl = 'wss://ws.quotex.io/';
  WebSocketChannel? _channel;
  String? _ssid;
  String? _accountType = 'demo';

  Future<bool> loginWithSSID(String ssid) async {
    _ssid = ssid;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.sink.add(jsonEncode({
        'action': 'ssid_auth',
        'ssid': _ssid,
      }));
      await Future.delayed(Duration(seconds: 2));
      return true;
    } catch (e) {
      print('❌ خطأ في الاتصال: $e');
      return false;
    }
  }

  Future<List<String>> getAssets() async {
    // مؤقتاً قائمة ثابتة حتى نربط API جلب العملات
    return ['EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'BTC/USD', 'ETH/USD', 'XAU/USD'];
  }

  Future<double> getBalance() async {
    // مؤقتاً قيمة ثابتة (سنربطها لاحقاً)
    return 10000.0;
  }

  Future<bool> switchAccount(String type) async {
    _accountType = type;
    print('🔄 تم تبديل الحساب إلى: $type');
    return true;
  }

  Future<bool> buy(String pair, double amount, int duration) async {
    _channel!.sink.add(jsonEncode({
      'action': 'buy',
      'pair': pair,
      'amount': amount,
      'duration': duration,
      'account_type': _accountType,
    }));
    return true;
  }

  Future<bool> sell(String pair, double amount, int duration) async {
    _channel!.sink.add(jsonEncode({
      'action': 'sell',
      'pair': pair,
      'amount': amount,
      'duration': duration,
      'account_type': _accountType,
    }));
    return true;
  }

  // دوال التحليل الفني (RSI, MACD, BB)
  double calculateRSI(List<double> prices, {int period = 14}) {
    if (prices.length < period + 1) return 50;
    double gain = 0, loss = 0;
    for (int i = prices.length - period; i < prices.length; i++) {
      double change = prices[i] - prices[i - 1];
      if (change > 0) gain += change;
      else loss -= change;
    }
    if (loss == 0) return 100;
    double rs = gain / loss;
    return 100 - (100 / (1 + rs));
  }

  Map<String, bool> calculateMACD(List<double> prices, {int fast = 12, int slow = 26, int signal = 9}) {
    if (prices.length < slow) return {'bullish': false, 'bearish': false};
    double _ema(List<double> data, int period) {
      if (data.length < period) return data.last;
      double multiplier = 2 / (period + 1);
      double ema = data.sublist(0, period).reduce((a, b) => a + b) / period;
      for (int i = period; i < data.length; i++) {
        ema = (data[i] - ema) * multiplier + ema;
      }
      return ema;
    }
    double emaFast = _ema(prices, fast);
    double emaSlow = _ema(prices, slow);
    double macdLine = emaFast - emaSlow;
    double emaFastPrev = _ema(prices.sublist(0, prices.length - 1), fast);
    double emaSlowPrev = _ema(prices.sublist(0, prices.length - 1), slow);
    double macdPrev = emaFastPrev - emaSlowPrev;
    double signalLine = _ema(prices, signal);
    double signalPrev = _ema(prices.sublist(0, prices.length - 1), signal);
    bool bullish = macdLine > signalLine && macdPrev <= signalPrev;
    bool bearish = macdLine < signalLine && macdPrev >= signalPrev;
    return {'bullish': bullish, 'bearish': bearish};
  }

  Map<String, bool> calculateBollinger(List<double> prices, {int period = 20, double stdDev = 2.0}) {
    if (prices.length < period) return {'atLower': false, 'atUpper': false};
    double sma = prices.sublist(prices.length - period).reduce((a, b) => a + b) / period;
    double variance = prices.sublist(prices.length - period).map((p) => (p - sma) * (p - sma)).reduce((a, b) => a + b) / period;
    double std = sqrt(variance);
    double lowerBand = sma - (stdDev * std);
    double upperBand = sma + (stdDev * std);
    return {'atLower': prices.last <= lowerBand, 'atUpper': prices.last >= upperBand};
  }

  Map<String, dynamic> analyzeMarket(List<double> prices) {
    if (prices.length < 50) return {'signal': 'HOLD', 'confidence': 0};
    double rsi = calculateRSI(prices);
    var macd = calculateMACD(prices);
    var bb = calculateBollinger(prices);
    if (rsi < 25 && macd['bullish']! && bb['atLower']!) return {'signal': 'BUY', 'confidence': 85};
    if (rsi > 75 && macd['bearish']! && bb['atUpper']!) return {'signal': 'SELL', 'confidence': 85};
    if (rsi < 30 && macd['bullish']!) return {'signal': 'BUY', 'confidence': 70};
    if (rsi > 70 && macd['bearish']!) return {'signal': 'SELL', 'confidence': 70};
    return {'signal': 'HOLD', 'confidence': 0};
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
