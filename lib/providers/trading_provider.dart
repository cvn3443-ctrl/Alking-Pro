import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/trading_models.dart';

class TradingProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  String? _email;
  String? _token;
  bool _isLoggedIn = false;
  bool _isPaused = false;
  String? _errorMessage;

  List<String> _symbols = [];
  String? _selectedSymbol;
  double _amount = 10.0;
  bool _isDemo = true;
  int _expiryMinutes = 1;

  int _consecutiveWins = 0;
  int _consecutiveLosses = 0;
  int _totalTrades = 0;

  String? get email => _email;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;
  bool get isPaused => _isPaused;
  String? get errorMessage => _errorMessage;
  List<String> get symbols => _symbols;
  String? get selectedSymbol => _selectedSymbol;
  double get amount => _amount;
  bool get isDemo => _isDemo;
  int get expiryMinutes => _expiryMinutes;
  int get consecutiveWins => _consecutiveWins;
  int get consecutiveLosses => _consecutiveLosses;
  int get totalTrades => _totalTrades;

  set selectedSymbol(String? value) {
    _selectedSymbol = value;
    notifyListeners();
  }

  set amount(double value) {
    _amount = value;
    notifyListeners();
  }

  set isDemo(bool value) {
    _isDemo = value;
    notifyListeners();
  }

  set expiryMinutes(int value) {
    _expiryMinutes = value;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);

      if (response['success'] == true) {
        _email = email;
        _token = response['token'] ?? 'session_token';
        _isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setString('token', _token!);

        await fetchSymbols();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'فشل تسجيل الدخول';
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطأ في الاتصال بالسيرفر: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final token = prefs.getString('token');

    if (email != null && token != null) {
      _email = email;
      _token = token;
      _isLoggedIn = true;
      await fetchSymbols();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _email = null;
    _token = null;
    _isLoggedIn = false;
    _symbols = [];
    _selectedSymbol = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('token');

    notifyListeners();
  }

  Future<void> fetchSymbols() async {
    try {
      final response = await _apiService.getSymbols();
      if (response['success'] == true) {
        _symbols = List<String>.from(response['symbols'] ?? []);
        if (_symbols.isNotEmpty && _selectedSymbol == null) {
          _selectedSymbol = _symbols.first;
        }
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'فشل جلب العملات: $e';
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> executeTrade() async {
    if (_selectedSymbol == null) {
      _errorMessage = 'الرجاء اختيار زوج عملة';
      notifyListeners();
      return {'success': false, 'message': 'الرجاء اختيار زوج عملة'};
    }

    try {
      final response = await _apiService.executeTrade(
        symbol: _selectedSymbol!,
        amount: _amount,
        isDemo: _isDemo,
      );

      if (response['success'] == true) {
        _totalTrades++;
        _consecutiveWins = response['trade']?['consecutive_wins'] ?? 0;
        _consecutiveLosses = response['trade']?['consecutive_losses'] ?? 0;
        _isPaused = response['trade']?['is_paused'] ?? false;
        notifyListeners();
        return response;
      } else {
        _errorMessage = response['message'] ?? 'فشل تنفيذ الصفقة';
        notifyListeners();
        return response;
      }
    } catch (e) {
      _errorMessage = 'خطأ في الاتصال بالسيرفر: $e';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  Future<Map<String, dynamic>> analyzeOnly() async {
    if (_selectedSymbol == null) {
      _errorMessage = 'الرجاء اختيار زوج عملة';
      notifyListeners();
      return {'success': false, 'message': 'الرجاء اختيار زوج عملة'};
    }

    try {
      final response = await _apiService.analyzeOnly(
        symbol: _selectedSymbol!,
        amount: _amount,
        isDemo: _isDemo,
      );
      return response;
    } catch (e) {
      _errorMessage = 'خطأ في التحليل: $e';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  Future<Map<String, dynamic>> resetTrading() async {
    try {
      final response = await _apiService.resetTrading();
      if (response['success'] == true) {
        _isPaused = false;
        _consecutiveWins = 0;
        _consecutiveLosses = 0;
        notifyListeners();
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': 'فشل إعادة التعيين: $e'};
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _apiService.getStatus();
      if (response['success'] == true) {
        _isPaused = response['is_paused'] ?? false;
        _consecutiveWins = response['consecutive_wins'] ?? 0;
        _consecutiveLosses = response['consecutive_losses'] ?? 0;
        notifyListeners();
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب الحالة: $e'};
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
