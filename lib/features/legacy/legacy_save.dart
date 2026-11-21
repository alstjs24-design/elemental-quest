import 'package:hive_flutter/hive_flutter.dart';
import '../../core/models/legacy.dart';

const _boxName = 'legacy';

class LegacySave {
  static Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
  }

  static Future<void> save(LegacyData data) async {
    final box = Hive.box<Map>(_boxName);
    await box.put('data', {
      'soulFragments': data.soulFragments,
      'levels': {
        for (final e in data.levels.entries) e.key.index.toString(): e.value,
      },
    });
  }

  static LegacyData load() {
    final box = Hive.box<Map>(_boxName);
    final raw = box.get('data');
    if (raw == null) return const LegacyData();
    final map = Map<String, dynamic>.from(raw);
    final levelsRaw = map['levels'] as Map? ?? {};
    final levels = <LegacyUpgradeType, int>{};
    for (final e in levelsRaw.entries) {
      final idx = int.tryParse(e.key.toString());
      if (idx != null && idx < LegacyUpgradeType.values.length) {
        levels[LegacyUpgradeType.values[idx]] = e.value as int;
      }
    }
    return LegacyData(
      soulFragments: map['soulFragments'] as int? ?? 0,
      levels: levels,
    );
  }
}
