import '../../core/enums/element_type.dart';
import '../../core/models/enemy.dart';
import '../../core/models/skill.dart';

class EnemyFactory {
  static List<Enemy> spawnForRoom({
    required int floor,
    required ElementType element,
    required bool isBoss,
  }) {
    if (isBoss) {
      return [_createBoss(floor: floor, element: element)];
    }
    return [_createNormal(floor: floor, element: element)];
  }

  static Enemy _createNormal({required int floor, required ElementType element}) {
    final scale = 1.0 + (floor - 1) * 0.15;
    final names = _namesFor(element);
    final name = names[(floor + element.index) % names.length];
    final id = '${element.name}_normal_f${floor}_${DateTime.now().millisecondsSinceEpoch}';

    return Enemy(
      id: id,
      name: name,
      element: element,
      grade: EnemyGrade.normal,
      maxHp: (80 * scale).round(),
      attack: (20 * scale).round(),
      defense: (10 * scale).round(),
      speed: (15 * scale).round(),
      skills: [],
      expReward: (20 * scale).round(),
      goldReward: 10 * scale,
      tendency: _tendencyFor(element),
    );
  }

  static Enemy _createBoss({required int floor, required ElementType element}) {
    final scale = 1.0 + (floor - 1) * 0.2;
    final bossNames = _bossNamesFor(element);
    final name = bossNames[floor % bossNames.length];
    final id = '${element.name}_boss_f${floor}_${DateTime.now().millisecondsSinceEpoch}';

    final bossSkill = Skill(
      id: 'boss_skill_${element.name}',
      name: _bossSkillName(element),
      description: '강력한 속성 공격',
      element: element,
      type: SkillType.attack,
      basePower: (50 * scale).round(),
      mpCost: 0,
      cooldown: 3,
    );

    return Enemy(
      id: id,
      name: name,
      element: element,
      grade: EnemyGrade.boss,
      maxHp: (300 * scale).round(),
      attack: (40 * scale).round(),
      defense: (20 * scale).round(),
      speed: (12 * scale).round(),
      skills: [bossSkill],
      expReward: (100 * scale).round(),
      goldReward: 50 * scale,
      tendency: BattleTendency.unpredictable,
    );
  }

  static BattleTendency _tendencyFor(ElementType element) {
    switch (element) {
      case ElementType.fire:
        return BattleTendency.aggressive;
      case ElementType.water:
        return BattleTendency.evasive;
      case ElementType.earth:
        return BattleTendency.defensive;
      case ElementType.wind:
        return BattleTendency.evasive;
      case ElementType.none:
        return BattleTendency.unpredictable;
    }
  }

  // ── Run mode (낮잠 런 / 꿈 세계관) spawn ──────────────────────────────────
  static List<Enemy> spawnForRunRoom({
    required int floor,
    required ElementType element,
    required bool isBoss,
  }) {
    if (isBoss) {
      return [_createRunBoss(floor: floor, element: element)];
    }
    return [_createRunNormal(floor: floor, element: element)];
  }

  static Enemy _createRunNormal({required int floor, required ElementType element}) {
    final scale = 1.0 + (floor - 1) * 0.15;
    final names = _runNamesFor(element);
    final name = names[(floor + element.index) % names.length];
    final id = 'run_${element.name}_f${floor}_${DateTime.now().millisecondsSinceEpoch}';
    return Enemy(
      id: id,
      name: name,
      element: element,
      grade: EnemyGrade.normal,
      maxHp: (80 * scale).round(),
      attack: (20 * scale).round(),
      defense: (10 * scale).round(),
      speed: (15 * scale).round(),
      skills: [],
      expReward: (20 * scale).round(),
      goldReward: 10 * scale,
      tendency: _tendencyFor(element),
    );
  }

  static Enemy _createRunBoss({required int floor, required ElementType element}) {
    final scale = 1.0 + (floor - 1) * 0.2;
    final id = 'run_boss_f${floor}_${DateTime.now().millisecondsSinceEpoch}';
    final bossSkill = Skill(
      id: 'run_boss_skill',
      name: '분리의 절규',
      description: '꿈속 깊은 두려움이 폭발한다',
      element: element,
      type: SkillType.attack,
      basePower: (50 * scale).round(),
      mpCost: 0,
      cooldown: 3,
    );
    return Enemy(
      id: id,
      name: '분리불안의 화신',
      element: element,
      grade: EnemyGrade.boss,
      maxHp: (300 * scale).round(),
      attack: (40 * scale).round(),
      defense: (20 * scale).round(),
      speed: (12 * scale).round(),
      skills: [bossSkill],
      expReward: (100 * scale).round(),
      goldReward: 50 * scale,
      tendency: BattleTendency.unpredictable,
    );
  }

  // 꿈 세계관: 아기의 감각/감정 의인화
  static List<String> _runNamesFor(ElementType element) {
    switch (element) {
      case ElementType.fire:
        return ['갑작스런 빛', '낯선 소리', '따가운 감각', '뜨거운 무언가'];
      case ElementType.water:
        return ['미끄러운 느낌', '흘러내리는 감각', '떠가는 무언가', '차가운 기억'];
      case ElementType.earth:
        return ['무거운 무언가', '짓누르는 감각', '굳어버린 두려움', '단단한 고집'];
      case ElementType.wind:
        return ['속삭이는 불안', '사라질 것 같은 느낌', '바람 같은 슬픔', '흔들리는 기억'];
      case ElementType.none:
        return ['알 수 없는 무언가', '형체 없는 느낌'];
    }
  }

  // ── Dungeon mode names (기존) ────────────────────────────────────────────────
  static List<String> _namesFor(ElementType element) {
    switch (element) {
      case ElementType.fire:
        return ['불꽃 슬라임', '화염 늑대', '용암 골렘', '불도마뱀'];
      case ElementType.water:
        return ['물 정령', '얼음 늑대', '해파리 마법사', '물의 뱀'];
      case ElementType.earth:
        return ['돌 골렘', '대지 두더지', '흙 거인', '바위 거북'];
      case ElementType.wind:
        return ['폭풍 조류', '번개 여우', '구름 정령', '바람 뱀'];
      case ElementType.none:
        return ['어둠의 존재', '미지의 슬라임'];
    }
  }

  static List<String> _bossNamesFor(ElementType element) {
    switch (element) {
      case ElementType.fire:
        return ['화염왕 이프리트', '태양의 군주'];
      case ElementType.water:
        return ['빙결의 레비아탄', '폭풍의 크라켄'];
      case ElementType.earth:
        return ['대지의 군주 가이아', '산악 타이탄'];
      case ElementType.wind:
        return ['폭풍의 티아맛', '번개 군주'];
      case ElementType.none:
        return ['어둠의 군주'];
    }
  }

  static String _bossSkillName(ElementType element) {
    switch (element) {
      case ElementType.fire:
        return '불꽃 폭풍';
      case ElementType.water:
        return '빙하 붕괴';
      case ElementType.earth:
        return '지진';
      case ElementType.wind:
        return '태풍';
      case ElementType.none:
        return '암흑 폭발';
    }
  }
}
