import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/element_type.dart';
import '../../core/models/character.dart';
import '../../core/models/equipment.dart';
import 'character_save.dart';

class CharacterState {
  final List<Character> roster;
  final Character? activeCharacter;
  final Map<EquipmentSlot, Equipment> equipped;
  final bool isLoaded;

  const CharacterState({
    this.roster = const [],
    this.activeCharacter,
    this.equipped = const {},
    this.isLoaded = false,
  });

  CharacterState copyWith({
    List<Character>? roster,
    Character? activeCharacter,
    Map<EquipmentSlot, Equipment>? equipped,
    bool? isLoaded,
  }) => CharacterState(
    roster: roster ?? this.roster,
    activeCharacter: activeCharacter ?? this.activeCharacter,
    equipped: equipped ?? this.equipped,
    isLoaded: isLoaded ?? this.isLoaded,
  );

  CharacterStats get effectiveStats {
    final base = activeCharacter?.stats;
    if (base == null) {
      return const CharacterStats(maxHp: 0, maxMp: 0, attack: 0, defense: 0, speed: 0);
    }
    return CharacterStats(
      maxHp: base.maxHp + equipped.values.fold(0, (s, e) => s + e.hpBonus),
      maxMp: base.maxMp,
      attack: base.attack + equipped.values.fold(0, (s, e) => s + e.attackBonus),
      defense: base.defense + equipped.values.fold(0, (s, e) => s + e.defenseBonus),
      speed: base.speed + equipped.values.fold(0, (s, e) => s + e.speedBonus),
    );
  }
}

class CharacterNotifier extends StateNotifier<CharacterState> {
  CharacterNotifier() : super(const CharacterState());

  Future<void> load() async {
    await CharacterSave.init();
    var roster = CharacterSave.loadAllCharacters();
    if (roster.isEmpty) {
      roster = [_createStarterCharacter()];
      await CharacterSave.saveCharacter(roster.first);
    }
    state = state.copyWith(
      roster: roster,
      activeCharacter: roster.first,
      isLoaded: true,
    );
  }

  void selectCharacter(String id) {
    final character = state.roster.firstWhere((c) => c.id == id);
    state = state.copyWith(activeCharacter: character, equipped: {});
  }

  Future<void> gainExp(int amount) async {
    final character = state.activeCharacter;
    if (character == null) return;

    character.exp += amount;
    var didLevelUp = false;

    while (character.exp >= character.expToNextLevel) {
      character.exp -= character.expToNextLevel;
      character.level += 1;
      final newStats = character.stats;
      character.currentHp = newStats.maxHp;
      character.currentMp = newStats.maxMp;
      didLevelUp = true;
    }

    await CharacterSave.saveCharacter(character);

    final updatedRoster = state.roster
        .map((c) => c.id == character.id ? character : c)
        .toList();
    state = state.copyWith(roster: updatedRoster, activeCharacter: character);

    if (didLevelUp) _onLevelUp(character);
  }

  void equipItem(Equipment equipment) {
    final newEquipped = Map<EquipmentSlot, Equipment>.from(state.equipped);
    newEquipped[equipment.slot] = equipment;
    state = state.copyWith(equipped: newEquipped);
  }

  void unequipSlot(EquipmentSlot slot) {
    final newEquipped = Map<EquipmentSlot, Equipment>.from(state.equipped);
    newEquipped.remove(slot);
    state = state.copyWith(equipped: newEquipped);
  }

  Future<void> restoreHp(int amount) async {
    final character = state.activeCharacter;
    if (character == null) return;
    final maxHp = state.effectiveStats.maxHp;
    character.currentHp = (character.currentHp + amount).clamp(0, maxHp);
    await CharacterSave.saveCharacter(character);
    state = state.copyWith(activeCharacter: character);
  }

  Future<void> fullRestore() async {
    final character = state.activeCharacter;
    if (character == null) return;
    final stats = state.effectiveStats;
    character.currentHp = stats.maxHp;
    character.currentMp = stats.maxMp;
    await CharacterSave.saveCharacter(character);
    state = state.copyWith(activeCharacter: character);
  }

  void _onLevelUp(Character character) {
    // 레벨업 이벤트 — 추후 UI 애니메이션 연결
  }

  Character _createStarterCharacter() => Character(
    id: 'hero_starter',
    name: '불꽃 기사',
    element: ElementType.fire,
    rarity: Rarity.common,
    baseStats: const CharacterStats(
      maxHp: 200,
      maxMp: 80,
      attack: 40,
      defense: 25,
      speed: 20,
    ),
    skills: [],
  );
}

final characterProvider = StateNotifierProvider<CharacterNotifier, CharacterState>(
  (ref) => CharacterNotifier(),
);
