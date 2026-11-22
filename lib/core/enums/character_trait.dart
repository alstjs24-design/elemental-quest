import 'element_type.dart';

enum CharacterTrait { screamer, accepter, gazer, shrinker }

extension CharacterTraitX on CharacterTrait {
  String get displayName => switch (this) {
    CharacterTrait.screamer => '세상에 소리치는 아이',
    CharacterTrait.accepter => '세상을 받아들이는 아이',
    CharacterTrait.gazer    => '세상을 바라보는 아이',
    CharacterTrait.shrinker => '세상에서 작아지는 아이',
  };

  String get emoji => switch (this) {
    CharacterTrait.screamer => '😤',
    CharacterTrait.accepter => '🤗',
    CharacterTrait.gazer    => '👀',
    CharacterTrait.shrinker => '🫣',
  };

  String get passiveLabel => switch (this) {
    CharacterTrait.screamer => '연속 승리 시 공격력 ×(1 + 연승×0.2)',
    CharacterTrait.accepter => '받은 피해 → 다음 잡기에 추가',
    CharacterTrait.gazer    => '집중 시 ×4.0 (기본의 2배)',
    CharacterTrait.shrinker => '피하기 승리 시 다음 턴 무적',
  };

  // Reuse element affinity for enemy damage multiplier calculations
  ElementType get element => switch (this) {
    CharacterTrait.screamer => ElementType.fire,
    CharacterTrait.accepter => ElementType.water,
    CharacterTrait.gazer    => ElementType.wind,
    CharacterTrait.shrinker => ElementType.earth,
  };
}
