import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/element_type.dart';
import '../../core/models/enemy.dart';
import '../../core/models/memory_card.dart';
import '../character/character_notifier.dart';
import '../dungeon/enemy_factory.dart';
import 'run_state.dart';

// Element sequence per zone/battle (variety + logical progression)
const _zoneElements = [
  [ElementType.fire,  ElementType.water, ElementType.earth],  // zone 0
  [ElementType.wind,  ElementType.fire,  ElementType.water],  // zone 1
  [ElementType.earth, ElementType.wind,  ElementType.fire],   // zone 2
];

class RunNotifier extends StateNotifier<RunState?> {
  final Ref _ref;
  RunNotifier(this._ref) : super(null);

  void startRun() {
    state = const RunState();
  }

  Enemy currentEnemy() {
    final s = state!;
    if (s.isBossPhase) {
      return EnemyFactory.spawnForRunRoom(
        floor: 7,
        element: ElementType.wind,
        isBoss: true,
      ).first;
    }
    final zoneIdx = s.zoneIndex.clamp(0, kRunZones.length - 1);
    final battleIdx = s.battleIndexInZone.clamp(0, kRunZones[zoneIdx].battleCount - 1);
    final element = _zoneElements[zoneIdx][battleIdx];
    final floor = kRunZones[zoneIdx].floorLevel;
    return EnemyFactory.spawnForRunRoom(floor: floor, element: element, isBoss: false).first;
  }

  void onBattleVictory() {
    final s = state;
    if (s == null) return;

    if (s.isBossPhase) {
      state = s.copyWith(isComplete: true, totalBattlesWon: s.totalBattlesWon + 1);
      return;
    }

    final zone = kRunZones[s.zoneIndex];
    final nextBattleIdx = s.battleIndexInZone + 1;

    if (nextBattleIdx >= zone.battleCount) {
      // Zone complete — advance zone or enter boss phase
      final nextZoneIdx = s.zoneIndex + 1;
      if (nextZoneIdx >= kRunZones.length) {
        state = s.copyWith(
          isBossPhase: true,
          totalBattlesWon: s.totalBattlesWon + 1,
        );
      } else {
        state = s.copyWith(
          zoneIndex: nextZoneIdx,
          battleIndexInZone: 0,
          totalBattlesWon: s.totalBattlesWon + 1,
        );
      }
    } else {
      state = s.copyWith(
        battleIndexInZone: nextBattleIdx,
        totalBattlesWon: s.totalBattlesWon + 1,
      );
    }
  }

  void onBattleDefeat() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(isFailed: true);
  }

  Future<void> pickCard(MemoryCard card) async {
    final s = state;
    if (s == null) return;
    state = s.copyWith(pickedCards: [...s.pickedCards, card]);
    // HP heal cards take effect immediately
    if (card.hpHeal > 0) {
      await _ref.read(characterProvider.notifier).restoreHp(card.hpHeal);
    }
  }

  List<MemoryCard> drawThreeCards() {
    final s = state;
    final alreadyPicked = s?.pickedCards.map((c) => c.id).toSet() ?? {};
    final pool = kAllMemoryCards.where((c) => !alreadyPicked.contains(c.id)).toList();
    if (pool.length <= 3) return List<MemoryCard>.from(pool);
    pool.shuffle(Random());
    return pool.take(3).toList();
  }

  void endRun() {
    state = null;
  }
}

final runProvider = StateNotifierProvider<RunNotifier, RunState?>(
  (ref) => RunNotifier(ref),
);
