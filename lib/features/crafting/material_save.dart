import 'package:hive_flutter/hive_flutter.dart';
import '../../core/enums/element_type.dart';
import '../../core/models/material_item.dart';

const _boxName = 'materials';

class MaterialSave {
  static Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
  }

  static Future<void> saveMaterials(List<MaterialItem> items) async {
    final box = Hive.box<Map>(_boxName);
    await box.clear();
    for (final m in items) {
      await box.put(m.id, _serialize(m));
    }
  }

  static List<MaterialItem> loadMaterials() {
    final box = Hive.box<Map>(_boxName);
    return box.values
        .map((v) => _deserialize(Map<String, dynamic>.from(v)))
        .toList();
  }

  static Map<String, dynamic> _serialize(MaterialItem m) => {
    'id':      m.id,
    'typeId':  m.typeId,
    'name':    m.name,
    'element': m.element.index,
    'rarity':  m.rarity.index,
    'icon':    m.icon,
  };

  static MaterialItem _deserialize(Map<String, dynamic> d) => MaterialItem(
    id:      d['id'] as String,
    typeId:  d['typeId'] as String,
    name:    d['name'] as String,
    element: ElementType.values[d['element'] as int],
    rarity:  MaterialRarity.values[d['rarity'] as int],
    icon:    d['icon'] as String,
  );
}
