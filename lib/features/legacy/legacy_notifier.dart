import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/legacy.dart';
import 'legacy_save.dart';

class LegacyNotifier extends StateNotifier<LegacyData> {
  LegacyNotifier() : super(const LegacyData());

  Future<void> load() async {
    await LegacySave.init();
    state = LegacySave.load();
  }

  Future<void> addSoulFragments(int amount) async {
    state = state.copyWith(soulFragments: state.soulFragments + amount);
    await LegacySave.save(state);
  }

  Future<bool> purchaseUpgrade(LegacyUpgradeType type) async {
    final upgrade = kLegacyUpgrades.firstWhere((u) => u.type == type);
    final currentLevel = state.levelOf(type);
    if (currentLevel >= upgrade.maxLevel) return false;

    final cost = upgrade.costs[currentLevel];
    if (state.soulFragments < cost) return false;

    final newLevels = Map<LegacyUpgradeType, int>.from(state.levels);
    newLevels[type] = currentLevel + 1;
    state = state.copyWith(
      soulFragments: state.soulFragments - cost,
      levels: newLevels,
    );
    await LegacySave.save(state);
    return true;
  }

  /// Called on dungeon death or exit — awards soul fragments based on progress.
  Future<int> onRunEnd({required int floor, required int roomsCleared, required bool victory}) async {
    final base = floor * roomsCleared;
    final earned = victory ? (base * 3).clamp(5, 999) : (base * 2).clamp(2, 500);
    await addSoulFragments(earned);
    return earned;
  }
}

final legacyProvider = StateNotifierProvider<LegacyNotifier, LegacyData>(
  (ref) => LegacyNotifier(),
);
