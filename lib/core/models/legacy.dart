enum LegacyUpgradeType {
  maxHp,
  attack,
  defense,
  maxMp,
  startingGold,
}

class LegacyUpgrade {
  final LegacyUpgradeType type;
  final int maxLevel;
  final List<int> costs;

  const LegacyUpgrade({
    required this.type,
    required this.maxLevel,
    required this.costs,
  });

  String get label => switch (type) {
    LegacyUpgradeType.maxHp        => '생명력 강화',
    LegacyUpgradeType.attack       => '공격력 강화',
    LegacyUpgradeType.defense      => '방어력 강화',
    LegacyUpgradeType.maxMp        => 'MP 강화',
    LegacyUpgradeType.startingGold => '황금의 손',
  };

  String get icon => switch (type) {
    LegacyUpgradeType.maxHp        => '❤️',
    LegacyUpgradeType.attack       => '⚔️',
    LegacyUpgradeType.defense      => '🛡️',
    LegacyUpgradeType.maxMp        => '💜',
    LegacyUpgradeType.startingGold => '💰',
  };

  String get effectPerLevel => switch (type) {
    LegacyUpgradeType.maxHp        => 'HP +20',
    LegacyUpgradeType.attack       => '공격 +5',
    LegacyUpgradeType.defense      => '방어 +3',
    LegacyUpgradeType.maxMp        => 'MP +15',
    LegacyUpgradeType.startingGold => '시작 골드 +50',
  };

  int bonusAt(int level) => switch (type) {
    LegacyUpgradeType.maxHp        => level * 20,
    LegacyUpgradeType.attack       => level * 5,
    LegacyUpgradeType.defense      => level * 3,
    LegacyUpgradeType.maxMp        => level * 15,
    LegacyUpgradeType.startingGold => level * 50,
  };
}

const kLegacyUpgrades = [
  LegacyUpgrade(type: LegacyUpgradeType.maxHp,        maxLevel: 5, costs: [10, 20, 35, 55, 80]),
  LegacyUpgrade(type: LegacyUpgradeType.attack,       maxLevel: 5, costs: [10, 20, 35, 55, 80]),
  LegacyUpgrade(type: LegacyUpgradeType.defense,      maxLevel: 5, costs: [10, 20, 35, 55, 80]),
  LegacyUpgrade(type: LegacyUpgradeType.maxMp,        maxLevel: 3, costs: [15, 30, 50]),
  LegacyUpgrade(type: LegacyUpgradeType.startingGold, maxLevel: 3, costs: [20, 40, 70]),
];

class LegacyData {
  final int soulFragments;
  final Map<LegacyUpgradeType, int> levels;

  const LegacyData({
    this.soulFragments = 0,
    this.levels = const {},
  });

  LegacyData copyWith({int? soulFragments, Map<LegacyUpgradeType, int>? levels}) =>
      LegacyData(
        soulFragments: soulFragments ?? this.soulFragments,
        levels: levels ?? this.levels,
      );

  int levelOf(LegacyUpgradeType type) => levels[type] ?? 0;

  int bonusFor(LegacyUpgradeType type) {
    final upgrade = kLegacyUpgrades.firstWhere((u) => u.type == type);
    return upgrade.bonusAt(levelOf(type));
  }

  int get hpBonus      => bonusFor(LegacyUpgradeType.maxHp);
  int get attackBonus  => bonusFor(LegacyUpgradeType.attack);
  int get defenseBonus => bonusFor(LegacyUpgradeType.defense);
  int get mpBonus      => bonusFor(LegacyUpgradeType.maxMp);
  int get goldBonus    => bonusFor(LegacyUpgradeType.startingGold);
}
