// Callers: character_screen.dart (Navigator.push)
// Purpose: Two-tab crafting UI — material recipes + equipment fusion
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/equipment.dart';
import '../character/inventory_notifier.dart';
import 'crafting_recipes.dart';
import 'material_notifier.dart';

const _uuid = Uuid();

class CraftingScreen extends ConsumerStatefulWidget {
  const CraftingScreen({super.key});

  @override
  ConsumerState<CraftingScreen> createState() => _CraftingScreenState();
}

class _CraftingScreenState extends ConsumerState<CraftingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(materialProvider.notifier).load());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('⚗️ 장비 합성', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: const Color(0xFFE07840),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: '소재 제작'),
            Tab(text: '장비 합성'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _MaterialCraftTab(),
          _FusionTab(),
        ],
      ),
    );
  }
}

// ── Material craft tab ────────────────────────────────────────────────────────

class _MaterialCraftTab extends ConsumerWidget {
  const _MaterialCraftTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matState = ref.watch(materialProvider);
    final inv = ref.watch(inventoryProvider);

    // Group materials by typeId for display
    final counts = <String, int>{};
    for (final m in matState.items) {
      counts[m.typeId] = (counts[m.typeId] ?? 0) + 1;
    }

    return Column(
      children: [
        // Material bag header
        if (matState.items.isNotEmpty)
          _MaterialBag(counts: counts),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: kMaterialRecipes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final recipe = kMaterialRecipes[i];
              final canCraft = recipe.ingredients.entries
                  .every((e) => (counts[e.key] ?? 0) >= e.value);
              // Skip if result already exists in inventory (by id)
              final alreadyOwned = inv.items.any((e) => e.id == recipe.result.id);

              return _RecipeCard(
                recipe: recipe,
                counts: counts,
                canCraft: canCraft && !alreadyOwned,
                alreadyOwned: alreadyOwned,
                onCraft: canCraft && !alreadyOwned
                    ? () => _craft(context, ref, recipe)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _craft(
      BuildContext context, WidgetRef ref, MaterialRecipe recipe) async {
    for (final entry in recipe.ingredients.entries) {
      final ok =
          await ref.read(materialProvider.notifier).consume(entry.key, entry.value);
      if (!ok) return;
    }
    await ref.read(inventoryProvider.notifier).addEquipment(recipe.result);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ ${recipe.result.name} 제작 완료!'),
        backgroundColor: const Color(0xFF4A90D9),
        duration: const Duration(seconds: 2),
      ));
    }
  }
}

class _MaterialBag extends StatelessWidget {
  final Map<String, int> counts;
  const _MaterialBag({required this.counts});

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('보유 소재',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: entries.map((e) {
              final typeId = e.key;
              final icon = _iconForType(typeId);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$icon ${_labelForType(typeId)} ×${e.value}',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 12)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _iconForType(String typeId) {
    if (typeId.startsWith('fire'))  return '🔥';
    if (typeId.startsWith('water')) return '💧';
    if (typeId.startsWith('earth')) return '🪨';
    if (typeId.startsWith('wind'))  return '🌀';
    return '⬜';
  }

  String _labelForType(String typeId) {
    final parts = typeId.split('_');
    final elemLabel = switch (parts[0]) {
      'fire'  => '불꽃',
      'water' => '물의',
      'earth' => '대지의',
      'wind'  => '바람의',
      _       => '무속성',
    };
    final typeLabel = switch (parts.last) {
      'shard'   => '파편',
      'crystal' => '결정',
      'essence' => '정수',
      _         => '소재',
    };
    return '$elemLabel $typeLabel';
  }
}

class _RecipeCard extends StatelessWidget {
  final MaterialRecipe recipe;
  final Map<String, int> counts;
  final bool canCraft;
  final bool alreadyOwned;
  final VoidCallback? onCraft;

  const _RecipeCard({
    required this.recipe,
    required this.counts,
    required this.canCraft,
    required this.alreadyOwned,
    required this.onCraft,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(recipe.result.rarity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: (canCraft ? rarityColor : Colors.white24)
                .withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Equipment icon block
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rarityColor.withValues(alpha: 0.3),
                  rarityColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: rarityColor.withValues(alpha: 0.6)),
            ),
            child: Center(
              child: Text(_slotIcon(recipe.result.slot),
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(recipe.name,
                        style: TextStyle(
                            color: rarityColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    _RarityBadge(rarity: recipe.result.rarity),
                  ],
                ),
                const SizedBox(height: 2),
                Text(_statText(recipe.result),
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 11)),
                const SizedBox(height: 6),
                // Ingredients
                Wrap(
                  spacing: 6,
                  children: recipe.ingredients.entries.map((e) {
                    final have = counts[e.key] ?? 0;
                    final enough = have >= e.value;
                    return Text('${_ingredientIcon(e.key)} ${e.value}',
                        style: TextStyle(
                            color: enough
                                ? Colors.white70
                                : Colors.red.shade300,
                            fontSize: 12));
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          alreadyOwned
              ? const Column(children: [
                  Text('✅', style: TextStyle(fontSize: 18)),
                  Text('보유중',
                      style: TextStyle(color: Colors.white38, fontSize: 10)),
                ])
              : ElevatedButton(
                  onPressed: onCraft,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canCraft ? rarityColor : Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('제작', style: TextStyle(fontSize: 13)),
                ),
        ],
      ),
    );
  }

  String _slotIcon(EquipmentSlot slot) => switch (slot) {
    EquipmentSlot.weapon    => '⚔️',
    EquipmentSlot.armor     => '🛡️',
    EquipmentSlot.accessory => '💍',
  };

  String _ingredientIcon(String typeId) {
    if (typeId.startsWith('fire'))  return '🔥';
    if (typeId.startsWith('water')) return '💧';
    if (typeId.startsWith('earth')) return '🪨';
    return '🌀';
  }

  String _statText(Equipment eq) {
    final parts = <String>[];
    if (eq.attackBonus > 0)  parts.add('공격 +${eq.attackBonus}');
    if (eq.defenseBonus > 0) parts.add('방어 +${eq.defenseBonus}');
    if (eq.hpBonus > 0)      parts.add('HP +${eq.hpBonus}');
    if (eq.speedBonus > 0)   parts.add('속도 +${eq.speedBonus}');
    return parts.join('  ');
  }

  Color _rarityColor(EquipmentRarity r) => switch (r) {
    EquipmentRarity.common => Colors.white54,
    EquipmentRarity.rare   => const Color(0xFF42A5F5),
    EquipmentRarity.hero   => const Color(0xFFCE93D8),
    EquipmentRarity.legend => const Color(0xFFFFD700),
  };
}

// ── Fusion tab ────────────────────────────────────────────────────────────────

class _FusionTab extends ConsumerWidget {
  const _FusionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(inventoryProvider);
    // Build fusable pairs: same slot + same rarity, not legend
    final groups = <String, List<Equipment>>{};
    for (final eq in inv.items) {
      if (eq.rarity == EquipmentRarity.legend) continue;
      final key = '${eq.slot.index}_${eq.rarity.index}';
      groups.putIfAbsent(key, () => []).add(eq);
    }
    final fusable =
        groups.entries.where((e) => e.value.length >= 2).toList();

    if (fusable.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('⚗️', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text(
                '같은 슬롯 + 같은 등급 장비 2개가\n있으면 합성할 수 있어요.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '일반 ×2 → 희귀\n희귀 ×2 → 영웅\n영웅 ×2 → 전설',
                style: TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: fusable.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final items = fusable[i].value;
        final sample = items.first;
        final nextRarity = fusionResultRarity(sample.rarity)!;
        return _FusionCard(
          items: items,
          nextRarity: nextRarity,
          onFuse: () => _fuse(context, ref, items, nextRarity),
        );
      },
    );
  }

  Future<void> _fuse(BuildContext context, WidgetRef ref,
      List<Equipment> items, EquipmentRarity nextRarity) async {
    // Pick the two with the best combined stats to consume
    final sorted = List<Equipment>.from(items)
      ..sort((a, b) => _totalStats(a).compareTo(_totalStats(b)));
    final toRemove = sorted.take(2).toList();
    final base = toRemove[1]; // higher-stat one as the base name

    for (final eq in toRemove) {
      await ref.read(inventoryProvider.notifier).removeEquipment(eq.id);
    }

    final fused = Equipment(
      id: _uuid.v4(),
      name: '${rarityLabel(nextRarity)} ${base.name}',
      slot: base.slot,
      rarity: nextRarity,
      element: base.element,
      attackBonus:  (base.attackBonus  * 1.6).round(),
      defenseBonus: (base.defenseBonus * 1.6).round(),
      hpBonus:      (base.hpBonus      * 1.6).round(),
      speedBonus:   (base.speedBonus   * 1.6).round(),
    );
    await ref.read(inventoryProvider.notifier).addEquipment(fused);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✨ ${fused.name} 합성 완료!'),
        backgroundColor: const Color(0xFF9C27B0),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  int _totalStats(Equipment eq) =>
      eq.attackBonus + eq.defenseBonus + eq.hpBonus + eq.speedBonus;
}

class _FusionCard extends StatelessWidget {
  final List<Equipment> items;
  final EquipmentRarity nextRarity;
  final VoidCallback onFuse;

  const _FusionCard(
      {required this.items,
      required this.nextRarity,
      required this.onFuse});

  @override
  Widget build(BuildContext context) {
    final sample = items.first;
    final fromColor = _rarityColor(sample.rarity);
    final toColor = _rarityColor(nextRarity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: toColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Visual: 2 items → arrow → result
          Text(_slotIcon(sample.slot), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 4),
          Text('×${items.length}',
              style: TextStyle(color: fromColor, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          const Text('→',
              style: TextStyle(color: Colors.white38, fontSize: 18)),
          const SizedBox(width: 6),
          Text(_slotIcon(sample.slot), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${rarityLabel(sample.rarity)} ${_slotName(sample.slot)}',
                      style: TextStyle(color: fromColor, fontSize: 13),
                    ),
                    const Text(' → ',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                    Text(
                      rarityLabel(nextRarity),
                      style: TextStyle(
                          color: toColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text('스탯 ×1.6 상승',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 11)),
                Text('보유: ${items.length}개',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: items.length >= 2 ? onFuse : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: toColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('합성', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _slotIcon(EquipmentSlot slot) => switch (slot) {
    EquipmentSlot.weapon    => '⚔️',
    EquipmentSlot.armor     => '🛡️',
    EquipmentSlot.accessory => '💍',
  };

  String _slotName(EquipmentSlot slot) => switch (slot) {
    EquipmentSlot.weapon    => '무기',
    EquipmentSlot.armor     => '방어구',
    EquipmentSlot.accessory => '악세서리',
  };

  Color _rarityColor(EquipmentRarity r) => switch (r) {
    EquipmentRarity.common => Colors.white54,
    EquipmentRarity.rare   => const Color(0xFF42A5F5),
    EquipmentRarity.hero   => const Color(0xFFCE93D8),
    EquipmentRarity.legend => const Color(0xFFFFD700),
  };
}

class _RarityBadge extends StatelessWidget {
  final EquipmentRarity rarity;
  const _RarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    final color = switch (rarity) {
      EquipmentRarity.common => Colors.white38,
      EquipmentRarity.rare   => const Color(0xFF42A5F5),
      EquipmentRarity.hero   => const Color(0xFFCE93D8),
      EquipmentRarity.legend => const Color(0xFFFFD700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(rarityLabel(rarity),
          style: TextStyle(color: color, fontSize: 10)),
    );
  }
}
