// Callers: crafting_screen.dart, battle_screen.dart (addDrops), dungeon_screen.dart (load)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/enums/element_type.dart';
import '../../core/models/material_item.dart';
import '../../core/models/enemy.dart';
import 'material_save.dart';

const _uuid = Uuid();

class MaterialState {
  final List<MaterialItem> items;
  final bool isLoaded;

  const MaterialState({this.items = const [], this.isLoaded = false});

  MaterialState copyWith({List<MaterialItem>? items, bool? isLoaded}) =>
      MaterialState(items: items ?? this.items, isLoaded: isLoaded ?? this.isLoaded);

  /// Count of a specific typeId in the bag.
  int countOf(String typeId) => items.where((m) => m.typeId == typeId).length;
}

class MaterialNotifier extends StateNotifier<MaterialState> {
  MaterialNotifier() : super(const MaterialState());

  Future<void> load() async {
    await MaterialSave.init();
    final items = MaterialSave.loadMaterials();
    state = MaterialState(items: items, isLoaded: true);
  }

  Future<void> addDrops(List<MaterialItem> drops) async {
    final updated = [...state.items, ...drops];
    state = state.copyWith(items: updated);
    await MaterialSave.saveMaterials(updated);
  }

  /// Remove [count] items of [typeId]; returns false if not enough.
  Future<bool> consume(String typeId, int count) async {
    final matching = state.items.where((m) => m.typeId == typeId).take(count).toList();
    if (matching.length < count) return false;
    final ids = matching.map((m) => m.id).toSet();
    final updated = state.items.where((m) => !ids.contains(m.id)).toList();
    state = state.copyWith(items: updated);
    await MaterialSave.saveMaterials(updated);
    return true;
  }
}

final materialProvider =
    StateNotifierProvider<MaterialNotifier, MaterialState>((ref) => MaterialNotifier());

// ── Drop generation ──────────────────────────────────────────────────────────

List<MaterialItem> generateEnemyDrops(Enemy enemy) {
  final drops = <MaterialItem>[];
  final count = switch (enemy.grade) {
    EnemyGrade.boss  => 2,
    EnemyGrade.elite => 1,
    _                => 1,
  };
  final rarity = switch (enemy.grade) {
    EnemyGrade.boss  => MaterialRarity.rare,
    EnemyGrade.elite => MaterialRarity.rare,
    _                => MaterialRarity.common,
  };
  for (int i = 0; i < count; i++) {
    final elem = enemy.element == ElementType.none
        ? ElementType.values[(enemy.id.codeUnitAt(0) % 4)]
        : enemy.element;
    drops.add(MaterialItem(
      id:      _uuid.v4(),
      typeId:  materialTypeId(elem, rarity),
      name:    materialName(elem, rarity),
      element: elem,
      rarity:  rarity,
      icon:    materialIcon(elem, rarity),
    ));
  }
  return drops;
}
