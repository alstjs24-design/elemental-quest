import '../../core/models/memory_card.dart';

class RunZoneConfig {
  final String name;
  final String subtitle;
  final String icon;
  final int battleCount;
  final int floorLevel;

  const RunZoneConfig({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.battleCount,
    required this.floorLevel,
  });
}

const kRunZones = <RunZoneConfig>[
  RunZoneConfig(name: '얕은 잠',  subtitle: '낯선 감각들이 가득해',        icon: '😴', battleCount: 3, floorLevel: 1),
  RunZoneConfig(name: '깊은 잠',  subtitle: '더 복잡한 느낌들이 와',       icon: '💤', battleCount: 3, floorLevel: 3),
  RunZoneConfig(name: '깊은 꿈',  subtitle: '내면 깊은 곳에서 뭔가 온다', icon: '🌑', battleCount: 3, floorLevel: 5),
];

class RunState {
  final int zoneIndex;
  final int battleIndexInZone;
  final bool isBossPhase;
  final bool isComplete;
  final bool isFailed;
  final List<MemoryCard> pickedCards;
  final int totalBattlesWon;

  const RunState({
    this.zoneIndex = 0,
    this.battleIndexInZone = 0,
    this.isBossPhase = false,
    this.isComplete = false,
    this.isFailed = false,
    this.pickedCards = const [],
    this.totalBattlesWon = 0,
  });

  RunState copyWith({
    int? zoneIndex,
    int? battleIndexInZone,
    bool? isBossPhase,
    bool? isComplete,
    bool? isFailed,
    List<MemoryCard>? pickedCards,
    int? totalBattlesWon,
  }) {
    return RunState(
      zoneIndex: zoneIndex ?? this.zoneIndex,
      battleIndexInZone: battleIndexInZone ?? this.battleIndexInZone,
      isBossPhase: isBossPhase ?? this.isBossPhase,
      isComplete: isComplete ?? this.isComplete,
      isFailed: isFailed ?? this.isFailed,
      pickedCards: pickedCards ?? this.pickedCards,
      totalBattlesWon: totalBattlesWon ?? this.totalBattlesWon,
    );
  }

  RunZoneConfig get currentZone =>
      kRunZones[zoneIndex.clamp(0, kRunZones.length - 1)];

  int get completedBattles {
    // When boss phase, all zone battles are done — avoids off-by-1 at transition
    if (isBossPhase) {
      return kRunZones.fold(0, (sum, z) => sum + z.battleCount);
    }
    var count = 0;
    for (var i = 0; i < zoneIndex; i++) {
      count += kRunZones[i].battleCount;
    }
    return count + battleIndexInZone;
  }

  int get currentFloor {
    if (isBossPhase) return 7;
    return kRunZones[zoneIndex.clamp(0, kRunZones.length - 1)].floorLevel;
  }

  int get totalBattles =>
      kRunZones.fold(0, (sum, z) => sum + z.battleCount) + 1;

  int get totalAttackBonus =>
      pickedCards.fold(0, (sum, c) => sum + c.attackBonus);
  int get totalDefenseBonus =>
      pickedCards.fold(0, (sum, c) => sum + c.defenseBonus);
}
