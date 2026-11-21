import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/dungeon.dart';
import 'dungeon_generator.dart';

class DungeonState {
  final Dungeon? dungeon;
  final bool isLoading;
  final String? errorMessage;

  const DungeonState({
    this.dungeon,
    this.isLoading = false,
    this.errorMessage,
  });

  DungeonState copyWith({
    Dungeon? dungeon,
    bool? isLoading,
    String? errorMessage,
  }) => DungeonState(
    dungeon: dungeon ?? this.dungeon,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
  );

  bool get hasDungeon => dungeon != null;
  DungeonRoom? get currentRoom => dungeon?.currentRoom;
}

class DungeonNotifier extends StateNotifier<DungeonState> {
  DungeonNotifier() : super(const DungeonState());

  void enterFloor(int floor) {
    state = state.copyWith(isLoading: true);
    final dungeon = DungeonGenerator.generate(floor: floor);
    state = DungeonState(dungeon: dungeon);
  }

  void moveToRoom(String roomId) {
    final dungeon = state.dungeon;
    if (dungeon == null) return;

    final current = dungeon.currentRoom;
    if (!current.connectedRoomIds.contains(roomId)) return;

    dungeon.currentRoomId = roomId;
    final target = dungeon.rooms.firstWhere((r) => r.id == roomId);
    target.isVisited = true;

    // 상태 갱신을 트리거하기 위해 copyWith
    state = state.copyWith(dungeon: dungeon);
  }

  void markCurrentRoomCleared() {
    final dungeon = state.dungeon;
    if (dungeon == null) return;
    dungeon.currentRoom.isCleared = true;
    state = state.copyWith(dungeon: dungeon);
  }

  void exitDungeon() {
    state = const DungeonState();
  }

  List<DungeonRoom> get visitedRooms =>
      state.dungeon?.rooms.where((r) => r.isVisited).toList() ?? [];

  List<DungeonRoom> get accessibleRooms {
    final dungeon = state.dungeon;
    if (dungeon == null) return [];
    final currentIds = dungeon.currentRoom.connectedRoomIds;
    return dungeon.rooms.where((r) => currentIds.contains(r.id)).toList();
  }
}

final dungeonProvider = StateNotifierProvider<DungeonNotifier, DungeonState>(
  (ref) => DungeonNotifier(),
);
