import '../enums/element_type.dart';

enum SkillType { attack, heal, buff, debuff }

class Skill {
  final String id;
  final String name;
  final String description;
  final ElementType element;
  final SkillType type;
  final int basePower;
  final int mpCost;
  final int cooldown;

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.element,
    required this.type,
    required this.basePower,
    required this.mpCost,
    this.cooldown = 0,
  });
}
