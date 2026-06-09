import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';

class QuotexAPI {
  static const String wsUrl = 'wss://ws.quotex.io/';
  WebSocketChannel? _channel;
  String? _ssid;

  // تسجيل الدخول باستخدام SSID
  Future<bool> loginWithSSID(String ssid) async {
    _ssid = ssid;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.sink.add(jsonEncode({
        'action': 'ssid_auth',
        'ssid': _ssid,
      }));
      await Future.delayed(Duration(seconds: 2));
      return true;
    } catch (e) {
      print('❌ خطأ في الاتصال: $e');
      return false;
    }
  }

  // جلب العملات المتاحة
  Future<List<String>> getAssets() async {
    // مؤقتاً قائمة ثابتة حتى نعرف الرسالة الصحيحة
    return ['EUR/USD', 'GBP/USD', 'USD/JPY', 'AUD/USD', 'BTC/USD'];
  }

  // جلب الرصيد
  Future<double> getBalance() async {
    // مؤقتاً قيمة ثابتة
    return 10000.0;
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
