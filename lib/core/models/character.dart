import '../enums/character_trait.dart';
import 'skill.dart';

enum Rarity { common, rare, hero, legend }

class CharacterStats {
  final int maxHp;
  final int maxMp;
  final int attack;
  final int defense;
  final int speed;

  const CharacterStats({
    required this.maxHp,
    required this.maxMp,
    required this.attack,
    required this.defense,
    required this.speed,
  });

  CharacterStats scale(int level) => CharacterStats(
    maxHp:    (maxHp    * (1 + level * 0.1)).round(),
    maxMp:    (maxMp    * (1 + level * 0.08)).round(),
    attack:   (attack   * (1 + level * 0.12)).round(),
    defense:  (defense  * (1 + level * 0.10)).round(),
    speed:    (speed    * (1 + level * 0.05)).round(),
  );
}

class Character {
  final String id;
  final String name;
  final CharacterTrait trait;
  final Rarity rarity;
  final CharacterStats baseStats;
  final List<Skill> skills;

  int level;
  int exp;
  int currentHp;
  int currentMp;

  Character({
    required this.id,
    required this.name,
    required this.trait,
    required this.rarity,
    required this.baseStats,
    required this.skills,
    this.level = 1,
    this.exp = 0,
  })  : currentHp = baseStats.maxHp,
        currentMp = baseStats.maxMp;

  CharacterStats get stats => baseStats.scale(level);

  bool get isAlive => currentHp > 0;

  int get expToNextLevel => level * 100;
}
