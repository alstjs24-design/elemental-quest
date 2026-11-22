import '../enums/element_type.dart';
import '../enums/enemy_intention.dart';
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

  // Returns the enemy's most likely next action — deterministic per turn so the
  // player can learn the pattern. Boss low-HP overrides to special more often.
  EnemyIntention calculateIntention(int turnNumber) {
    final hpRatio = currentHp / maxHp;
    if (grade == EnemyGrade.boss && hpRatio < 0.3 && skills.isNotEmpty) {
      return turnNumber.isOdd ? EnemyIntention.special : EnemyIntention.attack;
    }
    switch (tendency) {
      case BattleTendency.aggressive:
        return (turnNumber % 3 == 0) ? EnemyIntention.defend : EnemyIntention.attack;
      case BattleTendency.defensive:
        return (turnNumber % 3 == 0) ? EnemyIntention.attack : EnemyIntention.defend;
      case BattleTendency.evasive:
        return turnNumber.isOdd ? EnemyIntention.special : EnemyIntention.attack;
      case BattleTendency.unpredictable:
        return EnemyIntention.confused;
    }
  }
}
