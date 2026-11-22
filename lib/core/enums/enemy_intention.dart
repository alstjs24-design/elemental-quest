enum EnemyIntention { attack, defend, special, confused }

extension EnemyIntentionX on EnemyIntention {
  String get icon => switch (this) {
    EnemyIntention.attack   => '🤜',
    EnemyIntention.defend   => '🛡️',
    EnemyIntention.special  => '💫',
    EnemyIntention.confused => '❓',
  };
  String get label => switch (this) {
    EnemyIntention.attack   => '잡기',
    EnemyIntention.defend   => '방어',
    EnemyIntention.special  => '특수 행동',
    EnemyIntention.confused => '알 수 없음',
  };
  String get counterHint => switch (this) {
    EnemyIntention.attack   => '→ 피하기로 막아!',
    EnemyIntention.defend   => '→ 응시하기로 꿰뚫어!',
    EnemyIntention.special  => '→ 집중 or 피해!',
    EnemyIntention.confused => '',
  };
}
