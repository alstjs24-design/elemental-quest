// Callers: lib/features/home/home_screen.dart (menu push)
// Purpose: Character stats, equipment slots, inventory management
// Reads: characterProvider (activeCharacter, equipped, effectiveStats), inventoryProvider (items)
// Writes: equipItem, unequipSlot on characterProvider.notifier
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/character.dart';
import '../../core/models/equipment.dart';
import '../crafting/crafting_screen.dart';
import 'character_notifier.dart';
import 'inventory_notifier.dart';

class CharacterScreen extends ConsumerStatefulWidget {
  const CharacterScreen({super.key});

  @override
  ConsumerState<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends ConsumerState<CharacterScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(characterProvider.notifier).load();
      await ref.read(inventoryProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final charState = ref.watch(characterProvider);
    final invState = ref.watch(inventoryProvider);
    final character = charState.activeCharacter;

    if (character == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stats = charState.effectiveStats;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(character.name,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CraftingScreen()),
            ),
            icon: const Text('⚗️', style: TextStyle(fontSize: 16)),
            label: const Text('합성',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatCard(character: character, stats: stats),
            const SizedBox(height: 16),
            const Text('장비 슬롯',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final slot in EquipmentSlot.values)
              _EquipmentSlotTile(
                slot: slot,
                equipped: charState.equipped[slot],
                inventory: invState
                    .bySlot(slot)
                    .where((e) =>
                        !charState.equipped.values.contains(e) ||
                        charState.equipped[slot] == e)
                    .toList(),
                onEquip: (eq) => ref
                    .read(characterProvider.notifier)
                    .equipItem(eq),
                onUnequip: () => ref
                    .read(characterProvider.notifier)
                    .unequipSlot(slot),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Character character;
  final CharacterStats stats;
  const _StatCard({required this.character, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFE07840).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Lv.${character.level}',
                  style: const TextStyle(
                      color: Color(0xFFE07840),
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(character.element.name.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text('EXP: ${character.exp}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12)),
          const Divider(color: Colors.white12, height: 20),
          _StatRow('HP',
              '${character.currentHp} / ${stats.maxHp}', Colors.red),
          _StatRow('MP',
              '${character.currentMp} / ${stats.maxMp}',
              Colors.purple),
          _StatRow(
              '공격', '${stats.attack}', const Color(0xFFE07840)),
          _StatRow('방어', '${stats.defense}', Colors.blue),
          _StatRow('속도', '${stats.speed}', Colors.green),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13)),
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

class _EquipmentSlotTile extends StatelessWidget {
  final EquipmentSlot slot;
  final Equipment? equipped;
  final List<Equipment> inventory;
  final void Function(Equipment) onEquip;
  final VoidCallback onUnequip;

  const _EquipmentSlotTile({
    required this.slot,
    required this.equipped,
    required this.inventory,
    required this.onEquip,
    required this.onUnequip,
  });

  String _bonusText(Equipment eq) {
    final parts = <String>[];
    if (eq.attackBonus > 0) parts.add('공격 +${eq.attackBonus}');
    if (eq.defenseBonus > 0) parts.add('방어 +${eq.defenseBonus}');
    if (eq.hpBonus > 0) parts.add('HP +${eq.hpBonus}');
    if (eq.speedBonus > 0) parts.add('속도 +${eq.speedBonus}');
    return parts.join('  ');
  }

  @override
  Widget build(BuildContext context) {
    final slotLabel = switch (slot) {
      EquipmentSlot.weapon => '⚔️ 무기',
      EquipmentSlot.armor => '🛡️ 방어구',
      EquipmentSlot.accessory => '💍 악세서리',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slotLabel,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  Text(
                    equipped?.name ?? '없음',
                    style: TextStyle(
                      color: equipped != null
                          ? Colors.white
                          : Colors.white60,
                      fontSize: 15,
                      fontWeight: equipped != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (equipped != null)
                    Text(
                      _bonusText(equipped!),
                      style: const TextStyle(
                          color: Colors.greenAccent, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (equipped != null)
              TextButton(
                onPressed: onUnequip,
                child: const Text('해제',
                    style: TextStyle(
                        color: Colors.red, fontSize: 12)),
              ),
            if (inventory.isNotEmpty)
              TextButton(
                onPressed: () =>
                    _showEquipDialog(context, inventory),
                child: Text(equipped != null ? '교체' : '장착',
                    style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  void _showEquipDialog(
      BuildContext context, List<Equipment> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0A2E),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          const Text('장비 선택',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final eq in items)
            ListTile(
              title: Text(eq.name,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(_bonusText(eq),
                  style: const TextStyle(
                      color: Colors.greenAccent, fontSize: 12)),
              onTap: () {
                onEquip(eq);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
