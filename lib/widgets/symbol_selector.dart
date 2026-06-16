import 'package:flutter/material.dart';

class SymbolSelector extends StatelessWidget {
  final List<String> symbols;
  final String? selectedSymbol;
  final ValueChanged<String?> onChanged;

  const SymbolSelector({
    super.key,
    required this.symbols,
    required this.selectedSymbol,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text(
            'الزوج:',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSymbol,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1A2E),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                hint: const Text(
                  'اختر زوج عملة',
                  style: TextStyle(color: Colors.grey),
                ),
                items: symbols.map((symbol) {
                  return DropdownMenuItem<String>(
                    value: symbol,
                    child: Text(
                      symbol,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
