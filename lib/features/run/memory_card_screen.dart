import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/models/memory_card.dart';

class MemoryCardScreen extends StatefulWidget {
  final List<MemoryCard> cards;
  const MemoryCardScreen({super.key, required this.cards});

  @override
  State<MemoryCardScreen> createState() => _MemoryCardScreenState();
}

class _MemoryCardScreenState extends State<MemoryCardScreen> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                '오늘의 기억',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(color: Colors.amber),
              ),
              const SizedBox(height: 4),
              Text(
                '이 순간을 간직할 추억을 하나 골라줘',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Column(
                  children: List.generate(widget.cards.length, (i) {
                    final card = widget.cards[i];
                    final selected = _selectedIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.amber.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? Colors.amber
                                  : Colors.white.withValues(alpha: 0.15),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(card.icon,
                                  style: const TextStyle(fontSize: 36)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(card.name,
                                        style: AppTextStyles.labelBold.copyWith(
                                            color: selected
                                                ? Colors.amber
                                                : AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(card.description,
                                        style: AppTextStyles.bodySmall),
                                    const SizedBox(height: 6),
                                    Text(card.bonusSummary,
                                        style: AppTextStyles.caption.copyWith(
                                            color: AppColors.water,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              if (selected)
                                const Icon(Icons.check_circle,
                                    color: Colors.amber, size: 22),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _selectedIndex == null
                    ? null
                    : () => Navigator.pop(
                          context,
                          widget.cards[_selectedIndex!],
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.white12,
                ),
                child: Text('이 기억을 간직할게',
                    style: AppTextStyles.labelBold.copyWith(color: Colors.black)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('그냥 넘어갈게',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textDisabled)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
