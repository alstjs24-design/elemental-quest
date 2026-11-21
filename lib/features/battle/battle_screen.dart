// Callers: lib/features/dungeon/dungeon_screen.dart (battle room push)
// Purpose: Turn-based combat UI — arena with sprites, HP/MP bars, action buttons, battle log
// Reads/Writes: battleProvider (BattleState; calls playerChooseRps/playerFlee/endBattle)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/character.dart';
import '../../core/models/enemy.dart';
import '../character/character_notifier.dart';
import '../crafting/material_notifier.dart';
import 'battle_engine.dart';
import 'battle_notifier.dart';
import 'battle_sprites.dart';
import 'battle_state.dart';

class BattleScreen extends ConsumerStatefulWidget {
  final Character player;
  final Enemy enemy;

  const BattleScreen({super.key, required this.player, required this.enemy});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final effective = ref.read(effectiveStatsProvider);
      ref.read(battleProvider.notifier).startBattle(
            player: widget.player,
            enemy: widget.enemy,
            effectiveAttack: effective.attack,
            effectiveDefense: effective.defense,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final battle = ref.watch(battleProvider);

    if (battle == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF050D14),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050D14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(elemIcon(battle.enemy.element),
                style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(battle.enemy.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            if (battle.enemy.grade == EnemyGrade.boss) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('BOSS',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _BattleArena(battle: battle),
          Expanded(
            child: _BattleLog(
                log: battle.log.map((r) => r.message).toList()),
          ),
          if (!battle.isBattleOver)
            _ActionBar(battle: battle)
          else
            _ResultPanel(battle: battle),
        ],
      ),
    );
  }
}

// ── Arena ─────────────────────────────────────────────────────────────────────

class _BattleArena extends StatelessWidget {
  final BattleState battle;
  const _BattleArena({required this.battle});

  @override
  Widget build(BuildContext context) {
    final enemyGlow = elemAccentColor(battle.enemy.element);
    final playerGlow = elemAccentColor(battle.player.element);

    return SizedBox(
      height: 268,
      child: Stack(
        children: [
          // atmospheric background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    enemyGlow.withValues(alpha: 0.08),
                    const Color(0xFF050D14),
                    playerGlow.withValues(alpha: 0.07),
                  ],
                ),
              ),
            ),
          ),
          // centre divider line
          Positioned(
            left: 24,
            right: 24,
            top: 134,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  Colors.white10,
                  Colors.white10,
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Enemy — top half
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Column(
              children: [
                EnemySprite(enemy: battle.enemy, size: 92),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: _CompactBar(
                    label: battle.enemy.name,
                    current: battle.enemy.currentHp,
                    max: battle.enemy.maxHp,
                    color: enemyGlow,
                  ),
                ),
              ],
            ),
          ),
          // Player — bottom half
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      _CompactBar(
                        label: battle.player.name,
                        current: battle.player.currentHp,
                        max: battle.player.stats.maxHp,
                        color: playerGlow,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'MP ${battle.player.currentMp}/${battle.player.stats.maxMp}',
                            style: const TextStyle(
                                color: Colors.purpleAccent, fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (battle.player.currentMp /
                                        battle.player.stats.maxMp)
                                    .clamp(0.0, 1.0),
                                backgroundColor: Colors.white12,
                                color: Colors.purpleAccent,
                                minHeight: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                PlayerSprite(character: battle.player, size: 82),
              ],
            ),
          ),
          // "enemy turn" indicator
          if (!battle.isPlayerTurn && !battle.isBattleOver)
            Positioned(
              left: 0,
              right: 0,
              top: 118,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: const Text('적 행동 중',
                      style:
                          TextStyle(color: Colors.red, fontSize: 11)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;
  const _CompactBar(
      {required this.label,
      required this.current,
      required this.max,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ),
            Text('$current / $max',
                style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (current / max).clamp(0.0, 1.0),
            backgroundColor: Colors.white12,
            color: color,
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}

// ── Battle log ────────────────────────────────────────────────────────────────

class _BattleLog extends StatefulWidget {
  final List<String> log;
  const _BattleLog({required this.log});

  @override
  State<_BattleLog> createState() => _BattleLogState();
}

class _BattleLogState extends State<_BattleLog> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_BattleLog old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: ListView.builder(
        controller: _scroll,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: widget.log.length,
        itemBuilder: (_, i) {
          final isLast = i == widget.log.length - 1;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              widget.log[i],
              style: TextStyle(
                  color: isLast ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight: isLast
                      ? FontWeight.w500
                      : FontWeight.normal),
            ),
          );
        },
      ),
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  final BattleState battle;
  const _ActionBar({required this.battle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(battleProvider.notifier);
    final enabled = battle.isPlayerTurn;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black38,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ABtn(
                  label: '⚔️ 공격',
                  enabled: enabled,
                  onTap: () =>
                      notifier.playerChooseRps(RpsChoice.attack),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ABtn(
                  label: '🛡️ 방어',
                  enabled: enabled,
                  color: Colors.blueGrey,
                  onTap: () =>
                      notifier.playerChooseRps(RpsChoice.defense),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ABtn(
                  label: '💨 회피',
                  enabled: enabled,
                  color: Colors.teal,
                  onTap: () =>
                      notifier.playerChooseRps(RpsChoice.evasion),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ABtn(
            label: '🏃 도망',
            enabled: enabled,
            color: Colors.orange,
            onTap: notifier.playerFlee,
          ),
        ],
      ),
    );
  }
}

class _ABtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _ABtn({
    required this.label,
    required this.enabled,
    this.color = const Color(0xFFE07840),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Result panel ──────────────────────────────────────────────────────────────

class _ResultPanel extends ConsumerWidget {
  final BattleState battle;
  const _ResultPanel({required this.battle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final won = battle.phase == BattlePhase.victory;
    final fled = battle.phase == BattlePhase.fled;

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.black38,
      child: Column(
        children: [
          Text(
            won ? '🏆 승리!' : (fled ? '🏃 도망 성공!' : '💀 패배...'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: won || fled ? Colors.amber : Colors.red,
            ),
          ),
          if (won) ...[
            const SizedBox(height: 8),
            Text(
              '경험치 +${battle.expReward}  골드 +${battle.goldReward}',
              style: const TextStyle(color: Colors.white70),
            ),
            if (battle.pendingDrops.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                children: battle.pendingDrops
                    .map((m) => Text('${m.icon} ${m.name}',
                        style: const TextStyle(
                            color: Colors.amber, fontSize: 12)))
                    .toList(),
              ),
            ],
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (won) {
                await ref
                    .read(characterProvider.notifier)
                    .gainExp(battle.expReward);
                if (battle.pendingDrops.isNotEmpty) {
                  await ref
                      .read(materialProvider.notifier)
                      .addDrops(battle.pendingDrops);
                }
              }
              ref.read(battleProvider.notifier).endBattle();
              if (context.mounted) {
                Navigator.pop(context, battle.phase);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90D9),
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 12),
            ),
            child: const Text('계속', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
