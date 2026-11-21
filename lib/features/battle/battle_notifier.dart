import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/character.dart';
import '../../core/models/enemy.dart';
import '../../core/models/skill.dart';
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
  }) {
    state = BattleState(
      player: player,
      enemy: enemy,
      phase: BattlePhase.playerTurn,
      log: [],
      turn: 1,
      effectiveAttack: effectiveAttack ?? player.stats.attack,
      effectiveDefense: effectiveDefense ?? player.stats.defense,
    );
  }

  void playerAttack() {
    final s = state;
    if (s == null || !s.isPlayerTurn) return;

    final result = BattleEngine.executePlayerAction(
      player: s.player,
      enemy: s.enemy,
      action: BattleAction.basicAttack,
    );

    _afterPlayerAction(s, result);
  }

  void playerUseSkill(Skill skill) {
    final s = state;
    if (s == null || !s.isPlayerTurn) return;

    final result = BattleEngine.executePlayerAction(
      player: s.player,
      enemy: s.enemy,
      action: BattleAction.useSkill(skill),
    );

    _afterPlayerAction(s, result);
  }

  void playerDefend() {
    final s = state;
    if (s == null || !s.isPlayerTurn) return;

    final result = BattleEngine.executePlayerAction(
      player: s.player,
      enemy: s.enemy,
      action: BattleAction.defend,
    );

    final newLog = [...s.log, result];
    state = s.copyWith(
      log: newLog,
      isDefending: true,
      phase: BattlePhase.enemyTurn,
    );

    _executeEnemyTurn(state!);
  }

  void playerFlee() {
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
      final newLog = [...s.log, result];
      state = s.copyWith(log: newLog, phase: BattlePhase.enemyTurn);
      _executeEnemyTurn(state!);
    }
  }

  void _afterPlayerAction(BattleState s, BattleResult result) {
    final newLog = [...s.log, result];

    if (!s.enemy.isAlive) {
      final drops = generateEnemyDrops(s.enemy);
      state = s.copyWith(log: newLog, phase: BattlePhase.victory, pendingDrops: drops);
      return;
    }

    state = s.copyWith(log: newLog, phase: BattlePhase.enemyTurn);
    _executeEnemyTurn(state!);
  }

  void _executeEnemyTurn(BattleState s) {
    final defenseReduction = s.isDefending ? 0.5 : 1.0;
    final result = BattleEngine.executeEnemyAction(
      enemy: s.enemy,
      player: s.player,
      effectiveDefense: s.effectiveDefense,
    );

    final actualDamage = (result.damage * defenseReduction).round();
    if (actualDamage != result.damage && result.damage > 0) {
      s.player.currentHp = (s.player.currentHp + result.damage - actualDamage)
          .clamp(0, s.player.stats.maxHp);
    }

    final newLog = [...s.log, result];

    if (!s.player.isAlive) {
      state = s.copyWith(log: newLog, phase: BattlePhase.defeat, isDefending: false);
      return;
    }

    state = s.copyWith(
      log: newLog,
      phase: BattlePhase.playerTurn,
      isDefending: false,
      turn: s.turn + 1,
    );
  }

  void playerChooseRps(RpsChoice choice) {
    final s = state;
    if (s == null || !s.isPlayerTurn) return;

    final enemyChoice = _weightedEnemyChoice(s.enemy.tendency);
    final result = BattleEngine.resolveRps(
      playerChoice: choice,
      enemyChoice: enemyChoice,
      player: s.player,
      enemy: s.enemy,
      effectiveAttack: s.effectiveAttack,
      effectiveDefense: s.effectiveDefense,
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

    if (!s.enemy.isAlive) {
      final drops = generateEnemyDrops(s.enemy);
      state = s.copyWith(log: newLog, phase: BattlePhase.victory, pendingDrops: drops);
      return;
    }
    if (!s.player.isAlive) {
      state = s.copyWith(log: newLog, phase: BattlePhase.defeat);
      return;
    }

    state = s.copyWith(
      log: newLog,
      phase: BattlePhase.playerTurn,
      turn: s.turn + 1,
    );
  }

  RpsChoice _weightedEnemyChoice(BattleTendency tendency) {
    final rand = Random().nextDouble();
    switch (tendency) {
      case BattleTendency.aggressive:
        // 60% attack, 20% defense, 20% evasion
        if (rand < 0.60) return RpsChoice.attack;
        if (rand < 0.80) return RpsChoice.defense;
        return RpsChoice.evasion;
      case BattleTendency.defensive:
        // 20% attack, 60% defense, 20% evasion
        if (rand < 0.20) return RpsChoice.attack;
        if (rand < 0.80) return RpsChoice.defense;
        return RpsChoice.evasion;
      case BattleTendency.evasive:
        // 20% attack, 20% defense, 60% evasion
        if (rand < 0.20) return RpsChoice.attack;
        if (rand < 0.40) return RpsChoice.defense;
        return RpsChoice.evasion;
      case BattleTendency.unpredictable:
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
