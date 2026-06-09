import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';

class QuotexAPI {
  static const String wsUrl = 'wss://ws.quotex.io/'; // تأكد من الرابط
  WebSocketChannel? _channel;
  String? _ssid;

  // تسجيل الدخول باستخدام الـ SSID
  Future<bool> loginWithSSID(String ssid) async {
    _ssid = ssid;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.sink.add(jsonEncode({
        'action': 'ssid_auth',
        'ssid': _ssid,
      }));
      await Future.delayed(Duration(seconds: 2));
      // هنا سنضيف منطق للتحقق من الرد (سيتم لاحقاً)
      return true;
    } catch (e) {
      return false;
    }
  }

  // جلب العملات المتاحة
  Future<List<String>> getAssets() async {
    // إرسال الطلب المناسب لجلب الأصول
    return ['EUR/USD', 'GBP/USD', 'USD/JPY'];
  }

  // تنفيذ صفقة شراء
  Future<bool> buy(String pair, double amount, int duration) async {
    _channel!.sink.add(jsonEncode({
      'action': 'buy',
      'pair': pair,
      'amount': amount,
      'duration': duration,
    }));
    return true;
  }

  // تنفيذ صفقة بيع
  Future<bool> sell(String pair, double amount, int duration) async {
    _channel!.sink.add(jsonEncode({
      'action': 'sell',
      'pair': pair,
      'amount': amount,
      'duration': duration,
    }));
    return true;
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
