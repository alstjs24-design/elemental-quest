import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pvp_service.dart';

enum PvpStatus { idle, searching, inBattle, victory, defeat, error }

class PvpState {
  final PvpStatus status;
  final DefenseTeam? opponent;
  final List<DefenseTeam> leaderboard;
  final List<BattleRecord> history;
  final String? errorMessage;
  final bool isRegistered;

  const PvpState({
    this.status = PvpStatus.idle,
    this.opponent,
    this.leaderboard = const [],
    this.history = const [],
    this.errorMessage,
    this.isRegistered = false,
  });

  PvpState copyWith({
    PvpStatus? status,
    DefenseTeam? opponent,
    List<DefenseTeam>? leaderboard,
    List<BattleRecord>? history,
    String? errorMessage,
    bool? isRegistered,
  }) => PvpState(
    status: status ?? this.status,
    opponent: opponent ?? this.opponent,
    leaderboard: leaderboard ?? this.leaderboard,
    history: history ?? this.history,
    errorMessage: errorMessage,
    isRegistered: isRegistered ?? this.isRegistered,
  );
}

class PvpNotifier extends StateNotifier<PvpState> {
  PvpNotifier() : super(const PvpState());

  Future<void> registerDefenseTeam({
    required String userId,
    required String displayName,
    required List<String> characterIds,
  }) async {
    try {
      await PvpService.registerDefenseTeam(
        userId: userId,
        displayName: displayName,
        characterIds: characterIds,
      );
      state = state.copyWith(isRegistered: true);
    } catch (e) {
      state = state.copyWith(errorMessage: '방어팀 등록 실패: $e');
    }
  }

  Future<void> findOpponent(String myUserId) async {
    state = state.copyWith(status: PvpStatus.searching, errorMessage: null);
    try {
      final opponent = await PvpService.fetchRandomOpponent(myUserId);
      if (opponent == null) {
        state = state.copyWith(
          status: PvpStatus.idle,
          errorMessage: '상대방을 찾지 못했습니다. 나중에 다시 시도해주세요.',
        );
        return;
      }
      state = state.copyWith(status: PvpStatus.inBattle, opponent: opponent);
    } catch (e) {
      state = state.copyWith(status: PvpStatus.error, errorMessage: '매칭 실패: $e');
    }
  }

  Future<void> submitResult({
    required String myUserId,
    required bool iWon,
  }) async {
    final opponent = state.opponent;
    if (opponent == null) return;

    try {
      await PvpService.submitBattleResult(
        attackerId: myUserId,
        defenderId: opponent.userId,
        attackerWon: iWon,
      );
      state = state.copyWith(
        status: iWon ? PvpStatus.victory : PvpStatus.defeat,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: '결과 저장 실패: $e');
    }
  }

  Future<void> loadLeaderboard() async {
    try {
      final board = await PvpService.fetchLeaderboard();
      state = state.copyWith(leaderboard: board);
    } catch (e) {
      state = state.copyWith(errorMessage: '리더보드 로딩 실패: $e');
    }
  }

  Future<void> loadHistory(String userId) async {
    try {
      final history = await PvpService.fetchMyHistory(userId);
      state = state.copyWith(history: history);
    } catch (e) {
      state = state.copyWith(errorMessage: '전적 로딩 실패: $e');
    }
  }

  void reset() {
    state = state.copyWith(status: PvpStatus.idle, opponent: null, errorMessage: null);
  }
}

final pvpProvider = StateNotifierProvider<PvpNotifier, PvpState>(
  (ref) => PvpNotifier(),
);
