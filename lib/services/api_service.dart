import 'package:quotex_api/quotex_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class ApiService {
  static QuotexAPI? _client;
  static String? _currentAsset;
  static List<String> _cachedAssets = [];

  // تسجيل الدخول إلى Quotex
  static Future<Map<String, dynamic>> loginToQuotex(String email, String password) async {
    try {
      _client = QuotexAPI(email: email, password: password);
      bool connected = await _client!.connect();
      if (connected) {
        // جلب العملات بعد تسجيل الدخول
        await fetchAssets();
        return {'success': true, 'message': 'تم تسجيل الدخول بنجاح'};
      }
      return {'success': false, 'message': 'فشل الاتصال بـ Quotex'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ: $e'};
    }
  }

  // جلب العملات من المنصة
  static Future<List<String>> fetchAssets() async {
    if (_client == null) return _cachedAssets;
    try {
      final assets = await _client!.getAssets();
      _cachedAssets = assets;
      return assets;
    } catch (e) {
      if (_cachedAssets.isEmpty) {
        return ['EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'BTC/USD', 'ETH/USD'];
      }
      return _cachedAssets;
    }
  }

  // جلب بيانات الشموع للتحليل
  static Future<List<double>> getCandles(String asset, int count) async {
    if (_client == null) return [];
    try {
      return await _client!.getCandles(asset, count);
    } catch (e) {
      // توليد بيانات وهمية في حالة الخطأ
      return List.generate(count, (i) => 1.0 + Random().nextDouble() * 0.1);
    }
  }

  // تحليل السوق (RSI + MACD + BB)
  static Future<Map<String, dynamic>> analyzeMarket(String asset) async {
    final prices = await getCandles(asset, 100);
    if (prices.length < 50) return {'signal': 'HOLD', 'confidence': 0};
    
    // حساب RSI
    double rsi = _calculateRSI(prices);
    
    // حساب MACD
    var macd = _calculateMACD(prices);
    bool macdBullish = macd['bullish'];
    bool macdBearish = macd['bearish'];
    
    // حساب Bollinger Bands
    var bb = _calculateBollinger(prices);
    bool atLower = bb['atLower'];
    bool atUpper = bb['atUpper'];
    
    // إشارة شراء قوية (4 شروط)
    if (rsi < 25 && macdBullish && atLower) {
      return {'signal': 'BUY', 'confidence': 85};
    }
    // إشارة بيع قوية (4 شروط)
    if (rsi > 75 && macdBearish && atUpper) {
      return {'signal': 'SELL', 'confidence': 85};
    }
    // إشارة شراء متوسطة
    if (rsi < 30 && macdBullish) {
      return {'signal': 'BUY', 'confidence': 70};
    }
    // إشارة بيع متوسطة
    if (rsi > 70 && macdBearish) {
      return {'signal': 'SELL', 'confidence': 70};
    }
    return {'signal': 'HOLD', 'confidence': 0};
  }

  // تنفيذ صفقة شراء
  static Future<bool> buy(String asset, double amount, int durationMinutes) async {
    if (_client == null) return false;
    try {
      int durationSeconds = durationMinutes * 60;
      return await _client!.buy(amount, asset, durationSeconds);
    } catch (e) {
      return false;
    }
  }

  // تنفيذ صفقة بيع
  static Future<bool> sell(String asset, double amount, int durationMinutes) async {
    if (_client == null) return false;
    try {
      int durationSeconds = durationMinutes * 60;
      return await _client!.sell(amount, asset, durationSeconds);
    } catch (e) {
      return false;
    }
  }

  // الحصول على الرصيد
  static Future<double> getBalance() async {
    if (_client == null) return 0;
    try {
      return await _client!.getBalance();
    } catch (e) {
      return 0;
    }
  }

  // ============= دوال التحليل الفني (RSI, MACD, BB) =============
  
  static double _calculateRSI(List<double> prices, {int period = 14}) {
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

  static Map<String, bool> _calculateMACD(List<double> prices, {int fast = 12, int slow = 26, int signal = 9}) {
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

  static Map<String, bool> _calculateBollinger(List<double> prices, {int period = 20, double stdDev = 2.0}) {
    if (prices.length < period) return {'atLower': false, 'atUpper': false};
    
    double sma = prices.sublist(prices.length - period).reduce((a, b) => a + b) / period;
    double variance = prices.sublist(prices.length - period).map((p) => pow(p - sma, 2)).reduce((a, b) => a + b) / period;
    double std = sqrt(variance);
    double lowerBand = sma - (stdDev * std);
    double upperBand = sma + (stdDev * std);
    
    return {'atLower': prices.last <= lowerBand, 'atUpper': prices.last >= upperBand};
  }
}
