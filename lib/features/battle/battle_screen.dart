// Callers: lib/features/dungeon/dungeon_screen.dart (battle room push)
// Purpose: Turn-based combat UI — HP/MP bars, action buttons, battle log
// Reads/Writes: battleProvider (BattleState; calls playerAttack/Skill/Defend/Flee/endBattle)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/character.dart';
import '../../core/models/enemy.dart';
import '../character/character_notifier.dart';
import 'battle_engine.dart';
import 'battle_notifier.dart';
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
    Future.microtask(
      () => ref.read(battleProvider.notifier).startBattle(
            player: widget.player,
            enemy: widget.enemy,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final battle = ref.watch(battleProvider);

    if (battle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${battle.enemy.name} 전투',
            style: const TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _CombatantBar(
                  name: battle.enemy.name,
                  currentHp: battle.enemy.currentHp,
                  maxHp: battle.enemy.maxHp,
                  color: Colors.red,
                ),
                const SizedBox(height: 8),
                _CombatantBar(
                  name: battle.player.name,
                  currentHp: battle.player.currentHp,
                  maxHp: battle.player.stats.maxHp,
                  currentMp: battle.player.currentMp,
                  maxMp: battle.player.stats.maxMp,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
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

class _CombatantBar extends StatelessWidget {
  final String name;
  final int currentHp;
  final int maxHp;
  final int? currentMp;
  final int? maxMp;
  final Color color;

  const _CombatantBar({
    required this.name,
    required this.currentHp,
    required this.maxHp,
    this.currentMp,
    this.maxMp,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hpRatio = (currentHp / maxHp).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text('$currentHp / $maxHp HP',
                  style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hpRatio,
              backgroundColor: Colors.white12,
              color: color,
              minHeight: 8,
            ),
          ),
          if (currentMp != null && maxMp != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(),
                Text('$currentMp / $maxMp MP',
                    style: const TextStyle(
                        color: Colors.purpleAccent, fontSize: 11)),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (currentMp! / maxMp!).clamp(0.0, 1.0),
                backgroundColor: Colors.white12,
                color: Colors.purpleAccent,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.log.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(widget.log[i],
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  final BattleState battle;
  const _ActionBar({required this.battle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(battleProvider.notifier);
    final enabled = battle.isPlayerTurn;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black26,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ABtn(
                  label: '⚔️ 공격',
                  enabled: enabled,
                  onTap: () => notifier.playerChooseRps(RpsChoice.attack),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ABtn(
                  label: '🛡️ 방어',
                  enabled: enabled,
                  color: Colors.blueGrey,
                  onTap: () => notifier.playerChooseRps(RpsChoice.defense),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ABtn(
                  label: '💨 회피',
                  enabled: enabled,
                  color: Colors.teal,
                  onTap: () => notifier.playerChooseRps(RpsChoice.evasion),
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
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (won) {
                await ref
                    .read(characterProvider.notifier)
                    .gainExp(battle.expReward);
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
