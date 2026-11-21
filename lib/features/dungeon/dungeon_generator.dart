import 'dart:math';
import '../../core/enums/element_type.dart';
import '../../core/models/dungeon.dart';
import '../../core/models/enemy.dart';
import 'enemy_factory.dart';

class DungeonGenerator {
  static final _rng = Random();

  static Dungeon generate({required int floor}) {
    final theme = _themeForFloor(floor);
    final roomCount = _roomCount(floor);
    final rooms = _buildRooms(floor: floor, theme: theme, count: roomCount);
    final dungeonId = 'dungeon_f${floor}_${DateTime.now().millisecondsSinceEpoch}';

    return Dungeon(
      id: dungeonId,
      name: _dungeonName(floor, theme),
      floor: floor,
      theme: theme,
      rooms: rooms,
      startRoomId: rooms.first.id,
      bossRoomId: rooms.last.id,
    );
  }

  static List<DungeonRoom> _buildRooms({
    required int floor,
    required ElementType theme,
    required int count,
  }) {
    final rooms = <DungeonRoom>[];

    rooms.add(DungeonRoom(
      id: 'room_0',
      type: RoomType.start,
      dominantElement: ElementType.none,
      enemies: [],
      connectedRoomIds: ['room_1'],
      isVisited: true,
    ));

    for (var i = 1; i < count - 1; i++) {
      final type = _randomRoomType();
      final element = _randomElement(theme);
      final enemies = type == RoomType.battle
          ? EnemyFactory.spawnForRoom(floor: floor, element: element, isBoss: false)
          : <Enemy>[];

      rooms.add(DungeonRoom(
        id: 'room_$i',
        type: type,
        dominantElement: element,
        enemies: enemies,
        connectedRoomIds: i < count - 2 ? ['room_${i + 1}'] : ['room_${count - 1}'],
      ));
    }

    final bossElement = theme;
    rooms.add(DungeonRoom(
      id: 'room_${count - 1}',
      type: RoomType.boss,
      dominantElement: bossElement,
      enemies: EnemyFactory.spawnForRoom(floor: floor, element: bossElement, isBoss: true),
      connectedRoomIds: [],
    ));

    return rooms;
  }

  static RoomType _randomRoomType() {
    final roll = _rng.nextInt(100);
    if (roll < 70) return RoomType.battle;
    if (roll < 85) return RoomType.treasure;
    return RoomType.rest;
  }

  static ElementType _randomElement(ElementType theme) {
    if (_rng.nextInt(3) == 0) {
      final others = ElementType.values
          .where((e) => e != ElementType.none && e != theme)
          .toList();
      return others[_rng.nextInt(others.length)];
    }
    return theme;
  }

  static ElementType _themeForFloor(int floor) {
    final themes = [
      ElementType.fire,
      ElementType.water,
      ElementType.earth,
      ElementType.wind,
    ];
    return themes[(floor - 1) % themes.length];
  }

  static int _roomCount(int floor) => 5 + min(floor, 5);

  static String _dungeonName(int floor, ElementType theme) {
    const themeNames = {
      ElementType.fire: '불꽃',
      ElementType.water: '물의',
      ElementType.earth: '대지',
      ElementType.wind: '폭풍',
      ElementType.none: '???',
    };
    return '${themeNames[theme]!} 던전 $floor층';
  }
}
