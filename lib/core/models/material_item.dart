import '../enums/element_type.dart';

enum MaterialRarity { common, rare, epic }

class MaterialItem {
  final String id;
  final String typeId;
  final String name;
  final ElementType element;
  final MaterialRarity rarity;
  final String icon;

  const MaterialItem({
    required this.id,
    required this.typeId,
    required this.name,
    required this.element,
    required this.rarity,
    required this.icon,
  });
}

String materialIcon(ElementType element, MaterialRarity rarity) {
  if (rarity == MaterialRarity.epic) return '💠';
  return switch (element) {
    ElementType.fire  => '🔥',
    ElementType.water => '💧',
    ElementType.earth => '🪨',
    ElementType.wind  => '🌀',
    ElementType.none  => '⬜',
  };
}

String materialName(ElementType element, MaterialRarity rarity) {
  final rare = rarity == MaterialRarity.rare ? '정제된 ' : rarity == MaterialRarity.epic ? '고급 ' : '';
  final elem = switch (element) {
    ElementType.fire  => '불꽃',
    ElementType.water => '물의',
    ElementType.earth => '대지의',
    ElementType.wind  => '바람의',
    ElementType.none  => '무속성',
  };
  final type = rarity == MaterialRarity.epic ? '정수' : rarity == MaterialRarity.rare ? '결정' : '파편';
  return '$rare$elem $type';
}

String materialTypeId(ElementType element, MaterialRarity rarity) {
  final r = switch (rarity) {
    MaterialRarity.common => 'shard',
    MaterialRarity.rare   => 'crystal',
    MaterialRarity.epic   => 'essence',
  };
  return '${element.name}_$r';
}
