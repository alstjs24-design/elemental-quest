import '../../core/enums/element_type.dart';
import '../../core/models/character.dart';
import '../../core/models/enemy.dart';
import '../../core/models/skill.dart';

enum BattleActionType { attack, skill, defend, flee }

class BattleAction {
  final BattleActionType type;
  final Skill? skill;

  const BattleAction({required this.type, this.skill});

  static const BattleAction basicAttack = BattleAction(type: BattleActionType.attack);
  static const BattleAction defend = BattleAction(type: BattleActionType.defend);
  static const BattleAction flee = BattleAction(type: BattleActionType.flee);
  static BattleAction useSkill(Skill s) => BattleAction(type: BattleActionType.skill, skill: s);
}

enum RpsChoice { attack, defense, evasion }

class RpsResult {
  final RpsChoice playerChoice;
  final RpsChoice enemyChoice;
  final int playerDamageDealt;
  final int enemyDamageDealt;
  final String message;
  final String? comboMessage;

  const RpsResult({
    required this.playerChoice,
    required this.enemyChoice,
    required this.playerDamageDealt,
    required this.enemyDamageDealt,
    required this.message,
    this.comboMessage,
  });
}

class BattleResult {
  final String actorName;
  final String targetName;
  final int damage;
  final int healing;
  final String message;
  final bool isCritical;
  final double elementMultiplier;

  const BattleResult({
    required this.actorName,
    required this.targetName,
    this.damage = 0,
    this.healing = 0,
    required this.message,
    this.isCritical = false,
    this.elementMultiplier = 1.0,
  });
}

class BattleEngine {
  static const double criticalMultiplier = 1.5;
  static const int criticalChancePercent = 15;

  static BattleResult executePlayerAction({
    required Character player,
    required Enemy enemy,
    required BattleAction action,
  }) {
    switch (action.type) {
      case BattleActionType.attack:
        return _basicAttack(
          actorName: player.name,
          actorAttack: player.stats.attack,
          actorElement: player.element,
          targetName: enemy.name,
          targetDefense: enemy.defense,
          targetElement: enemy.element,
          target: enemy,
        );
      case BattleActionType.skill:
        return _useSkill(
          actor: player,
          target: enemy,
          skill: action.skill!,
        );
      case BattleActionType.defend:
        return BattleResult(
          actorName: player.name,
          targetName: player.name,
          message: '${player.name}이(가) 방어 태세를 취했습니다.',
        );
      case BattleActionType.flee:
        return BattleResult(
          actorName: player.name,
          targetName: enemy.name,
          message: '도망치려 합니다...',
        );
    }
  }

  static BattleResult executeEnemyAction({
    required Enemy enemy,
    required Character player,
  }) {
    if (enemy.skills.isNotEmpty && _shouldUseSkill(enemy)) {
      final skill = enemy.skills[0];
      return _useSkillOnCharacter(
        actorName: enemy.name,
        actorAttack: enemy.attack,
        actorElement: enemy.element,
        target: player,
        skill: skill,
      );
    }
    return _basicAttack(
      actorName: enemy.name,
      actorAttack: enemy.attack,
      actorElement: enemy.element,
      targetName: player.name,
      targetDefense: player.stats.defense,
      targetElement: player.element,
      target: player,
    );
  }

  static BattleResult _basicAttack({
    required String actorName,
    required int actorAttack,
    required ElementType actorElement,
    required String targetName,
    required int targetDefense,
    required ElementType targetElement,
    required dynamic target,
  }) {
    final multiplier = actorElement.damageMultiplier(targetElement);
    final isCrit = _rollCritical();
    final critMult = isCrit ? criticalMultiplier : 1.0;

    final raw = (actorAttack - targetDefense * 0.5).clamp(1, double.infinity);
    final damage = (raw * multiplier * critMult).round();

    _applyDamage(target, damage);

    final elementMsg = multiplier > 1.0
        ? ' 효과가 뛰어납니다!'
        : multiplier < 1.0
            ? ' 효과가 별로입니다...'
            : '';
    final critMsg = isCrit ? ' 치명타!' : '';

    return BattleResult(
      actorName: actorName,
      targetName: targetName,
      damage: damage,
      message: '$actorName의 공격! $damage 데미지!$elementMsg$critMsg',
      isCritical: isCrit,
      elementMultiplier: multiplier,
    );
  }

  static BattleResult _useSkill({
    required Character actor,
    required Enemy target,
    required Skill skill,
  }) {
    if (actor.currentMp < skill.mpCost) {
      return BattleResult(
        actorName: actor.name,
        targetName: target.name,
        message: 'MP가 부족합니다! (필요: ${skill.mpCost}, 현재: ${actor.currentMp})',
      );
    }

    actor.currentMp -= skill.mpCost;
    final multiplier = skill.element.damageMultiplier(target.element);

    if (skill.type == SkillType.heal) {
      final healing = (skill.basePower * (1 + actor.level * 0.05)).round();
      actor.currentHp = (actor.currentHp + healing).clamp(0, actor.stats.maxHp);
      return BattleResult(
        actorName: actor.name,
        targetName: actor.name,
        healing: healing,
        message: '${skill.name}! ${actor.name} HP +$healing 회복!',
      );
    }

    final isCrit = _rollCritical();
    final raw = (skill.basePower + actor.stats.attack * 0.5) - target.defense * 0.3;
    final damage = (raw.clamp(1, double.infinity) * multiplier * (isCrit ? criticalMultiplier : 1.0)).round();

    _applyDamage(target, damage);

    final elementMsg = multiplier > 1.0 ? ' 효과가 뛰어납니다!' : multiplier < 1.0 ? ' 효과가 별로입니다...' : '';
    final critMsg = isCrit ? ' 치명타!' : '';

    return BattleResult(
      actorName: actor.name,
      targetName: target.name,
      damage: damage,
      message: '${skill.name}! $damage 데미지!$elementMsg$critMsg',
      isCritical: isCrit,
      elementMultiplier: multiplier,
    );
  }

  static BattleResult _useSkillOnCharacter({
    required String actorName,
    required int actorAttack,
    required ElementType actorElement,
    required Character target,
    required Skill skill,
  }) {
    final multiplier = actorElement.damageMultiplier(target.element);
    final raw = (skill.basePower + actorAttack * 0.5) - target.stats.defense * 0.3;
    final damage = (raw.clamp(1, double.infinity) * multiplier).round();

    _applyDamage(target, damage);

    return BattleResult(
      actorName: actorName,
      targetName: target.name,
      damage: damage,
      message: '${skill.name}! $damage 데미지!',
      elementMultiplier: multiplier,
    );
  }

  static void _applyDamage(dynamic target, int damage) {
    target.currentHp = (target.currentHp - damage).clamp(0, target.currentHp);
  }

  static bool _rollCritical() {
    return (DateTime.now().millisecondsSinceEpoch % 100) < criticalChancePercent;
  }

  static bool _shouldUseSkill(Enemy enemy) {
    return (DateTime.now().millisecondsSinceEpoch % 3) == 0;
  }

  static bool tryFlee({required int playerSpeed, required int enemySpeed}) {
    final chance = (playerSpeed / (playerSpeed + enemySpeed) * 100).round();
    return (DateTime.now().millisecondsSinceEpoch % 100) < chance;
  }

  static RpsResult resolveRps({
    required RpsChoice playerChoice,
    required RpsChoice enemyChoice,
    required Character player,
    required Enemy enemy,
  }) {
    final outcome = _rpsOutcome(playerChoice, enemyChoice);
    final elemMult = player.element.damageMultiplier(enemy.element);
    int playerDmg = 0;
    int enemyDmg = 0;
    String msg;
    String? comboMsg;

    if (outcome == 1) {
      // Player wins — check win combos
      final raw = (player.stats.attack - enemy.defense * 0.5).clamp(1, double.infinity);
      double bonusMult = 1.0;

      if (player.element == ElementType.fire && playerChoice == RpsChoice.attack) {
        // 🔥 화염 폭발: damage ×1.5
        bonusMult = 1.5;
        comboMsg = '🔥 화염 폭발! 속성 콤보 발동!';
      } else if (player.element == ElementType.wind && playerChoice == RpsChoice.evasion) {
        // 💨 질풍 반격: win + extra 50% counter
        bonusMult = 1.5;
        comboMsg = '💨 질풍 반격! 속성 콤보 발동!';
      }

      playerDmg = (raw * elemMult * bonusMult).round();
      _applyDamage(enemy, playerDmg);
      msg = '${_choiceName(playerChoice)} ▶ ${_choiceName(enemyChoice)} 승! ${enemy.name} $playerDmg 피해!';

      // 💧 냉기 흡수: defense win → heal
      if (player.element == ElementType.water && playerChoice == RpsChoice.defense) {
        final heal = (player.stats.maxHp * 0.10).round().clamp(1, player.stats.maxHp);
        player.currentHp = (player.currentHp + heal).clamp(0, player.stats.maxHp);
        comboMsg = '💧 냉기 흡수! HP +$heal 회복! 속성 콤보 발동!';
      }
    } else if (outcome == -1) {
      // Player loses — check loss combos
      final raw = (enemy.attack - player.stats.defense * 0.5).clamp(1, double.infinity);
      double damageReduction = 1.0;

      if (player.element == ElementType.earth && playerChoice == RpsChoice.defense) {
        // 🌿 대지 갑옷: defense loss → 60% damage reduction
        damageReduction = 0.4;
        comboMsg = '🌿 대지 갑옷! 받는 피해 60% 감소! 속성 콤보 발동!';
      }

      enemyDmg = (raw * damageReduction).round().clamp(1, 9999);
      _applyDamage(player, enemyDmg);
      msg = '${_choiceName(enemyChoice)} ▶ ${_choiceName(playerChoice)} 패! ${player.name} $enemyDmg 피해!';
    } else if (playerChoice == RpsChoice.attack) {
      final pRaw = (player.stats.attack - enemy.defense * 0.5).clamp(1, double.infinity);
      playerDmg = (pRaw * elemMult).round();
      final eRaw = (enemy.attack - player.stats.defense * 0.5).clamp(1, double.infinity);
      enemyDmg = eRaw.round();
      _applyDamage(enemy, playerDmg);
      _applyDamage(player, enemyDmg);
      msg = '공격 vs 공격! 상호 피해 — 나 $playerDmg / 적 $enemyDmg';
    } else {
      msg = '${_choiceName(playerChoice)} vs ${_choiceName(enemyChoice)} — 무승부. 아무 일도 없었다.';
    }

    return RpsResult(
      playerChoice: playerChoice,
      enemyChoice: enemyChoice,
      playerDamageDealt: playerDmg,
      enemyDamageDealt: enemyDmg,
      message: msg,
      comboMessage: comboMsg,
    );
  }

  static int _rpsOutcome(RpsChoice a, RpsChoice b) {
    if (a == b) return 0;
    if ((a == RpsChoice.attack && b == RpsChoice.evasion) ||
        (a == RpsChoice.defense && b == RpsChoice.attack) ||
        (a == RpsChoice.evasion && b == RpsChoice.defense)) {
      return 1;
    }
    return -1;
  }

  static String _choiceName(RpsChoice c) => switch (c) {
    RpsChoice.attack  => '⚔️ 공격',
    RpsChoice.defense => '🛡️ 방어',
    RpsChoice.evasion => '💨 회피',
  };
}
