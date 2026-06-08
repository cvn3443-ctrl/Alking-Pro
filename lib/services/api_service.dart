import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // 🔥 الرابط السحري الذي يعمل على أي هاتف Android
  static const String baseUrl = 'http://10.0.2.2:5000';

  // 1. تسجيل الدخول
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🌐 محاولة الاتصال بـ: $baseUrl');
      print('📧 الإيميل: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      
      print('✅ الرد من السيرفر: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'message': 'فشل الاتصال بالسيرفر'};
    } catch (e) {
      print('❌ خطأ في الاتصال: $e');
      return {'status': 'error', 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // 2. بدء التداول
  static Future<Map<String, dynamic>> startTrading({
    required String pair,
    required double amount,
    required int duration,
    required int targetTrades,
    required int maxTradesPerDay,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pair': pair,
          'amount': amount,
          'duration': duration,
          'target_trades': targetTrades,
          'max_trades_per_day': maxTradesPerDay,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'message': 'فشل بدء التداول'};
    } catch (e) {
      return {'status': 'error', 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // 3. إيقاف التداول
  static Future<Map<String, dynamic>> stopTrading() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/stop'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'message': 'فشل إيقاف التداول'};
    } catch (e) {
      return {'status': 'error', 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // 4. جلب حالة البوت
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/status'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'active': false};
    } catch (e) {
      return {'active': false};
    }
  }

  // 5. جلب العملات المتاحة
  static Future<List<String>> getAssets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/assets'));
      final data = jsonDecode(response.body);
      return List<String>.from(data['assets']);
    } catch (e) {
      return ['EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'BTC/USD'];
    }
  }
}
