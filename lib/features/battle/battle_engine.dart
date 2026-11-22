import 'dart:math';

import '../../core/enums/character_trait.dart';
import '../../core/enums/element_type.dart';
import '../../core/models/character.dart';
import '../../core/models/enemy.dart';
import '../../core/models/skill.dart';

enum RpsChoice { attack, defense, evasion }

class RpsResult {
  final RpsChoice playerChoice;
  final RpsChoice enemyChoice;
  final int playerDamageDealt;
  final int enemyDamageDealt;
  final String message;
  final String? comboMessage;
  final int outcome; // 1=player win, 0=draw, -1=player loss

  const RpsResult({
    required this.playerChoice,
    required this.enemyChoice,
    required this.playerDamageDealt,
    required this.enemyDamageDealt,
    required this.message,
    required this.outcome,
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

final _rng = Random();

class BattleEngine {
  static const double criticalMultiplier = 1.5;
  static const int criticalChancePercent = 15;

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
      targetElement: player.trait.element,
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

  static BattleResult _useSkillOnCharacter({
    required String actorName,
    required int actorAttack,
    required ElementType actorElement,
    required Character target,
    required Skill skill,
    int? targetDefense,
  }) {
    final multiplier = actorElement.damageMultiplier(target.trait.element);
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
    return _rng.nextInt(100) < criticalChancePercent;
  }

  static bool _shouldUseSkill(Enemy enemy) {
    return _rng.nextInt(3) == 0;
  }

  static bool tryFlee({required int playerSpeed, required int enemySpeed}) {
    final chance = (playerSpeed / (playerSpeed + enemySpeed) * 100).round();
    return _rng.nextInt(100) < chance;
  }

  static RpsResult resolveRps({
    required RpsChoice playerChoice,
    required RpsChoice enemyChoice,
    required Character player,
    required Enemy enemy,
    int? effectiveAttack,
    int? effectiveDefense,
    int? effectiveMaxHp,
    bool isCharged = false,
    int consecutiveWins = 0,
    int absorbedDamage = 0,
  }) {
    final pAtk = effectiveAttack ?? player.stats.attack;
    final pDef = effectiveDefense ?? player.stats.defense;
    // gazer trait doubles charge multiplier
    final chargeMult = isCharged
        ? (player.trait == CharacterTrait.gazer ? 4.0 : 2.0)
        : 1.0;
    final outcome = _rpsOutcome(playerChoice, enemyChoice);
    final elemMult = player.trait.element.damageMultiplier(enemy.element);
    int playerDmg = 0;
    int enemyDmg = 0;
    String msg;
    String? comboMsg;

    if (outcome == 1) {
      // Base: 응시하기 win → 방어 무시, 잡기 win → ×1.3
      final effEnemyDef = playerChoice == RpsChoice.evasion ? 0 : enemy.defense;
      double bonusMult = playerChoice == RpsChoice.attack ? 1.3 : 1.0;

      if (playerChoice == RpsChoice.defense) {
        // 피하기 win → 카운터 (공격력의 60%)
        final counter = (pAtk * 0.6).round().clamp(1, 9999);
        playerDmg = (counter * chargeMult).round();
        comboMsg = '🫂 피하기 카운터!';
      } else {
        final raw = (pAtk - effEnemyDef * 0.5).clamp(1, double.infinity);
        playerDmg = (raw * elemMult * bonusMult * chargeMult).round();
      }

      // Trait passives on win
      if (player.trait == CharacterTrait.screamer && consecutiveWins > 0) {
        final streakMult = (1.0 + consecutiveWins * 0.2).clamp(1.0, 3.0);
        playerDmg = (playerDmg * streakMult).round();
        comboMsg = '😤 분노 폭발! (${consecutiveWins + 1}연승 ×${streakMult.toStringAsFixed(1)})';
      }

      if (player.trait == CharacterTrait.accepter) {
        if (playerChoice == RpsChoice.defense) {
          // 받아들이는 아이: 피하기 win → heal
          final maxHp = effectiveMaxHp ?? player.stats.maxHp;
          final heal = (maxHp * 0.12).round().clamp(1, maxHp);
          player.currentHp = (player.currentHp + heal).clamp(0, maxHp);
          comboMsg = '🤗 받아들이기! HP +$heal 회복!';
        } else if (playerChoice == RpsChoice.attack && absorbedDamage > 0) {
          // 받아들이는 아이: 잡기 win → stored damage bonus
          playerDmg += absorbedDamage;
          comboMsg = '🤗 역전! 흡수 $absorbedDamage 추가 피해!';
        }
      }

      _applyDamage(enemy, playerDmg);

      final actionNote = switch (playerChoice) {
        RpsChoice.attack  => ' (잡기 보너스!)',
        RpsChoice.evasion => ' (방어 무시!)',
        RpsChoice.defense => ' (카운터!)',
      };
      msg = '${_choiceName(playerChoice)} ▶ ${_choiceName(enemyChoice)} 승! '
          '${enemy.name} $playerDmg 피해!$actionNote';
      if (isCharged) msg = '⚡ 집중 발동! $msg';

    } else if (outcome == -1) {
      // Loss secondary effects
      double damageMult = switch (playerChoice) {
        RpsChoice.attack  => 1.2,  // 잡기 패: 과공격 패널티
        RpsChoice.defense => 0.6,  // 피하기 패: 부분 방어
        RpsChoice.evasion => 0.0,  // 응시하기 패: 완전 빗나감
      };

      // shrinker trait: defense loss → extra reduction
      if (player.trait == CharacterTrait.shrinker && playerChoice == RpsChoice.defense) {
        damageMult = 0.4;
        comboMsg = '🫣 작아지기! 받는 피해 60% 감소!';
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
      msg = '잡기 vs 잡기! 상호 피해 — 나 $playerDmg / 적 $enemyDmg';
    } else {
      msg = '${_choiceName(playerChoice)} vs ${_choiceName(enemyChoice)} — 무승부.';
    }

    return RpsResult(
      playerChoice: playerChoice,
      enemyChoice: enemyChoice,
      playerDamageDealt: playerDmg,
      enemyDamageDealt: enemyDmg,
      message: msg,
      outcome: outcome,
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
    RpsChoice.attack  => '🤜 잡기',
    RpsChoice.defense => '🫂 피하기',
    RpsChoice.evasion => '👀 응시하기',
  };
}
