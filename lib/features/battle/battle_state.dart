import '../../core/enums/enemy_intention.dart';
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
  final int turn;
  final int effectiveAttack;
  final int effectiveDefense;
  final List<MaterialItem> pendingDrops;

  final bool isCharged;
  final int consecutiveWins;   // screamer: 잡기 연승 카운터
  final int absorbedDamage;    // accepter: 누적 피해 → 잡기 성공 시 소진
  final bool isInvincible;     // shrinker: 피하기 승리 시 다음 턴 무적
  final EnemyIntention enemyIntention; // telegraph: enemy's most likely next RPS choice
  final int effectiveMaxHp;    // equipment + legacy HP — used for HP bar display & heal cap

  const BattleState({
    required this.player,
    required this.enemy,
    required this.phase,
    required this.log,
    required this.effectiveAttack,
    required this.effectiveDefense,
    required this.effectiveMaxHp,
    this.pendingDrops = const [],
    this.isCharged = false,
    this.consecutiveWins = 0,
    this.absorbedDamage = 0,
    this.isInvincible = false,
    this.enemyIntention = EnemyIntention.confused,
    this.turn = 1,
  });

  BattleState copyWith({
    Character? player,
    Enemy? enemy,
    BattlePhase? phase,
    List<BattleResult>? log,
    bool? isCharged,
    int? consecutiveWins,
    int? absorbedDamage,
    bool? isInvincible,
    EnemyIntention? enemyIntention,
    int? turn,
    int? effectiveAttack,
    int? effectiveDefense,
    int? effectiveMaxHp,
    List<MaterialItem>? pendingDrops,
  }) {
    return BattleState(
      player: player ?? this.player,
      enemy: enemy ?? this.enemy,
      phase: phase ?? this.phase,
      log: log ?? this.log,
      isCharged: isCharged ?? this.isCharged,
      consecutiveWins: consecutiveWins ?? this.consecutiveWins,
      absorbedDamage: absorbedDamage ?? this.absorbedDamage,
      isInvincible: isInvincible ?? this.isInvincible,
      enemyIntention: enemyIntention ?? this.enemyIntention,
      turn: turn ?? this.turn,
      effectiveAttack: effectiveAttack ?? this.effectiveAttack,
      effectiveDefense: effectiveDefense ?? this.effectiveDefense,
      effectiveMaxHp: effectiveMaxHp ?? this.effectiveMaxHp,
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
