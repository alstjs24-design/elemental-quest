import '../enums/element_type.dart';
import 'skill.dart';

enum EnemyGrade { normal, elite, boss }

enum BattleTendency { aggressive, defensive, evasive, unpredictable }

class Enemy {
  final String id;
  final String name;
  final ElementType element;
  final EnemyGrade grade;
  final int maxHp;
  final int attack;
  final int defense;
  final int speed;
  final List<Skill> skills;
  final int expReward;
  final double goldReward;
  final BattleTendency tendency;

  int currentHp;

  Enemy({
    required this.id,
    required this.name,
    required this.element,
    required this.grade,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.skills,
    required this.expReward,
    required this.goldReward,
    this.tendency = BattleTendency.unpredictable,
  }) : currentHp = maxHp;

  bool get isAlive => currentHp > 0;
}
