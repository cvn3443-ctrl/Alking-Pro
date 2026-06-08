import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000';

  // تسجيل الدخول
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'message': 'فشل الاتصال بالسيرفر'};
    } catch (e) {
      return {'status': 'error', 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // بدء التداول
  static Future<Map<String, dynamic>> startTrading({
    required String pair,
    required double amount,
    required int duration,
    required String accountType,
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
          'account_type': accountType,
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

  // إيقاف التداول
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

  // جلب حالة البوت
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/status'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'active': false, 'total_trades': 0, 'win_streak': 0, 'loss_streak': 0};
    } catch (e) {
      return {'active': false, 'total_trades': 0, 'win_streak': 0, 'loss_streak': 0};
    }
  }

  // جلب العملات أون لاين
  static Future<List<String>> getAssets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/assets'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['assets'] != null && data['assets'].isNotEmpty) {
          return List<String>.from(data['assets']);
        }
      }
      return ['EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'BTC/USD', 'ETH/USD', 'XAU/USD'];
    } catch (e) {
      return ['EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'BTC/USD', 'ETH/USD', 'XAU/USD'];
    }
  }
}
