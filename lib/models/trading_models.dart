class TradeResponse {
  final bool success;
  final String? message;
  final String? symbol;
  final double? amount;
  final String? action;
  final bool? isPaused;
  final int? consecutiveWins;
  final int? consecutiveLosses;
  final Map<String, dynamic>? analysis;
  final Map<String, dynamic>? trade;

  TradeResponse({
    required this.success,
    this.message,
    this.symbol,
    this.amount,
    this.action,
    this.isPaused,
    this.consecutiveWins,
    this.consecutiveLosses,
    this.analysis,
    this.trade,
  });

  factory TradeResponse.fromJson(Map<String, dynamic> json) {
    return TradeResponse(
      success: json['success'] ?? false,
      message: json['message'],
      symbol: json['symbol'],
      amount: json['amount']?.toDouble(),
      action: json['action'],
      isPaused: json['is_paused'],
      consecutiveWins: json['consecutive_wins'],
      consecutiveLosses: json['consecutive_losses'],
      analysis: json['analysis'],
      trade: json['trade'],
    );
  }
}

class AnalysisResult {
  final String action; // "CALL", "PUT", "HOLD"
  final double finalSignal;
  final double strength;
  final List<Map<String, dynamic>> strategiesResults;

  AnalysisResult({
    required this.action,
    required this.finalSignal,
    required this.strength,
    required this.strategiesResults,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      action: json['action'] ?? 'HOLD',
      finalSignal: (json['final_signal'] ?? 0).toDouble(),
      strength: (json['strength'] ?? 0).toDouble(),
      strategiesResults: List<Map<String, dynamic>>.from(
        json['strategies_results'] ?? [],
      ),
    );
  }
}

class SystemStatus {
  final bool isLoggedIn;
  final bool isPaused;
  final int consecutiveWins;
  final int consecutiveLosses;
  final int maxWinsBeforePause;
  final int maxLossesBeforePause;
  final List<String> availableSymbols;

  SystemStatus({
    required this.isLoggedIn,
    required this.isPaused,
    required this.consecutiveWins,
    required this.consecutiveLosses,
    required this.maxWinsBeforePause,
    required this.maxLossesBeforePause,
    required this.availableSymbols,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      isLoggedIn: json['is_logged_in'] ?? false,
      isPaused: json['is_paused'] ?? false,
      consecutiveWins: json['consecutive_wins'] ?? 0,
      consecutiveLosses: json['consecutive_losses'] ?? 0,
      maxWinsBeforePause: json['max_wins_before_pause'] ?? 5,
      maxLossesBeforePause: json['max_losses_before_pause'] ?? 2,
      availableSymbols: List<String>.from(json['available_symbols'] ?? []),
    );
  }
}

class LoginResponse {
  final bool success;
  final String? message;
  final String? token;
  final List<String>? symbols;
  final String? accountType;

  LoginResponse({
    required this.success,
    this.message,
    this.token,
    this.symbols,
    this.accountType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'],
      token: json['token'],
      symbols: json['symbols'] != null
          ? List<String>.from(json['symbols'])
          : null,
      accountType: json['account_type'],
    );
  }
}
