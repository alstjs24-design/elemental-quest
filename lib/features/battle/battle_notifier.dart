import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/character_trait.dart';
import '../../core/enums/enemy_intention.dart';
import '../../core/models/character.dart';
import '../../core/models/enemy.dart';
import '../../features/crafting/material_notifier.dart';
import 'battle_engine.dart';
import 'battle_state.dart';

class BattleNotifier extends StateNotifier<BattleState?> {
  BattleNotifier() : super(null);

  void startBattle({
    required Character player,
    required Enemy enemy,
    int? effectiveAttack,
    int? effectiveDefense,
    int? effectiveMaxHp,
  }) {
    state = BattleState(
      player: player,
      enemy: enemy,
      phase: BattlePhase.playerTurn,
      log: [],
      turn: 1,
      effectiveAttack: effectiveAttack ?? player.stats.attack,
      effectiveDefense: effectiveDefense ?? player.stats.defense,
      effectiveMaxHp: effectiveMaxHp ?? player.stats.maxHp,
      enemyIntention: enemy.calculateIntention(1),
    );
  }

  Future<void> playerFlee() async {
    final s = state;
    if (s == null || !s.isPlayerTurn) return;

    final fled = BattleEngine.tryFlee(
      playerSpeed: s.player.stats.speed,
      enemySpeed: s.enemy.speed,
    );

    final result = BattleResult(
      actorName: s.player.name,
      targetName: s.enemy.name,
      message: fled ? '도망에 성공했습니다!' : '도망에 실패했습니다!',
    );

    if (fled) {
      state = s.copyWith(log: [...s.log, result], phase: BattlePhase.fled);
    } else {
      state = s.copyWith(log: [...s.log, result], phase: BattlePhase.enemyTurn);
      await Future.delayed(const Duration(milliseconds: 400));
      if (state != null) _executeEnemyTurn(state!);
    }
  }

  void _executeEnemyTurn(BattleState s) {
    // shrinker passive: invincible this turn
    if (s.isInvincible) {
      final blockEntry = BattleResult(
        actorName: s.player.name,
        targetName: s.player.name,
        message: '🫣 무적! 적의 공격을 완전히 무시!',
      );
      state = s.copyWith(
        log: [...s.log, blockEntry],
        phase: BattlePhase.playerTurn,
        isInvincible: false,
        turn: s.turn + 1,
      );
      return;
    }

    final result = BattleEngine.executeEnemyAction(
      enemy: s.enemy,
      player: s.player,
      effectiveDefense: s.effectiveDefense,
    );

    final actualDamage = result.damage;

    // Gazer balance: being hit while charging cancels the charge
    var newIsCharged = s.isCharged;
    var newLog = [...s.log, result];
    if (s.player.trait == CharacterTrait.gazer && s.isCharged && actualDamage > 0) {
      newIsCharged = false;
      newLog = [...newLog, BattleResult(
        actorName: s.enemy.name,
        targetName: s.player.name,
        message: '⚡ 집중이 풀렸다! (피격으로 취소)',
      )];
    }

    // accepter: accumulate damage from enemy turn
    var newAbsorbedDamage = s.absorbedDamage;
    if (s.player.trait == CharacterTrait.accepter && actualDamage > 0) {
      newAbsorbedDamage += actualDamage;
    }

    final nextTurn = s.turn + 1;
    final nextIntention = s.enemy.calculateIntention(nextTurn);

    if (!s.player.isAlive) {
      state = s.copyWith(
        log: newLog, phase: BattlePhase.defeat,
        isCharged: newIsCharged,
        consecutiveWins: 0, absorbedDamage: 0,
      );
      return;
    }

    state = s.copyWith(
      log: newLog,
      phase: BattlePhase.playerTurn,
      isCharged: newIsCharged,
      absorbedDamage: newAbsorbedDamage,
      enemyIntention: nextIntention,
      turn: nextTurn,
    );
  }

  void playerChooseRps(RpsChoice choice) {
    final s = state;
    if (s == null || !s.isPlayerTurn) return;

    final enemyChoice = _weightedEnemyChoice(s.enemyIntention);
    final result = BattleEngine.resolveRps(
      playerChoice: choice,
      enemyChoice: enemyChoice,
      player: s.player,
      enemy: s.enemy,
      effectiveAttack: s.effectiveAttack,
      effectiveDefense: s.effectiveDefense,
      effectiveMaxHp: s.effectiveMaxHp,
      isCharged: s.isCharged,
      consecutiveWins: s.consecutiveWins,
      absorbedDamage: s.absorbedDamage,
    );

    final entries = <BattleResult>[
      BattleResult(
        actorName: s.player.name,
        targetName: s.enemy.name,
        damage: result.playerDamageDealt,
        message: result.message,
      ),
      if (result.comboMessage != null)
        BattleResult(
          actorName: s.player.name,
          targetName: s.enemy.name,
          message: result.comboMessage!,
        ),
    ];

    final newLog = [...s.log, ...entries];

    // Update passive states based on result
    final trait = s.player.trait;
    // screamer: 연승은 잡기 승리 시에만 증가, 패배 시 리셋, 다른 행동 승리 시 유지
    final newConsecutiveWins = result.outcome == -1
        ? 0
        : (choice == RpsChoice.attack && result.outcome == 1
            ? s.consecutiveWins + 1
            : s.consecutiveWins);
    // accepter: 잡기 승리 시에만 흡수 데미지 소진(리셋), 나머지 상황엔 계속 누적
    final newAbsorbedDamage = trait == CharacterTrait.accepter
        ? (choice == RpsChoice.attack && result.outcome == 1
            ? 0
            : s.absorbedDamage + result.enemyDamageDealt)
        : 0;
    // shrinker: 피하기 승리 시 무적 (테마: 작아지기/숨기)
    final newInvincible = trait == CharacterTrait.shrinker &&
        result.outcome == 1 &&
        choice == RpsChoice.defense;

    if (!s.enemy.isAlive) {
      final drops = generateEnemyDrops(s.enemy);
      state = s.copyWith(
        log: newLog, phase: BattlePhase.victory, pendingDrops: drops,
        isCharged: false, consecutiveWins: 0, absorbedDamage: 0, isInvincible: false,
      );
      return;
    }
    if (!s.player.isAlive) {
      state = s.copyWith(
        log: newLog, phase: BattlePhase.defeat,
        isCharged: false, consecutiveWins: 0, absorbedDamage: 0, isInvincible: false,
      );
      return;
    }

    final nextTurn = s.turn + 1;
    state = s.copyWith(
      log: newLog,
      phase: BattlePhase.playerTurn,
      turn: nextTurn,
      isCharged: false,
      consecutiveWins: newConsecutiveWins,
      absorbedDamage: newAbsorbedDamage,
      isInvincible: newInvincible,
      enemyIntention: s.enemy.calculateIntention(nextTurn),
    );
  }

  Future<void> playerCharge() async {
    final s = state;
    if (s == null || !s.isPlayerTurn || s.isCharged) return;

    final chargeMult = s.player.trait == CharacterTrait.gazer ? '×4.0' : '×2.0';
    final entry = BattleResult(
      actorName: s.player.name,
      targetName: s.player.name,
      message: '⚡ ${s.player.name}이(가) 집중! 다음 공격 $chargeMult!',
    );

    // Show "enemy turn" briefly so the UI can render the charge state
    state = s.copyWith(
      log: [...s.log, entry],
      isCharged: true,
      phase: BattlePhase.enemyTurn,
    );
    await Future.delayed(const Duration(milliseconds: 400));
    if (state != null) _executeEnemyTurn(state!);
  }

  // Intention biases the enemy's RPS choice so the telegraph is meaningful.
  // 75% follow-through keeps it strategic but not perfectly predictable.
  RpsChoice _weightedEnemyChoice(EnemyIntention intention) {
    final rand = Random().nextDouble();
    switch (intention) {
      case EnemyIntention.attack:
        if (rand < 0.75) return RpsChoice.attack;
        if (rand < 0.90) return RpsChoice.defense;
        return RpsChoice.evasion;
      case EnemyIntention.defend:
        if (rand < 0.15) return RpsChoice.attack;
        if (rand < 0.90) return RpsChoice.defense;
        return RpsChoice.evasion;
      case EnemyIntention.special:
        if (rand < 0.20) return RpsChoice.attack;
        if (rand < 0.50) return RpsChoice.defense;
        return RpsChoice.evasion;
      case EnemyIntention.confused:
        return RpsChoice.values[Random().nextInt(RpsChoice.values.length)];
    }
  }

  void endBattle() {
    state = null;
  }
}

final battleProvider = StateNotifierProvider<BattleNotifier, BattleState?>(
  (ref) => BattleNotifier(),
);
