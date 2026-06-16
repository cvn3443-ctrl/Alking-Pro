import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // رابط السيرفر على Render
  static const String baseUrl = 'https://alking-pro-trading-server-3.onrender.com';

  // ============== تسجيل الدخول ==============
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
        return {
          'success': false,
          'message': 'خطأ في السيرفر: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالسيرفر: $e'};
    }
  }

  // ============== جلب العملات ==============
  Future<Map<String, dynamic>> getSymbols() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/symbols'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'يجب تسجيل الدخول أولاً'};
      } else {
        return {
          'success': false,
          'message': 'خطأ في جلب العملات: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالسيرفر: $e'};
    }
  }

  // ============== تحليل فقط (بدون تنفيذ) ==============
  Future<Map<String, dynamic>> analyzeOnly({
    required String symbol,
    required double amount,
    required bool isDemo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/trade/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'symbol': symbol,
          'amount': amount,
          'is_demo': isDemo,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'يجب تسجيل الدخول أولاً'};
      } else {
        return {
          'success': false,
          'message': 'خطأ في التحليل: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالسيرفر: $e'};
    }
  }

  // ============== تنفيذ صفقة ==============
  Future<Map<String, dynamic>> executeTrade({
    required String symbol,
    required double amount,
    required bool isDemo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/trade/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'symbol': symbol,
          'amount': amount,
          'is_demo': isDemo,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'يجب تسجيل الدخول أولاً'};
      } else {
        return {
          'success': false,
          'message': 'خطأ في تنفيذ الصفقة: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالسيرفر: $e'};
    }
  }

  // ============== إعادة تعيين حالة الإيقاف ==============
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
        return {
          'success': false,
          'message': 'فشل إعادة التعيين: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالسيرفر: $e'};
    }
  }

  // ============== الحصول على حالة النظام ==============
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/status'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'فشل جلب الحالة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالسيرفر: $e'};
    }
  }

  // ============== التحقق من صحة السيرفر ==============
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'unhealthy'};
      }
    } catch (e) {
      return {'status': 'unhealthy', 'error': e.toString()};
    }
  }
}
