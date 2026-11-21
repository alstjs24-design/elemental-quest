import '../../core/models/character.dart';
import '../../core/models/enemy.dart';
import 'battle_engine.dart';

enum BattlePhase { playerTurn, enemyTurn, victory, defeat, fled }

class BattleState {
  final Character player;
  final Enemy enemy;
  final BattlePhase phase;
  final List<BattleResult> log;
  final bool isDefending;
  final int turn;

  const BattleState({
    required this.player,
    required this.enemy,
    required this.phase,
    required this.log,
    this.isDefending = false,
    this.turn = 1,
  });

  BattleState copyWith({
    Character? player,
    Enemy? enemy,
    BattlePhase? phase,
    List<BattleResult>? log,
    bool? isDefending,
    int? turn,
  }) {
    return BattleState(
      player: player ?? this.player,
      enemy: enemy ?? this.enemy,
      phase: phase ?? this.phase,
      log: log ?? this.log,
      isDefending: isDefending ?? this.isDefending,
      turn: turn ?? this.turn,
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
