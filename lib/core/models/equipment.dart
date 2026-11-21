import '../enums/element_type.dart';

enum EquipmentSlot { weapon, armor, accessory }
enum EquipmentRarity { common, rare, hero, legend }

class Equipment {
  final String id;
  final String name;
  final EquipmentSlot slot;
  final EquipmentRarity rarity;
  final ElementType element;

  // 스탯 보너스
  final int hpBonus;
  final int attackBonus;
  final int defenseBonus;
  final int speedBonus;

  const Equipment({
    required this.id,
    required this.name,
    required this.slot,
    required this.rarity,
    required this.element,
    this.hpBonus = 0,
    this.attackBonus = 0,
    this.defenseBonus = 0,
    this.speedBonus = 0,
  });
}
