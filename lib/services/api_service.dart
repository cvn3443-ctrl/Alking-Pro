import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // 🔥 رابط السيرفر على Render (عدله إذا تغير)
  static const String baseUrl = 'https://alking-server-3.onrender.com';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'فشل الاتصال بالسيرفر'};
    }
  }

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
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'فشل بدء التداول'};
    }
  }

  static Future<Map<String, dynamic>> stopTrading() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/stop'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'فشل إيقاف التداول'};
    }
  }

  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/status'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'active': false};
    }
  }

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
