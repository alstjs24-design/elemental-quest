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
    int? effectiveDefense,
  }) {
    final playerDef = effectiveDefense ?? player.stats.defense;
    if (enemy.skills.isNotEmpty && _shouldUseSkill(enemy)) {
      final skill = enemy.skills[0];
      return _useSkillOnCharacter(
        actorName: enemy.name,
        actorAttack: enemy.attack,
        actorElement: enemy.element,
        target: player,
        targetDefense: playerDef,
        skill: skill,
      );
    }
    return _basicAttack(
      actorName: enemy.name,
      actorAttack: enemy.attack,
      actorElement: enemy.element,
      targetName: player.name,
      targetDefense: playerDef,
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
    int? targetDefense,
  }) {
    final multiplier = actorElement.damageMultiplier(target.element);
    final effectiveDef = targetDefense ?? target.stats.defense;
    final raw = (skill.basePower + actorAttack * 0.5) - effectiveDef * 0.3;
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
    int? effectiveAttack,
    int? effectiveDefense,
    bool isCharged = false,
  }) {
    final pAtk = effectiveAttack ?? player.stats.attack;
    final pDef = effectiveDefense ?? player.stats.defense;
    final chargeMult = isCharged ? 2.0 : 1.0;
    final outcome = _rpsOutcome(playerChoice, enemyChoice);
    final elemMult = player.element.damageMultiplier(enemy.element);
    int playerDmg = 0;
    int enemyDmg = 0;
    String msg;
    String? comboMsg;

    if (outcome == 1) {
      // A안: 꿰뚫기 win → 방어 무시 (pierce); 강타 win → ×1.3 보너스
      final effEnemyDef = playerChoice == RpsChoice.evasion ? 0 : enemy.defense;
      double bonusMult = playerChoice == RpsChoice.attack ? 1.3 : 1.0;

      if (player.element == ElementType.fire && playerChoice == RpsChoice.attack) {
        bonusMult = 1.5;
        comboMsg = '🔥 화염 폭발! 속성 콤보 발동!';
      } else if (player.element == ElementType.wind && playerChoice == RpsChoice.evasion) {
        bonusMult = 1.5;
        comboMsg = '💨 질풍 반격! 속성 콤보 발동!';
      }

      if (playerChoice == RpsChoice.defense) {
        // 막아치기 win → 카운터 (공격력의 60%)
        final counter = (pAtk * 0.6).round().clamp(1, 9999);
        playerDmg = (counter * chargeMult).round();
        comboMsg = comboMsg ?? '🗡️ 막아치기 카운터!';
      } else {
        final raw = (pAtk - effEnemyDef * 0.5).clamp(1, double.infinity);
        playerDmg = (raw * elemMult * bonusMult * chargeMult).round();
      }
      _applyDamage(enemy, playerDmg);

      final actionNote = switch (playerChoice) {
        RpsChoice.attack  => ' (강타 보너스!)',
        RpsChoice.evasion => ' (방어 무시!)',
        RpsChoice.defense => ' (카운터!)',
      };
      msg = '${_choiceName(playerChoice)} ▶ ${_choiceName(enemyChoice)} 승! '
          '${enemy.name} $playerDmg 피해!$actionNote';
      if (isCharged) msg = '⚡ 집중 발동! $msg';

      // 💧 냉기 흡수: water+defense win → heal + 카운터
      if (player.element == ElementType.water && playerChoice == RpsChoice.defense) {
        final maxHp = player.stats.maxHp;
        final heal = (maxHp * 0.10).round().clamp(1, maxHp);
        player.currentHp = (player.currentHp + heal).clamp(0, maxHp);
        comboMsg = '💧 냉기 흡수 + 카운터! HP +$heal 회복! 속성 콤보 발동!';
      }
    } else if (outcome == -1) {
      // A안: 행동별 패배 2차 효과
      // 강타 패배: 과공격 패널티 ×1.2 / 막아치기 패배: ×0.6 / 꿰뚫기 패배: 완전 빗나감
      double damageMult = switch (playerChoice) {
        RpsChoice.attack  => 1.2,
        RpsChoice.defense => 0.6,
        RpsChoice.evasion => 0.0,
      };

      // 대지 갑옷 combo: defense loss → 추가 감소
      if (player.element == ElementType.earth && playerChoice == RpsChoice.defense) {
        damageMult = 0.4;
        comboMsg = '🌿 대지 갑옷! 받는 피해 60% 감소! 속성 콤보 발동!';
      }

      if (damageMult > 0) {
        final raw = (enemy.attack - pDef * 0.5).clamp(1, double.infinity);
        enemyDmg = (raw * damageMult).round().clamp(1, 9999);
        _applyDamage(player, enemyDmg);
      }

      final lossNote = switch (playerChoice) {
        RpsChoice.attack  => ' ⚠️ 과공격 패널티',
        RpsChoice.defense => ' (부분 방어됨)',
        RpsChoice.evasion => ' (완전 빗나감, 무피해)',
      };
      msg = '${_choiceName(enemyChoice)} ▶ ${_choiceName(playerChoice)} 패!'
          '${enemyDmg > 0 ? ' ${player.name} $enemyDmg 피해!' : ''}$lossNote';
    } else if (playerChoice == RpsChoice.attack) {
      final pRaw = (pAtk - enemy.defense * 0.5).clamp(1, double.infinity);
      playerDmg = (pRaw * elemMult * chargeMult).round();
      final eRaw = (enemy.attack - pDef * 0.5).clamp(1, double.infinity);
      enemyDmg = eRaw.round();
      _applyDamage(enemy, playerDmg);
      _applyDamage(player, enemyDmg);
      msg = '강타 vs 강타! 상호 피해 — 나 $playerDmg / 적 $enemyDmg';
    } else {
      msg = '${_choiceName(playerChoice)} vs ${_choiceName(enemyChoice)} — 무승부.';
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
    RpsChoice.attack  => '⚔️ 강타',
    RpsChoice.defense => '🛡️ 막아치기',
    RpsChoice.evasion => '💨 꿰뚫기',
  };
}
