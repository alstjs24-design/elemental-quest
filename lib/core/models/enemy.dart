import '../enums/element_type.dart';
import 'skill.dart';

enum EnemyGrade { normal, elite, boss }

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
  }) : currentHp = maxHp;

  bool get isAlive => currentHp > 0;
}
