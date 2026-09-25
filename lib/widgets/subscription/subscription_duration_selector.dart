import 'package:flutter/material.dart';
import '../../providers/app_provider.dart';

class SubscriptionDurationSelector extends StatelessWidget {
  final AppProvider provider;
  final bool isBn;
  final int selectedDuration;
  final ValueChanged<int> onSelectDuration;

  const SubscriptionDurationSelector({
    super.key,
    required this.provider,
    required this.isBn,
    required this.selectedDuration,
    required this.onSelectDuration,
  });

  @override
  Widget build(BuildContext context) {
    final p = provider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.tr('plan_duration'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDurationChip(1, p.tr('month_1'), null),
              const SizedBox(width: 8),
              _buildDurationChip(3, p.tr('month_3'), p.tr('save_5_pct')),
              const SizedBox(width: 8),
              _buildDurationChip(6, p.tr('month_6'), p.tr('save_10_pct')),
              const SizedBox(width: 8),
              _buildDurationChip(12, p.tr('month_12'), p.tr('save_20_pct')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationChip(int months, String label, String? discount) {
    final isSelected = selectedDuration == months;
    return InkWell(
      onTap: () => onSelectDuration(months),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            if (discount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amberAccent : Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  discount,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black87 : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
