import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://alking-pro-trading-server-3.onrender.com';

  // دالة جديدة لاختبار الاتصال
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print('✅ Connection test: ${response.statusCode}');
      print('✅ Response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('📤 Sending login request to: $baseUrl/api/login');
      print('📤 Email: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 401) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'خطأ في السيرفر: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'message': 'فشل الاتصال بالسيرفر: $e'};
    }
  }

  Future<Map<String, dynamic>> getSymbols() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/symbols'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'خطأ في جلب العملات: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالسيرفر: $e'};
    }
  }

  Future<Map<String, dynamic>> executeTrade({
    required String symbol,
    required double amount,
    required bool isDemo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/trade/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'symbol': symbol, 'amount': amount, 'is_demo': isDemo}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالسيرفر: $e'};
    }
  }

  Future<Map<String, dynamic>> resetTrading() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/trade/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'confirm': true}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'فشل إعادة التعيين: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالسيرفر: $e'};
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/status'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'فشل جلب الحالة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالسيرفر: $e'};
    }
  }
}
