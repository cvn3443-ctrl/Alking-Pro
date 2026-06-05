import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // 🔥 غير هذا الرابط بعد ما تجهز السيرفر
  static const String baseUrl = 'https://your-server.com/api';

  // تسجيل الدخول
  static Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ssid'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // تنفيذ صفقة
  static Future<bool> executeTrade({
    required String ssid,
    required String action,
    required String pair,
    required double amount,
    required int duration,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trade'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ssid': ssid,
          'action': action,
          'pair': pair,
          'amount': amount,
          'duration': duration,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // جلب الرصيد
  static Future<double> getBalance(String ssid) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/balance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ssid': ssid}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['balance'] ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // جلب العملات
  static Future<List<String>> getAssets(String ssid) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assets'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ssid': ssid}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['assets']);
      }
      return ['EUR/USD', 'GBP/USD', 'BTC/USD'];
    } catch (e) {
      return ['EUR/USD', 'GBP/USD', 'BTC/USD'];
    }
  }
}
