import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        backgroundColor: Color(0xFF050D14),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (runState.isComplete) {
      return _RunEndScreen(
        won: true,
        battlesWon: runState.totalBattlesWon,
        cardsCount: runState.pickedCards.length,
        onExit: () => Navigator.pop(context),
      );
    }

    if (runState.isFailed) {
      return _RunEndScreen(
        won: false,
        battlesWon: runState.totalBattlesWon,
        cardsCount: runState.pickedCards.length,
        onExit: () => Navigator.pop(context),
      );
    }

    final zone = runState.currentZone;
    final total = runState.totalBattles;
    final done = runState.completedBattles;
    final progressRatio = done / total;

    return Scaffold(
      backgroundColor: const Color(0xFF050D14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('낮잠 런', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _confirmExit(context),
            child: const Text('나가기', style: TextStyle(color: Colors.white54)),
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
                  runState.isBossPhase ? '👹 보스 도전!' : '⚔️ 전투 시작',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        backgroundColor: const Color(0xFF1A0A2E),
        title: const Text('런 포기', style: TextStyle(color: Colors.white)),
        content: const Text('지금 나가면 이번 런의 기억이 사라져요.',
            style: TextStyle(color: Colors.white70)),
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
            Text('전투 $done / ${total - 1}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (isBossNext)
              const Text('🔥 보스',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white12,
            color: isBossNext ? Colors.red : const Color(0xFF8B2FC9),
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
    final color = isBoss ? Colors.red : const Color(0xFF8B2FC9);
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
                        style: TextStyle(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text(zone.subtitle,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
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
                        style: TextStyle(
                          color: cleared
                              ? Colors.green
                              : (current ? color : Colors.white54),
                          fontSize: 13,
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
              const Text('📖 오늘의 기억',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              if (attackBonus > 0)
                Text('공격 +$attackBonus  ',
                    style: const TextStyle(
                        color: Color(0xFFE07840), fontSize: 12)),
              if (defenseBonus > 0)
                Text('방어 +$defenseBonus',
                    style:
                        const TextStyle(color: Colors.lightBlue, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: cards
                .map((c) => Text('${c.icon} ${c.name}',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 11)))
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
        Text('$hp / $maxHp',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

// ── Run end screen ────────────────────────────────────────────────────────────

class _RunEndScreen extends StatelessWidget {
  final bool won;
  final int battlesWon;
  final int cardsCount;
  final VoidCallback onExit;
  const _RunEndScreen(
      {required this.won,
      required this.battlesWon,
      required this.cardsCount,
      required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D14),
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: won ? Colors.amber : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                won
                    ? '오늘은 조금 용감했어요.'
                    : '오늘은 조금 무서웠나요...',
                style: const TextStyle(color: Colors.white60, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _StatRow('전투 클리어', '$battlesWon'),
              _StatRow('기억한 추억', '$cardsCount'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90D9),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                ),
                child: const Text('로비로 돌아가기',
                    style: TextStyle(fontSize: 16)),
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
          Text('$label: ',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
