import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://alking-pro-trading-server-3.onrender.com';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200 || response.statusCode == 401) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالسيرفر: $e'};
    }
  }

  Future<Map<String, dynamic>> getSymbols() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/symbols'));
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
      );
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
      );
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
      final response = await http.get(Uri.parse('$baseUrl/api/status'));
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
