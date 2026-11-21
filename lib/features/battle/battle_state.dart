import '../../core/models/character.dart';
import '../../core/models/enemy.dart';
import '../../core/models/material_item.dart';
import 'battle_engine.dart';

enum BattlePhase { playerTurn, enemyTurn, victory, defeat, fled }

class BattleState {
  final Character player;
  final Enemy enemy;
  final BattlePhase phase;
  final List<BattleResult> log;
  final bool isDefending;
  final int turn;
  final int effectiveAttack;
  final int effectiveDefense;
  final List<MaterialItem> pendingDrops;

  final bool isCharged;

  const BattleState({
    required this.player,
    required this.enemy,
    required this.phase,
    required this.log,
    required this.effectiveAttack,
    required this.effectiveDefense,
    this.pendingDrops = const [],
    this.isDefending = false,
    this.isCharged = false,
    this.turn = 1,
  });

  BattleState copyWith({
    Character? player,
    Enemy? enemy,
    BattlePhase? phase,
    List<BattleResult>? log,
    bool? isDefending,
    bool? isCharged,
    int? turn,
    int? effectiveAttack,
    int? effectiveDefense,
    List<MaterialItem>? pendingDrops,
  }) {
    return BattleState(
      player: player ?? this.player,
      enemy: enemy ?? this.enemy,
      phase: phase ?? this.phase,
      log: log ?? this.log,
      isDefending: isDefending ?? this.isDefending,
      isCharged: isCharged ?? this.isCharged,
      turn: turn ?? this.turn,
      effectiveAttack: effectiveAttack ?? this.effectiveAttack,
      effectiveDefense: effectiveDefense ?? this.effectiveDefense,
      pendingDrops: pendingDrops ?? this.pendingDrops,
    );
  }

  bool get isPlayerTurn => phase == BattlePhase.playerTurn;
  bool get isBattleOver =>
      phase == BattlePhase.victory ||
      phase == BattlePhase.defeat ||
      phase == BattlePhase.fled;

  int get expReward => enemy.expReward;
  double get goldReward => enemy.goldReward;
}
