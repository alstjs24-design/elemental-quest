class MemoryCard {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int attackBonus;
  final int defenseBonus;
  final int hpHeal;

  const MemoryCard({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.attackBonus = 0,
    this.defenseBonus = 0,
    this.hpHeal = 0,
  });

  String get bonusSummary {
    final parts = <String>[];
    if (attackBonus > 0) parts.add('공격 +$attackBonus');
    if (defenseBonus > 0) parts.add('방어 +$defenseBonus');
    if (hpHeal > 0) parts.add('HP +$hpHeal 회복');
    return parts.join('  ');
  }
}

const kAllMemoryCards = <MemoryCard>[
  MemoryCard(id: 'swing',       name: '그네를 탔어',     description: '처음 그네를 탔던 느낌',      icon: '🎠', attackBonus: 8),
  MemoryCard(id: 'bath',        name: '목욕을 했어',     description: '따뜻한 물에 몸을 담갔어',    icon: '🛁', defenseBonus: 8),
  MemoryCard(id: 'mom_smile',   name: '엄마가 웃었어',   description: '그 웃음이 세상 전부였어',    icon: '😊', hpHeal: 20),
  MemoryCard(id: 'dad_hug',     name: '아빠가 안아줬어', description: '큰 손이 나를 감쌌어',        icon: '🤗', attackBonus: 5, defenseBonus: 5),
  MemoryCard(id: 'first_laugh', name: '처음 웃었어',     description: '소리 내서 웃어봤어',         icon: '😄', attackBonus: 12),
  MemoryCard(id: 'first_step',  name: '혼자 걸었어',     description: '비틀거리며 걸어봤어',        icon: '👣', defenseBonus: 12),
  MemoryCard(id: 'flip',        name: '처음 뒤집기',     description: '뒤집어지는 세상을 봤어',     icon: '🔄', attackBonus: 6, defenseBonus: 6),
  MemoryCard(id: 'head_up',     name: '목을 가눴어',     description: '처음으로 세상을 바로 봤어',  icon: '👀', hpHeal: 30),
  MemoryCard(id: 'solid_food',  name: '처음 고체식',     description: '뭔가 씹어먹었어',            icon: '🥣', defenseBonus: 15),
  MemoryCard(id: 'first_word',  name: '처음 말했어',     description: '엄마... 아빠...',            icon: '💬', attackBonus: 15),
  MemoryCard(id: 'peekaboo',    name: '까꿍 놀이',       description: '없어졌다 나타나는 게 재밌어', icon: '🙈', hpHeal: 25),
  MemoryCard(id: 'clap',        name: '짝짝짝',          description: '손뼉 치는 법을 배웠어',      icon: '👏', attackBonus: 10, defenseBonus: 3),
  MemoryCard(id: 'rattle',      name: '딸랑이를 흔들어', description: '소리가 나! 내가 만든 소리!', icon: '🎵', attackBonus: 7, defenseBonus: 7),
  MemoryCard(id: 'blanket',     name: '담요가 포근해',   description: '이 안이 가장 안전해',         icon: '🛏️', defenseBonus: 10, hpHeal: 15),
  MemoryCard(id: 'mobile',      name: '모빌이 돌아',     description: '빙글빙글... 예쁘다',          icon: '🌀', attackBonus: 3, defenseBonus: 3, hpHeal: 10),
];
