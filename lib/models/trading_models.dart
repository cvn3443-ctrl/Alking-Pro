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

  factory
