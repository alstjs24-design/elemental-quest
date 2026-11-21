import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/element_type.dart';
import '../../core/models/equipment.dart';
import 'character_save.dart';

class InventoryState {
  final List<Equipment> items;
  final bool isLoaded;

  const InventoryState({this.items = const [], this.isLoaded = false});

  InventoryState copyWith({List<Equipment>? items, bool? isLoaded}) =>
      InventoryState(
        items: items ?? this.items,
        isLoaded: isLoaded ?? this.isLoaded,
      );

  List<Equipment> bySlot(EquipmentSlot slot) =>
      items.where((e) => e.slot == slot).toList();
}

class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier() : super(const InventoryState());

  Future<void> load() async {
    var items = CharacterSave.loadEquipment();
    if (items.isEmpty) items = _starterEquipment();
    state = InventoryState(items: items, isLoaded: true);
    await CharacterSave.saveEquipment(items);
  }

  Future<void> addEquipment(Equipment equipment) async {
    final updated = [...state.items, equipment];
    state = state.copyWith(items: updated);
    await CharacterSave.saveEquipment(updated);
  }

  Future<void> removeEquipment(String id) async {
    final updated = state.items.where((e) => e.id != id).toList();
    state = state.copyWith(items: updated);
    await CharacterSave.saveEquipment(updated);
  }

  Future<void> addLoot(List<Equipment> loot) async {
    final updated = [...state.items, ...loot];
    state = state.copyWith(items: updated);
    await CharacterSave.saveEquipment(updated);
  }

  static List<Equipment> _starterEquipment() => [
    const Equipment(
      id: 'starter_sword',
      name: '낡은 검',
      slot: EquipmentSlot.weapon,
      rarity: EquipmentRarity.common,
      element: ElementType.none,
      attackBonus: 10,
    ),
    const Equipment(
      id: 'starter_armor',
      name: '낡은 갑옷',
      slot: EquipmentSlot.armor,
      rarity: EquipmentRarity.common,
      element: ElementType.none,
      defenseBonus: 8,
      hpBonus: 20,
    ),
  ];
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>(
  (ref) => InventoryNotifier(),
);
