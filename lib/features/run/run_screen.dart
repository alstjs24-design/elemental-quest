import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/models/character.dart';
import '../../core/models/memory_card.dart';
import '../battle/battle_screen.dart';
import '../battle/battle_state.dart';
import '../character/character_notifier.dart';
import '../legacy/legacy_notifier.dart';
import 'memory_card_screen.dart';
import 'run_notifier.dart';
import 'run_state.dart';

class RunScreen extends ConsumerStatefulWidget {
  const RunScreen({super.key});

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends ConsumerState<RunScreen> {
  bool _inBattle = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(characterProvider.notifier).fullRestore();
      ref.read(runProvider.notifier).startRun();
    });
  }

  @override
  void dispose() {
    ref.read(runProvider.notifier).endRun();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    final character = ref.watch(characterProvider).activeCharacter;

    if (runState == null || character == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final legacyState = ref.watch(legacyProvider);

    if (runState.isComplete) {
      return _RunEndScreen(
        won: true,
        battlesWon: runState.totalBattlesWon,
        cardsCount: runState.pickedCards.length,
        soulFragments: legacyState.soulFragments,
        onExit: () => Navigator.pop(context),
      );
    }

    if (runState.isFailed) {
      return _RunEndScreen(
        won: false,
        battlesWon: runState.totalBattlesWon,
        cardsCount: runState.pickedCards.length,
        soulFragments: legacyState.soulFragments,
        onExit: () => Navigator.pop(context),
      );
    }

    final zone = runState.currentZone;
    final total = runState.totalBattles;
    final done = runState.completedBattles;
    final progressRatio = done / total;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('낮잠 런', style: AppTextStyles.titleMedium),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _confirmExit(context),
            child: Text('나가기', style: AppTextStyles.bodySmall),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress bar
              _ProgressBar(
                done: done,
                total: total,
                ratio: progressRatio,
                isBossNext: runState.isBossPhase,
              ),
              const SizedBox(height: 24),
              // Zone card
              _ZoneCard(
                zone: runState.isBossPhase
                    ? const RunZoneConfig(
                        name: '최종 보스',
                        subtitle: '분리불안의 화신이 기다린다',
                        icon: '👹',
                        battleCount: 1,
                        floorLevel: 7,
                      )
                    : zone,
                battleIndex: runState.battleIndexInZone,
                isBoss: runState.isBossPhase,
              ),
              const SizedBox(height: 20),
              // Run buffs from memory cards
              if (runState.pickedCards.isNotEmpty)
                _CardBuffsRow(
                  attackBonus: runState.totalAttackBonus,
                  defenseBonus: runState.totalDefenseBonus,
                  cardCount: runState.pickedCards.length,
                  cards: runState.pickedCards,
                ),
              if (runState.pickedCards.isNotEmpty) const SizedBox(height: 20),
              // Character HP (uses effectiveStats maxHp so equipment bonuses are reflected)
              _CharHpRow(
                character: character,
                effectiveMaxHp: ref.watch(effectiveStatsProvider).maxHp,
              ),
              const Spacer(),
              // Battle button
              ElevatedButton(
                onPressed: _inBattle ? null : () => _startBattle(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: runState.isBossPhase
                      ? Colors.red.shade800
                      : const Color(0xFF8B2FC9),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  runState.isBossPhase ? '😱 분리불안과 마주하기' : '🌙 꿈속으로',
                  style: AppTextStyles.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startBattle(BuildContext context) async {
    if (_inBattle) return;
    final runNotifier = ref.read(runProvider.notifier);
    final runState = ref.read(runProvider);
    final character = ref.read(characterProvider).activeCharacter;
    if (runState == null || character == null) return;

    setState(() => _inBattle = true);

    final enemy = runNotifier.currentEnemy();
    if (!context.mounted) return;

    final result = await Navigator.push<BattlePhase>(
      context,
      MaterialPageRoute(
        builder: (_) => BattleScreen(
          player: character,
          enemy: enemy,
          extraAttackBonus: runState.totalAttackBonus,
          extraDefenseBonus: runState.totalDefenseBonus,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _inBattle = false);

    if (result == BattlePhase.victory) {
      runNotifier.onBattleVictory();
      final updatedState = ref.read(runProvider);
      if (updatedState == null) return;

      if (updatedState.isComplete) {
        // Boss cleared — award soul fragments for a full run clear
        await ref.read(legacyProvider.notifier).onRunEnd(
          floor: 7,
          roomsCleared: updatedState.totalBattlesWon,
          victory: true,
        );
        return;
      }
      if (updatedState.isFailed) return;

      // Show memory card picker between battles
      final cards = runNotifier.drawThreeCards();
      if (cards.isNotEmpty && context.mounted) {
        final picked = await Navigator.push<MemoryCard>(
          context,
          MaterialPageRoute(builder: (_) => MemoryCardScreen(cards: cards)),
        );
        if (picked != null && mounted) {
          await runNotifier.pickCard(picked);
        }
      }
    } else if (result == BattlePhase.defeat) {
      runNotifier.onBattleDefeat();
      // Award partial soul fragments even on defeat
      final runState = ref.read(runProvider);
      if (runState != null) {
        await ref.read(legacyProvider.notifier).onRunEnd(
          floor: runState.currentFloor,
          roomsCleared: runState.totalBattlesWon.clamp(1, 999),
          victory: false,
        );
      }
    }
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgPurple,
        title: Text('런 포기', style: AppTextStyles.titleMedium),
        content: Text('지금 나가면 이번 런의 기억이 사라져요.',
            style: AppTextStyles.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('계속하기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('나가기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int done;
  final int total;
  final double ratio;
  final bool isBossNext;
  const _ProgressBar(
      {required this.done,
      required this.total,
      required this.ratio,
      required this.isBossNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('기억 $done / ${total - 1}', style: AppTextStyles.bodySmall),
            if (isBossNext)
              Text('💀 분리불안',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.hpLow, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white12,
            color: isBossNext ? AppColors.hpLow : AppColors.dungeon,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final RunZoneConfig zone;
  final int battleIndex;
  final bool isBoss;
  const _ZoneCard(
      {required this.zone, required this.battleIndex, required this.isBoss});

  @override
  Widget build(BuildContext context) {
    final color = isBoss ? AppColors.hpLow : AppColors.dungeon;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(zone.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name,
                        style: AppTextStyles.titleLarge.copyWith(color: color)),
                    Text(zone.subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (!isBoss) ...[
            const SizedBox(height: 12),
            Row(
              children: List.generate(zone.battleCount, (i) {
                final cleared = i < battleIndex;
                final current = i == battleIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cleared
                          ? Colors.green.withValues(alpha: 0.3)
                          : (current
                              ? color.withValues(alpha: 0.3)
                              : Colors.white12),
                      border: Border.all(
                          color: cleared
                              ? Colors.green
                              : (current ? color : Colors.white24)),
                    ),
                    child: Center(
                      child: Text(
                        cleared ? '✓' : '${i + 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: cleared
                              ? AppColors.hpHigh
                              : (current ? color : AppColors.textMuted),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardBuffsRow extends StatelessWidget {
  final int attackBonus;
  final int defenseBonus;
  final int cardCount;
  final List<MemoryCard> cards;
  const _CardBuffsRow(
      {required this.attackBonus,
      required this.defenseBonus,
      required this.cardCount,
      required this.cards});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📖 오늘의 기억',
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (attackBonus > 0)
                Text('공격 +$attackBonus  ',
                    style: AppTextStyles.caption.copyWith(color: AppColors.fire)),
              if (defenseBonus > 0)
                Text('방어 +$defenseBonus',
                    style: AppTextStyles.caption.copyWith(color: AppColors.water)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: cards
                .map((c) => Text('${c.icon} ${c.name}',
                    style: AppTextStyles.caption))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CharHpRow extends StatelessWidget {
  final Character character;
  final int effectiveMaxHp;
  const _CharHpRow({required this.character, required this.effectiveMaxHp});

  @override
  Widget build(BuildContext context) {
    final hp = character.currentHp;
    final maxHp = effectiveMaxHp > 0 ? effectiveMaxHp : character.stats.maxHp;
    final ratio = (hp / maxHp).clamp(0.0, 1.0);
    return Row(
      children: [
        const Text('❤️ ', style: TextStyle(fontSize: 14)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.white12,
              color: ratio > 0.5
                  ? Colors.green
                  : ratio > 0.25
                      ? Colors.orange
                      : Colors.red,
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$hp / $maxHp', style: AppTextStyles.caption),
      ],
    );
  }
}

// ── Run end screen ────────────────────────────────────────────────────────────

class _RunEndScreen extends StatelessWidget {
  final bool won;
  final int battlesWon;
  final int cardsCount;
  final int soulFragments;
  final VoidCallback onExit;
  const _RunEndScreen(
      {required this.won,
      required this.battlesWon,
      required this.cardsCount,
      required this.soulFragments,
      required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(won ? '☀️' : '😢',
                  style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text(
                won
                    ? '아기가 평화롭게 깨어났습니다'
                    : '아기가 울며 깨어났습니다',
                style: AppTextStyles.titleLarge.copyWith(
                    color: won ? Colors.amber : AppColors.hpLow),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                won
                    ? '오늘은 조금 용감했어요.'
                    : '오늘은 조금 무서웠나요...',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _StatRow('기억 클리어', '$battlesWon'),
              _StatRow('기억한 추억', '$cardsCount'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.dungeon.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.soul.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💎', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text('영혼 파편 $soulFragments개 보유',
                            style: AppTextStyles.labelBold.copyWith(
                                color: AppColors.soul)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('다음 꿈에서도 이어집니다 — 유산 화면에서 영구 강화에 사용하세요',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.water,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                ),
                child: Text('꿈에서 깨어나기', style: AppTextStyles.labelBold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ', style: AppTextStyles.bodyMedium),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
