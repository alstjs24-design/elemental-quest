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
