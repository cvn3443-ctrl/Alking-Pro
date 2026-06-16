import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/trading_provider.dart';
import '../widgets/symbol_selector.dart';
import 'login_screen.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TradingProvider>().getStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          'Alking Pro - تداول',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Consumer<TradingProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(provider),
                const SizedBox(height: 16),
                _buildPlatformWebView(),
                const SizedBox(height: 16),
                SymbolSelector(
                  symbols: provider.symbols,
                  selectedSymbol: provider.selectedSymbol,
                  onChanged: (symbol) {
                    provider.selectedSymbol = symbol;
                  },
                ),
                const SizedBox(height: 16),
                _buildAmountField(provider),
                const SizedBox(height: 16),
                _buildAccountTypeToggle(provider),
                const SizedBox(height: 16),
                _buildControlButtons(provider),
                const SizedBox(height: 16),
                _buildStatsRow(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlatformWebView() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: const WebView(
        initialUrl: 'https://qxbroker.com',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }

  Widget _buildStatusCard(TradingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: provider.isPaused ? Colors.orange : Colors.greenAccent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'حالة النظام',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                provider.isPaused ? '⏸ متوقف' : '▶️ يعمل',
                style: TextStyle(
                  color: provider.isPaused ? Colors.orange : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'الصفقات المتتالية',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '🏆 ${provider.consecutiveWins}',
                    style: const TextStyle(color: Colors.green, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '💔 ${provider.consecutiveLosses}',
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(TradingProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text(
            'المبلغ:',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              initialValue: provider.amount.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'أدخل المبلغ',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value);
                if (amount != null && amount > 0) {
                  provider.amount = amount;
                }
              },
            ),
          ),
          const Text(
            'USD',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeToggle(TradingProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text(
            'الحساب:',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ToggleButtons(
              isSelected: [!provider.isDemo, provider.isDemo],
              onPressed: (index) {
                provider.isDemo = index == 1;
              },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: provider.isDemo ? Colors.blue : Colors.green,
              color: Colors.grey,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('حقيقي'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('تجريبي'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(TradingProvider provider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isExecuting || provider.isPaused
                ? null
                : () => _handleExecuteTrade(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isExecuting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    '🚀 تنفيذ صفقة',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: provider.isPaused ? _handleResetTrading : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  provider.isPaused ? Colors.orange : Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              provider.isPaused ? '🔄 إعادة تشغيل' : '⏸ متوقف',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(TradingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'عدد الصفقات',
            provider.totalTrades.toString(),
            Colors.blue,
          ),
          _buildStatItem(
            'حد الربح',
            '${provider.consecutiveWins}/${5}',
            Colors.green,
          ),
          _buildStatItem(
            'حد الخسارة',
            '${provider.consecutiveLosses}/${2}',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Future<void> _handleExecuteTrade(TradingProvider provider) async {
    if (provider.selectedSymbol == null) {
      Fluttertoast.showToast(
        msg: '⚠️ الرجاء اختيار زوج عملة',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isExecuting = true);

    try {
      final result = await provider.executeTrade();

      if (result['success'] == true) {
        final tradeResult = result['trade']?['trade_result'] ?? 'unknown';
        final isWin = tradeResult == 'win';
        final isPaused = result['is_paused'] ?? false;

        Fluttertoast.showToast(
          msg: isWin
              ? '✅ صفقة رابحة! +${result['amount']}'
              : '❌ صفقة خاسرة -${result['amount']}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: isWin ? Colors.green : Colors.red,
          textColor: Colors.white,
        );

        if (isPaused) {
          Fluttertoast.showToast(
            msg: '⏸ تم إيقاف التداول تلقائياً',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? '❌ فشل تنفيذ الصفقة',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: '❌ خطأ: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isExecuting = false);
      }
      await provider.getStatus();
    }
  }

  Future<void> _handleResetTrading() async {
    final provider = context.read<TradingProvider>();
    final result = await provider.resetTrading();

    if (result['success'] == true) {
      Fluttertoast.showToast(
        msg: '✅ تم إعادة تشغيل التداول',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      await provider.getStatus();
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? '❌ فشل إعادة التشغيل',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تسجيل خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<TradingProvider>().logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
}
