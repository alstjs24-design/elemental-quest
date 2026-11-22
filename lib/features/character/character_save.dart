import 'package:hive_flutter/hive_flutter.dart';
import '../../core/enums/character_trait.dart';
import '../../core/enums/element_type.dart';
import '../../core/models/character.dart';
import '../../core/models/equipment.dart';

const _boxName = 'characters';
const _equipBoxName = 'equipment';

class CharacterSave {
  static Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
    await Hive.openBox<Map>(_equipBoxName);
  }

  static Future<void> saveCharacter(Character character) async {
    final box = Hive.box<Map>(_boxName);
    await box.put(character.id, _serializeCharacter(character));
  }

  static Character? loadCharacter(String id) {
    final box = Hive.box<Map>(_boxName);
    final data = box.get(id);
    if (data == null) return null;
    return _deserializeCharacter(Map<String, dynamic>.from(data));
  }

  static List<Character> loadAllCharacters() {
    final box = Hive.box<Map>(_boxName);
    return box.values
        .map((v) => _deserializeCharacter(Map<String, dynamic>.from(v)))
        .toList();
  }

  static Future<void> saveEquipment(List<Equipment> inventory) async {
    final box = Hive.box<Map>(_equipBoxName);
    await box.clear();
    for (final eq in inventory) {
      await box.put(eq.id, _serializeEquipment(eq));
    }
  }

  static List<Equipment> loadEquipment() {
    final box = Hive.box<Map>(_equipBoxName);
    return box.values
        .map((v) => _deserializeEquipment(Map<String, dynamic>.from(v)))
        .toList();
  }

  static Map<String, dynamic> _serializeCharacter(Character c) => {
    'id': c.id,
    'name': c.name,
    'trait': c.trait.index,
    'rarity': c.rarity.index,
    'level': c.level,
    'exp': c.exp,
    'currentHp': c.currentHp,
    'currentMp': c.currentMp,
    'baseMaxHp': c.baseStats.maxHp,
    'baseMaxMp': c.baseStats.maxMp,
    'baseAttack': c.baseStats.attack,
    'baseDefense': c.baseStats.defense,
    'baseSpeed': c.baseStats.speed,
  };

  static Character _deserializeCharacter(Map<String, dynamic> d) {
    final stats = CharacterStats(
      maxHp: d['baseMaxHp'] as int,
      maxMp: d['baseMaxMp'] as int,
      attack: d['baseAttack'] as int,
      defense: d['baseDefense'] as int,
      speed: d['baseSpeed'] as int,
    );
    final character = Character(
      id: d['id'] as String,
      name: d['name'] as String,
      trait: CharacterTrait.values[(d['trait'] ?? 0) as int],
      rarity: Rarity.values[d['rarity'] as int],
      baseStats: stats,
      skills: [],
      level: d['level'] as int,
      exp: d['exp'] as int,
    );
    character.currentHp = d['currentHp'] as int;
    character.currentMp = d['currentMp'] as int;
    return character;
  }

  static Map<String, dynamic> _serializeEquipment(Equipment e) => {
    'id': e.id,
    'name': e.name,
    'slot': e.slot.index,
    'rarity': e.rarity.index,
    'element': e.element.index,
    'hpBonus': e.hpBonus,
    'attackBonus': e.attackBonus,
    'defenseBonus': e.defenseBonus,
    'speedBonus': e.speedBonus,
  };

  static Equipment _deserializeEquipment(Map<String, dynamic> d) => Equipment(
    id: d['id'] as String,
    name: d['name'] as String,
    slot: EquipmentSlot.values[d['slot'] as int],
    rarity: EquipmentRarity.values[d['rarity'] as int],
    element: ElementType.values[d['element'] as int],
    hpBonus: d['hpBonus'] as int,
    attackBonus: d['attackBonus'] as int,
    defenseBonus: d['defenseBonus'] as int,
    speedBonus: d['speedBonus'] as int,
  );
}
