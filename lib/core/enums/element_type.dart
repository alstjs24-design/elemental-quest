enum ElementType {
  fire,   // 불
  water,  // 물
  earth,  // 땅
  wind,   // 바람
  none,   // 무속성
}

extension ElementTypeX on ElementType {
  String get displayName => switch (this) {
    ElementType.fire  => '🔥 불',
    ElementType.water => '💧 물',
    ElementType.earth => '🌍 땅',
    ElementType.wind  => '🌪 바람',
    ElementType.none  => '⚪ 무',
  };

  // 상성: 이 속성이 강한 대상
  ElementType get strongAgainst => switch (this) {
    ElementType.fire  => ElementType.wind,   // 불 > 바람
    ElementType.water => ElementType.fire,   // 물 > 불
    ElementType.earth => ElementType.water,  // 땅 > 물
    ElementType.wind  => ElementType.earth,  // 바람 > 땅
    ElementType.none  => ElementType.none,
  };

  // 데미지 배율 계산
  double damageMultiplier(ElementType defenderElement) {
    if (strongAgainst == defenderElement) return 1.5; // 유리
    if (defenderElement.strongAgainst == this) return 0.75; // 불리
    return 1.0;
  }
}
