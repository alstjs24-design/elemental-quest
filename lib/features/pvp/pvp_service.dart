import 'package:cloud_firestore/cloud_firestore.dart';

class DefenseTeam {
  final String userId;
  final String displayName;
  final List<String> characterIds;
  final int wins;
  final int losses;
  final DateTime updatedAt;

  const DefenseTeam({
    required this.userId,
    required this.displayName,
    required this.characterIds,
    this.wins = 0,
    this.losses = 0,
    required this.updatedAt,
  });

  int get totalBattles => wins + losses;
  double get winRate => totalBattles == 0 ? 0 : wins / totalBattles;

  factory DefenseTeam.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DefenseTeam(
      userId: doc.id,
      displayName: d['displayName'] as String? ?? '알 수 없음',
      characterIds: List<String>.from(d['characterIds'] as List),
      wins: d['wins'] as int? ?? 0,
      losses: d['losses'] as int? ?? 0,
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap(String displayName) => {
    'displayName': displayName,
    'characterIds': characterIds,
    'wins': wins,
    'losses': losses,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class BattleRecord {
  final String attackerId;
  final String defenderId;
  final String winnerId;
  final DateTime timestamp;

  const BattleRecord({
    required this.attackerId,
    required this.defenderId,
    required this.winnerId,
    required this.timestamp,
  });
}

class PvpService {
  static final _db = FirebaseFirestore.instance;
  static const _defenseCol = 'defense_teams';
  static const _resultsCol = 'battle_results';

  static Future<void> registerDefenseTeam({
    required String userId,
    required String displayName,
    required List<String> characterIds,
  }) async {
    await _db.collection(_defenseCol).doc(userId).set(
      DefenseTeam(
        userId: userId,
        displayName: displayName,
        characterIds: characterIds,
        updatedAt: DateTime.now(),
      ).toMap(displayName),
      SetOptions(merge: true),
    );
  }

  static Future<List<DefenseTeam>> fetchLeaderboard({int limit = 20}) async {
    final snap = await _db
        .collection(_defenseCol)
        .orderBy('wins', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(DefenseTeam.fromDoc).toList();
  }

  static Future<DefenseTeam?> fetchRandomOpponent(String myUserId) async {
    final snap = await _db
        .collection(_defenseCol)
        .where(FieldPath.documentId, isNotEqualTo: myUserId)
        .limit(10)
        .get();

    if (snap.docs.isEmpty) return null;

    final docs = snap.docs..shuffle();
    return DefenseTeam.fromDoc(docs.first);
  }

  static Future<void> submitBattleResult({
    required String attackerId,
    required String defenderId,
    required bool attackerWon,
  }) async {
    final batch = _db.batch();

    final resultRef = _db.collection(_resultsCol).doc();
    batch.set(resultRef, {
      'attackerId': attackerId,
      'defenderId': defenderId,
      'winnerId': attackerWon ? attackerId : defenderId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final attackerRef = _db.collection(_defenseCol).doc(attackerId);
    batch.update(attackerRef, {
      if (attackerWon) 'wins': FieldValue.increment(1)
      else 'losses': FieldValue.increment(1),
    });

    final defenderRef = _db.collection(_defenseCol).doc(defenderId);
    batch.update(defenderRef, {
      if (!attackerWon) 'wins': FieldValue.increment(1)
      else 'losses': FieldValue.increment(1),
    });

    await batch.commit();
  }

  static Future<List<BattleRecord>> fetchMyHistory(String userId) async {
    final snap = await _db
        .collection(_resultsCol)
        .where('attackerId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    return snap.docs.map((doc) {
      final d = doc.data();
      return BattleRecord(
        attackerId: d['attackerId'] as String,
        defenderId: d['defenderId'] as String,
        winnerId: d['winnerId'] as String,
        timestamp: (d['timestamp'] as Timestamp).toDate(),
      );
    }).toList();
  }
}
