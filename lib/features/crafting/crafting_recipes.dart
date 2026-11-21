// Callers: crafting_screen.dart
import '../../core/enums/element_type.dart';
import '../../core/models/equipment.dart';

class MaterialRecipe {
  final String id;
  final String name;
  final String description;
  final Map<String, int> ingredients; // typeId → count
  final Equipment result;

  const MaterialRecipe({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.result,
  });
}

/// Two same-slot same-rarity items → one item of the next rarity.
EquipmentRarity? fusionResultRarity(EquipmentRarity r) => switch (r) {
  EquipmentRarity.common => EquipmentRarity.rare,
  EquipmentRarity.rare   => EquipmentRarity.hero,
  EquipmentRarity.hero   => EquipmentRarity.legend,
  EquipmentRarity.legend => null, // already max
};

String rarityLabel(EquipmentRarity r) => switch (r) {
  EquipmentRarity.common => '일반',
  EquipmentRarity.rare   => '희귀',
  EquipmentRarity.hero   => '영웅',
  EquipmentRarity.legend => '전설',
};

const kMaterialRecipes = <MaterialRecipe>[
  // ── Weapons ──────────────────────────────────────────────────────────────
  MaterialRecipe(
    id: 'fire_weapon',
    name: '불꽃의 검',
    description: '불꽃 파편 3개로 제작',
    ingredients: {'fire_shard': 3},
    result: Equipment(
      id: 'crafted_fire_weapon',
      name: '불꽃의 검',
      slot: EquipmentSlot.weapon,
      rarity: EquipmentRarity.rare,
      element: ElementType.fire,
      attackBonus: 28,
    ),
  ),
  MaterialRecipe(
    id: 'water_weapon',
    name: '냉기의 단검',
    description: '물의 파편 3개로 제작',
    ingredients: {'water_shard': 3},
    result: Equipment(
      id: 'crafted_water_weapon',
      name: '냉기의 단검',
      slot: EquipmentSlot.weapon,
      rarity: EquipmentRarity.rare,
      element: ElementType.water,
      attackBonus: 22,
      speedBonus: 5,
    ),
  ),
  MaterialRecipe(
    id: 'earth_weapon',
    name: '대지의 철퇴',
    description: '대지의 파편 3개로 제작',
    ingredients: {'earth_shard': 3},
    result: Equipment(
      id: 'crafted_earth_weapon',
      name: '대지의 철퇴',
      slot: EquipmentSlot.weapon,
      rarity: EquipmentRarity.rare,
      element: ElementType.earth,
      attackBonus: 32,
    ),
  ),
  MaterialRecipe(
    id: 'wind_weapon',
    name: '질풍의 단검',
    description: '바람의 파편 3개로 제작',
    ingredients: {'wind_shard': 3},
    result: Equipment(
      id: 'crafted_wind_weapon',
      name: '질풍의 단검',
      slot: EquipmentSlot.weapon,
      rarity: EquipmentRarity.rare,
      element: ElementType.wind,
      attackBonus: 20,
      speedBonus: 10,
    ),
  ),
  // ── Armors ───────────────────────────────────────────────────────────────
  MaterialRecipe(
    id: 'fire_armor',
    name: '불꽃의 갑옷',
    description: '불꽃 파편 3개로 제작',
    ingredients: {'fire_shard': 3},
    result: Equipment(
      id: 'crafted_fire_armor',
      name: '불꽃의 갑옷',
      slot: EquipmentSlot.armor,
      rarity: EquipmentRarity.rare,
      element: ElementType.fire,
      defenseBonus: 18,
      hpBonus: 40,
    ),
  ),
  MaterialRecipe(
    id: 'water_armor',
    name: '물의 로브',
    description: '물의 파편 3개로 제작',
    ingredients: {'water_shard': 3},
    result: Equipment(
      id: 'crafted_water_armor',
      name: '물의 로브',
      slot: EquipmentSlot.armor,
      rarity: EquipmentRarity.rare,
      element: ElementType.water,
      defenseBonus: 14,
      hpBonus: 60,
    ),
  ),
  MaterialRecipe(
    id: 'earth_armor',
    name: '대지의 갑옷',
    description: '대지의 파편 3개로 제작',
    ingredients: {'earth_shard': 3},
    result: Equipment(
      id: 'crafted_earth_armor',
      name: '대지의 갑옷',
      slot: EquipmentSlot.armor,
      rarity: EquipmentRarity.rare,
      element: ElementType.earth,
      defenseBonus: 24,
      hpBonus: 50,
    ),
  ),
  MaterialRecipe(
    id: 'wind_armor',
    name: '바람의 망토',
    description: '바람의 파편 3개로 제작',
    ingredients: {'wind_shard': 3},
    result: Equipment(
      id: 'crafted_wind_armor',
      name: '바람의 망토',
      slot: EquipmentSlot.armor,
      rarity: EquipmentRarity.rare,
      element: ElementType.wind,
      defenseBonus: 12,
      hpBonus: 30,
      speedBonus: 8,
    ),
  ),
  // ── Boss-tier accessories ─────────────────────────────────────────────────
  MaterialRecipe(
    id: 'fire_accessory',
    name: '불꽃 반지',
    description: '불꽃 결정 2개 + 불꽃 파편 1개',
    ingredients: {'fire_crystal': 2, 'fire_shard': 1},
    result: Equipment(
      id: 'crafted_fire_accessory',
      name: '불꽃 반지',
      slot: EquipmentSlot.accessory,
      rarity: EquipmentRarity.hero,
      element: ElementType.fire,
      attackBonus: 15,
      speedBonus: 6,
    ),
  ),
  MaterialRecipe(
    id: 'water_accessory',
    name: '물의 목걸이',
    description: '물의 결정 2개 + 물의 파편 1개',
    ingredients: {'water_crystal': 2, 'water_shard': 1},
    result: Equipment(
      id: 'crafted_water_accessory',
      name: '물의 목걸이',
      slot: EquipmentSlot.accessory,
      rarity: EquipmentRarity.hero,
      element: ElementType.water,
      hpBonus: 60,
      defenseBonus: 10,
    ),
  ),
  MaterialRecipe(
    id: 'earth_accessory',
    name: '대지의 보석',
    description: '대지의 결정 2개 + 대지의 파편 1개',
    ingredients: {'earth_crystal': 2, 'earth_shard': 1},
    result: Equipment(
      id: 'crafted_earth_accessory',
      name: '대지의 보석',
      slot: EquipmentSlot.accessory,
      rarity: EquipmentRarity.hero,
      element: ElementType.earth,
      defenseBonus: 18,
      hpBonus: 40,
    ),
  ),
  MaterialRecipe(
    id: 'wind_accessory',
    name: '바람의 깃털',
    description: '바람의 결정 2개 + 바람의 파편 1개',
    ingredients: {'wind_crystal': 2, 'wind_shard': 1},
    result: Equipment(
      id: 'crafted_wind_accessory',
      name: '바람의 깃털',
      slot: EquipmentSlot.accessory,
      rarity: EquipmentRarity.hero,
      element: ElementType.wind,
      speedBonus: 20,
      attackBonus: 10,
    ),
  ),
];
