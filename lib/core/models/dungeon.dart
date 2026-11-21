import '../enums/element_type.dart';
import 'enemy.dart';

enum RoomType { battle, treasure, rest, boss, start }

class DungeonRoom {
  final String id;
  final RoomType type;
  final ElementType dominantElement;
  final List<Enemy> enemies;
  final List<String> connectedRoomIds;

  bool isCleared;
  bool isVisited;

  DungeonRoom({
    required this.id,
    required this.type,
    required this.dominantElement,
    required this.enemies,
    required this.connectedRoomIds,
    this.isCleared = false,
    this.isVisited = false,
  });
}

class Dungeon {
  final String id;
  final String name;
  final int floor;
  final ElementType theme;
  final List<DungeonRoom> rooms;
  final String startRoomId;
  final String bossRoomId;

  String currentRoomId;

  Dungeon({
    required this.id,
    required this.name,
    required this.floor,
    required this.theme,
    required this.rooms,
    required this.startRoomId,
    required this.bossRoomId,
  }) : currentRoomId = startRoomId;

  DungeonRoom get currentRoom =>
      rooms.firstWhere((r) => r.id == currentRoomId);
}
