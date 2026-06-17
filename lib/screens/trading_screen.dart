import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/trading_provider.dart';
import '../widgets/symbol_selector.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  bool _isTradingActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TradingProvider>().getStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TradingProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusCard(provider),
              const SizedBox(height: 16),
              SymbolSelector(
                symbols: provider.symbols,
                selectedSymbol: provider.selectedSymbol,
                onChanged: (symbol) => provider.selectedSymbol = symbol,
              ),
              const SizedBox(height: 16),
              _buildAmountField(provider),
              const SizedBox(height: 16),
              _buildAccountTypeToggle(provider),
              const SizedBox(height: 16),
              _buildActivationButton(provider),
              const SizedBox(height: 16),
              _buildStatsRow(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(TradingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: provider.isPaused ? Colors.orange : Colors.greenAccent, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('حالة النظام', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(provider.isPaused ? '⏸ متوقف' : '▶️ يعمل',
                style: TextStyle(color: provider.isPaused ? Colors.orange : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('الصفقات المتتالية', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('🏆 ${provider.consecutiveWins}', style: const TextStyle(color: Colors.green, fontSize: 14)),
                  const SizedBox(width: 12),
                  Text('💔 ${provider.consecutiveLosses}', style: const TextStyle(color: Colors.red, fontSize: 14)),
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
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Text('المبلغ:', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              initialValue: provider.amount.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'أدخل المبلغ', hintStyle: TextStyle(color: Colors.grey)),
              onChanged: (value) {
                final amount = double.tryParse(value);
                if (amount != null && amount > 0) provider.amount = amount;
              },
            ),
          ),
          const Text('USD', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAccountTypeToggle(TradingProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Text('الحساب:', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: ToggleButtons(
              isSelected: [!provider.isDemo, provider.isDemo],
              onPressed: (index) => provider.isDemo = index == 1,
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: provider.isDemo ? Colors.blue : Colors.green,
              color: Colors.grey,
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('حقيقي')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('تجريبي')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationButton(TradingProvider provider) {
    return ElevatedButton(
      onPressed: provider.isPaused ? null : (_isTradingActive ? _stopTrading : () => _startTrading(provider)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isTradingActive ? Colors.red : Colors.greenAccent.shade700,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        provider.isPaused ? '⏸ متوقف (إعادة تشغيل)' : (_isTradingActive ? '⏹ إيقاف التداول' : '▶️ تنشيط التداول'),
        style: TextStyle(
          color: _isTradingActive ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildStatsRow(TradingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('عدد الصفقات', provider.totalTrades.toString(), Colors.blue),
          _buildStatItem('حد الربح', '${provider.consecutiveWins}/5', Colors.green),
          _buildStatItem('حد الخسارة', '${provider.consecutiveLosses}/2', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Future<void> _startTrading(TradingProvider provider) async {
    if (provider.selectedSymbol == null) {
      Fluttertoast.showToast(msg: '⚠️ الرجاء اختيار زوج عملة', backgroundColor: Colors.orange, textColor: Colors.white);
      return;
    }
    setState(() => _isTradingActive = true);
    Fluttertoast.showToast(msg: '▶️ بدء التداول المستمر...', backgroundColor: Colors.blue, textColor: Colors.white);

    while (_isTradingActive && !provider.isPaused && mounted) {
      final result = await provider.executeTrade();
      if (result['success'] == true) {
        final isWin = result['trade']?['trade_result'] == 'win';
        Fluttertoast.showToast(
          msg: isWin ? '✅ صفقة رابحة!' : '❌ صفقة خاسرة',
          backgroundColor: isWin ? Colors.green : Colors.red,
          textColor: Colors.white,
        );
        if (result['is_paused'] == true) {
          Fluttertoast.showToast(msg: '⏸ تم إيقاف التداول تلقائياً', backgroundColor: Colors.orange, textColor: Colors.white);
          setState(() => _isTradingActive = false);
          break;
        }
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? '❌ فشل تنفيذ الصفقة', backgroundColor: Colors.red, textColor: Colors.white);
      }
      // انتظار 4 دقائق بين الصفقات (سرعة بشرية)
      for (int i = 0; i < 240 && _isTradingActive && mounted; i++) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    setState(() => _isTradingActive = false);
  }

  void _stopTrading() {
    setState(() => _isTradingActive = false);
    Fluttertoast.showToast(msg: '⏹ تم إيقاف التداول', backgroundColor: Colors.orange, textColor: Colors.white);
  }
}
