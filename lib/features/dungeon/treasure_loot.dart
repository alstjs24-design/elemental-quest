// Callers: lib/features/dungeon/dungeon_screen.dart (_enterRoom, RoomType.treasure)
// Purpose: Generate random equipment loot for treasure rooms
// Pure functions — no state read/write
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../core/enums/element_type.dart';
import '../../core/models/equipment.dart';

final _rng = Random();
const _uuid = Uuid();

Equipment generateTreasureLoot(int floor) {
  final slot = EquipmentSlot.values[_rng.nextInt(EquipmentSlot.values.length)];
  final rarity = _pickRarity(floor);
  final element = _pickElement();
  final mult = _rarityMult(rarity);

  return Equipment(
    id: _uuid.v4(),
    name: _name(slot, rarity, element),
    slot: slot,
    rarity: rarity,
    element: element,
    attackBonus:  slot == EquipmentSlot.weapon   ? _stat(floor, mult, 8, 20)  : 0,
    defenseBonus: slot == EquipmentSlot.armor     ? _stat(floor, mult, 6, 15)  : 0,
    hpBonus:      slot == EquipmentSlot.armor     ? _stat(floor, mult, 15, 40) : 0,
    speedBonus:   slot == EquipmentSlot.accessory ? _stat(floor, mult, 2, 8)   : 0,
  );
}

EquipmentRarity _pickRarity(int floor) {
  final roll = _rng.nextDouble();
  if (floor >= 5 && roll < 0.05) return EquipmentRarity.legend;
  if (floor >= 3 && roll < 0.15) return EquipmentRarity.hero;
  if (roll < 0.40) return EquipmentRarity.rare;
  return EquipmentRarity.common;
}

ElementType _pickElement() {
  final pool = [
    ElementType.fire, ElementType.water,
    ElementType.earth, ElementType.wind, ElementType.none,
  ];
  return pool[_rng.nextInt(pool.length)];
}

double _rarityMult(EquipmentRarity r) => switch (r) {
  EquipmentRarity.common => 1.0,
  EquipmentRarity.rare   => 1.4,
  EquipmentRarity.hero   => 1.9,
  EquipmentRarity.legend => 2.6,
};

int _stat(int floor, double mult, int base, int range) =>
    ((base + _rng.nextInt(range) + floor * 2) * mult).round();

String _name(EquipmentSlot slot, EquipmentRarity rarity, ElementType element) {
  final prefix = switch (rarity) {
    EquipmentRarity.common => '',
    EquipmentRarity.rare   => '정제된 ',
    EquipmentRarity.hero   => '영웅의 ',
    EquipmentRarity.legend => '전설의 ',
  };
  final elem = switch (element) {
    ElementType.fire  => '불꽃 ',
    ElementType.water => '물의 ',
    ElementType.earth => '대지의 ',
    ElementType.wind  => '바람의 ',
    ElementType.none  => '',
  };
  final base = switch (slot) {
    EquipmentSlot.weapon    => '검',
    EquipmentSlot.armor     => '갑옷',
    EquipmentSlot.accessory => '반지',
  };
  return '$prefix$elem$base';
}
