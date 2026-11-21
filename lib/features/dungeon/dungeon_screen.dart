// Callers: lib/features/home/home_screen.dart (menu push)
// Purpose: Dungeon floor exploration — room graph, room entry, battle launch
// Reads: dungeonProvider (DungeonState: dungeon.rooms, dungeon.currentRoomId, currentRoom)
// Writes: enterFloor, moveToRoom(String), markCurrentRoomCleared, exitDungeon
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/dungeon.dart';
import '../../core/models/enemy.dart';
import '../battle/battle_screen.dart';
import '../battle/battle_state.dart';
import '../character/character_notifier.dart';
import '../character/inventory_notifier.dart';
import 'dungeon_notifier.dart';
import 'treasure_loot.dart';

class DungeonScreen extends ConsumerStatefulWidget {
  const DungeonScreen({super.key});

  @override
  ConsumerState<DungeonScreen> createState() => _DungeonScreenState();
}

class _DungeonScreenState extends ConsumerState<DungeonScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(dungeonProvider.notifier).enterFloor(1));
  }

  @override
  Widget build(BuildContext context) {
    final ds = ref.watch(dungeonProvider);
    final dungeon = ds.dungeon;

    if (dungeon == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentRoom = dungeon.currentRoom;
    final accessibleIds = currentRoom.connectedRoomIds.toSet();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${dungeon.theme.name.toUpperCase()} 던전  Lv.${dungeon.floor}',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(dungeonProvider.notifier).exitDungeon();
              Navigator.pop(context);
            },
            child: const Text('나가기',
                style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dungeon.rooms.length,
        itemBuilder: (context, i) {
          final room = dungeon.rooms[i];
          final isCurrent = room.id == dungeon.currentRoomId;
          final isAccessible =
              isCurrent || accessibleIds.contains(room.id);
          return _RoomTile(
            room: room,
            isCurrent: isCurrent,
            isAccessible: isAccessible,
            onTap: isAccessible && !isCurrent
                ? () => _enterRoom(context, room)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _enterRoom(
      BuildContext context, DungeonRoom room) async {
    ref.read(dungeonProvider.notifier).moveToRoom(room.id);

    if (room.type == RoomType.battle || room.type == RoomType.boss) {
      final enemy =
          room.enemies.isNotEmpty ? room.enemies.first : null;
      final player = ref.read(characterProvider).activeCharacter;
      if (enemy == null || player == null) return;

      if (!context.mounted) return;
      final shouldFight = await _showPreBattleSheet(context, enemy);
      if (shouldFight != true || !mounted) return;

      if (!context.mounted) return;
      final result = await Navigator.push<BattlePhase>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BattleScreen(player: player, enemy: enemy),
        ),
      );

      if (result == BattlePhase.victory && mounted) {
        ref.read(dungeonProvider.notifier).markCurrentRoomCleared();
        if (room.type == RoomType.boss && context.mounted) {
          _showFloorComplete(context);
        }
      }
      return;
    }

    if (room.type == RoomType.treasure && !room.isCleared) {
      final floor = ref.read(dungeonProvider).dungeon?.floor ?? 1;
      final loot = generateTreasureLoot(floor);
      await ref.read(inventoryProvider.notifier).addEquipment(loot);
      ref.read(dungeonProvider.notifier).markCurrentRoomCleared();
      if (mounted && context.mounted) {
        _showLootDialog(context, loot.name);
      }
      return;
    }

    if (room.type == RoomType.rest && !room.isCleared) {
      final charNotifier = ref.read(characterProvider.notifier);
      final maxHp = ref.read(characterProvider).effectiveStats.maxHp;
      await charNotifier.restoreHp((maxHp * 0.3).round());
      ref.read(dungeonProvider.notifier).markCurrentRoomCleared();
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💚 HP 30% 회복!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showLootDialog(BuildContext context, String itemName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        title: const Text('💎 보물 발견!',
            style: TextStyle(color: Colors.amber)),
        content: Text('[$itemName]을(를) 획득했습니다!',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인',
                style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPreBattleSheet(BuildContext context, Enemy enemy) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1A0A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PreBattleSheet(enemy: enemy),
    );
  }

  void _showFloorComplete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        title: const Text('🎉 플로어 클리어!',
            style: TextStyle(color: Colors.amber)),
        content: const Text('다음 층으로 진행할 수 있습니다.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final ds = ref.read(dungeonProvider);
              final nextFloor = (ds.dungeon?.floor ?? 1) + 1;
              ref
                  .read(dungeonProvider.notifier)
                  .enterFloor(nextFloor);
            },
            child: const Text('다음 층'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(dungeonProvider.notifier).exitDungeon();
              Navigator.pop(context);
            },
            child: const Text('나가기',
                style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

class _PreBattleSheet extends StatelessWidget {
  final Enemy enemy;
  const _PreBattleSheet({required this.enemy});

  @override
  Widget build(BuildContext context) {
    final elemIcon = switch (enemy.element.name) {
      'fire'  => '🔥',
      'water' => '💧',
      'earth' => '🌿',
      'wind'  => '💨',
      _       => '✨',
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(elemIcon, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(enemy.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text('속성: ${enemy.element.name.toUpperCase()}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 24),
            _StatRow2('HP', '${enemy.maxHp}', Colors.red),
            _StatRow2('공격', '${enemy.attack}', const Color(0xFFE07840)),
            _StatRow2('방어', '${enemy.defense}', Colors.blue),
            _StatRow2('속도', '${enemy.speed}', Colors.green),
            if (enemy.skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('스킬',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              ...enemy.skills.map((s) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text('• ${s.name}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  )),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('🏃 도망치기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE07840),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('⚔️ 전투 시작',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow2 extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow2(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final DungeonRoom room;
  final bool isCurrent;
  final bool isAccessible;
  final VoidCallback? onTap;

  const _RoomTile({
    required this.room,
    required this.isCurrent,
    required this.isAccessible,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (room.type) {
      RoomType.start => '🚪',
      RoomType.battle => '⚔️',
      RoomType.boss => '👹',
      RoomType.treasure => '💎',
      RoomType.rest => '⛺',
    };
    final enemyName = room.enemies.isNotEmpty
        ? room.enemies.first.name
        : null;
    final label = switch (room.type) {
      RoomType.start => '시작 방',
      RoomType.battle => enemyName ?? '전투',
      RoomType.boss => '보스: ${enemyName ?? "???"}',
      RoomType.treasure => '보물 방',
      RoomType.rest => '휴식 방',
    };
    final color = switch (room.type) {
      RoomType.boss => Colors.red,
      RoomType.treasure => Colors.amber,
      RoomType.rest => Colors.green,
      _ => const Color(0xFF4A90D9),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isCurrent
            ? color.withValues(alpha: 0.2)
            : (isAccessible
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? color
                    : (room.isCleared
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.white12),
              ),
            ),
            child: Row(
              children: [
                Text(icon,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isAccessible
                              ? Colors.white
                              : Colors.white38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (room.isCleared)
                        const Text('클리어 ✓',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 11)),
                      if (isCurrent && !room.isCleared)
                        const Text('현재 위치',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11)),
                    ],
                  ),
                ),
                if (isAccessible && !isCurrent && !room.isCleared)
                  Icon(Icons.arrow_forward_ios,
                      color: color.withValues(alpha: 0.6),
                      size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
