import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // 🔥 غير هذا الرابط بعد ما ترفع السيرفر على PythonAnywhere
  static const String baseUrl = 'https://your-username.pythonanywhere.com';

  // الخطوة 1: التحقق من صحة الكود والإيميل
  static Future<Map<String, dynamic>> verifyLicense(String licenseKey, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/verify_license'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'license_key': licenseKey, 'email': email}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'فشل الاتصال بالسيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  // الخطوة 2: تسجيل الدخول إلى Quotex
  static Future<Map<String, dynamic>> loginToQuotex(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'فشل تسجيل الدخول إلى المنصة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  // الخطوة 3: تنفيذ صفقة
  static Future<bool> executeTrade({
    required String licenseKey,
    required String action,
    required String pair,
    required double amount,
    required int duration,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/trade'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'license_key': licenseKey,
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
}
