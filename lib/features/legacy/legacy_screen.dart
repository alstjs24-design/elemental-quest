import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/legacy.dart';
import 'legacy_notifier.dart';

class LegacyScreen extends ConsumerWidget {
  const LegacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legacy = ref.watch(legacyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('⚗️ 유산 — 영구 강화', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _FragmentBar(fragments: legacy.soulFragments),
          const Divider(color: Colors.white12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: kLegacyUpgrades.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final upgrade = kLegacyUpgrades[i];
                final level = legacy.levelOf(upgrade.type);
                final maxed = level >= upgrade.maxLevel;
                final cost = maxed ? 0 : upgrade.costs[level];
                final canAfford = !maxed && legacy.soulFragments >= cost;

                return _UpgradeCard(
                  upgrade: upgrade,
                  currentLevel: level,
                  cost: cost,
                  maxed: maxed,
                  canAfford: canAfford,
                  onUpgrade: canAfford
                      ? () async {
                          final ok = await ref
                              .read(legacyProvider.notifier)
                              .purchaseUpgrade(upgrade.type);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${upgrade.icon} ${upgrade.label} Lv.${level + 1} 강화!'),
                                backgroundColor: Colors.deepPurple,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FragmentBar extends StatelessWidget {
  final int fragments;
  const _FragmentBar({required this.fragments});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A1080), Color(0xFF6B2FC9)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('💎', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('영혼 파편', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('$fragments', style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          const Text('던전에서 획득\n죽어도 보존됨',
              style: TextStyle(color: Colors.white60, fontSize: 11),
              textAlign: TextAlign.right),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final LegacyUpgrade upgrade;
  final int currentLevel;
  final int cost;
  final bool maxed;
  final bool canAfford;
  final VoidCallback? onUpgrade;

  const _UpgradeCard({
    required this.upgrade,
    required this.currentLevel,
    required this.cost,
    required this.maxed,
    required this.canAfford,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final color = maxed ? Colors.amber : canAfford ? Colors.deepPurple : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(upgrade.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(upgrade.label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(upgrade.effectPerLevel,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                _LevelDots(current: currentLevel, max: upgrade.maxLevel),
              ],
            ),
          ),
          const SizedBox(width: 12),
          maxed
              ? const Column(children: [
                  Text('✅', style: TextStyle(fontSize: 20)),
                  Text('MAX', style: TextStyle(color: Colors.amber, fontSize: 11)),
                ])
              : ElevatedButton(
                  onPressed: onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford
                        ? Colors.deepPurple
                        : Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Column(
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 14)),
                      Text('$cost', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

class _LevelDots extends StatelessWidget {
  final int current;
  final int max;
  const _LevelDots({required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(max, (i) {
        final filled = i < current;
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Colors.deepPurple : Colors.transparent,
            border: Border.all(
              color: filled ? Colors.deepPurple : Colors.white24,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}
