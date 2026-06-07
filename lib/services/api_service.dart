import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://vgkmvf.pythonanywhere.com';

  // ============= التحقق من كود التفعيل =============
  static Future<Map<String, dynamic>> verifyLicense(
    String licenseKey,
    String email,
    String deviceId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/verify_license'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'license_key': licenseKey,
          'email': email,
          'device_id': deviceId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل الاتصال'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  // ============= تسجيل الدخول (محاكاة) =============
  static Future<Map<String, dynamic>> loginToQuotex(
    String email,
    String password,
    String license,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    return {'success': true, 'message': 'تم تسجيل الدخول بنجاح'};
  }

  // ============= جلب العملات (قائمة ثابتة) =============
  static Future<List<String>> getAssets(String licenseKey) async {
    return [
      'EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'USD/CAD',
      'NZD/USD', 'USD/CHF', 'BTC/USD', 'ETH/USD', 'XAU/USD',
      'EUR/GBP', 'EUR/JPY', 'GBP/JPY', 'AUD/JPY', 'EUR/AUD'
    ];
  }

  // ============= تحليل السوق (RSI + MACD + BB) =============
  static Future<Map<String, dynamic>> analyzeMarket(List<double> prices) {
    if (prices.length < 50) {
      return Future.value({'signal': 'HOLD', 'confidence': 0});
    }
    
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
      return Future.value({'signal': 'BUY', 'confidence': 85});
    }
    // إشارة بيع قوية (4 شروط)
    if (rsi > 75 && macdBearish && atUpper) {
      return Future.value({'signal': 'SELL', 'confidence': 85});
    }
    // إشارة شراء متوسطة
    if (rsi < 30 && macdBullish) {
      return Future.value({'signal': 'BUY', 'confidence': 70});
    }
    // إشارة بيع متوسطة
    if (rsi > 70 && macdBearish) {
      return Future.value({'signal': 'SELL', 'confidence': 70});
    }
    return Future.value({'signal': 'HOLD', 'confidence': 0});
  }

  // جلب بيانات الشموع من WebView (سيتم تنفيذها في home_screen)
  static List<double> parseCandlesFromPriceHistory(List<dynamic> candles) {
    List<double> prices = [];
    for (var candle in candles) {
      if (candle['close'] != null) {
        prices.add(candle['close'].toDouble());
      }
    }
    return prices;
  }

  // ============= دوال التحليل الفني =============
  
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
    double variance = prices.sublist(prices.length - period).map((p) => (p - sma) * (p - sma)).reduce((a, b) => a + b) / period;
    double std = variance.sqrt();
    double lowerBand = sma - (stdDev * std);
    double upperBand = sma + (stdDev * std);
    
    return {'atLower': prices.last <= lowerBand, 'atUpper': prices.last >= upperBand};
  }
}
