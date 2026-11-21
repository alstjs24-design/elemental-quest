// Callers: lib/features/home/home_screen.dart (menu push to PvpScreen)
// Purpose: Async PvP — find opponent, submit result, view leaderboard
// Reads: pvpProvider (PvpState: status, opponent, leaderboard, errorMessage)
// Writes: findOpponent, submitResult, loadLeaderboard, reset on pvpProvider.notifier
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pvp_notifier.dart';

String get _currentUserId =>
    FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

class PvpScreen extends ConsumerStatefulWidget {
  const PvpScreen({super.key});

  @override
  ConsumerState<PvpScreen> createState() => _PvpScreenState();
}

class _PvpScreenState extends ConsumerState<PvpScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    Future.microtask(
        () => ref.read(pvpProvider.notifier).loadLeaderboard());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pvp = ref.watch(pvpProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('비동기 PvP',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFFE07840),
          tabs: const [Tab(text: '대전'), Tab(text: '리더보드')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BattleTab(pvp: pvp),
          _LeaderboardTab(pvp: pvp),
        ],
      ),
    );
  }
}

class _BattleTab extends ConsumerWidget {
  final PvpState pvp;
  const _BattleTab({required this.pvp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pvp.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(pvp.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(pvpProvider.notifier).reset(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return switch (pvp.status) {
      PvpStatus.idle => _IdleView(),
      PvpStatus.searching => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('상대 탐색 중...',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      PvpStatus.inBattle => _OpponentView(pvp: pvp),
      PvpStatus.victory ||
      PvpStatus.defeat =>
        _ResultView(pvp: pvp),
      PvpStatus.error => Center(
          child: Text(pvp.errorMessage ?? '오류',
              style: const TextStyle(color: Colors.red))),
    };
  }
}

class _IdleView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚔️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('다른 유저의 팀과 대결하세요!',
                style:
                    TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => ref
                    .read(pvpProvider.notifier)
                    .findOpponent(_currentUserId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE07840),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('상대 찾기',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpponentView extends ConsumerWidget {
  final PvpState pvp;
  const _OpponentView({required this.pvp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opp = pvp.opponent!;
    final winRate = (opp.winRate * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('상대 발견!',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      const Color(0xFFE07840).withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(opp.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${opp.wins}승 ${opp.losses}패  승률 $winRate%',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(pvpProvider.notifier)
                      .submitResult(
                          myUserId: _currentUserId, iWon: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90D9),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                  ),
                  child: const Text('승리 기록',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(pvpProvider.notifier)
                      .submitResult(
                          myUserId: _currentUserId, iWon: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                  ),
                  child: const Text('패배 기록',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultView extends ConsumerWidget {
  final PvpState pvp;
  const _ResultView({required this.pvp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final won = pvp.status == PvpStatus.victory;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(won ? '🏆 승리!' : '💀 패배',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: won ? Colors.amber : Colors.red)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () =>
                ref.read(pvpProvider.notifier).reset(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90D9),
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 14),
            ),
            child: const Text('돌아가기',
                style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  final PvpState pvp;
  const _LeaderboardTab({required this.pvp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pvp.leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('리더보드 데이터가 없습니다.',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(pvpProvider.notifier).loadLeaderboard(),
              child: const Text('새로고침'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pvp.leaderboard.length,
      itemBuilder: (_, i) {
        final team = pvp.leaderboard[i];
        final rankEmoji = i == 0
            ? '🥇'
            : (i == 1 ? '🥈' : (i == 2 ? '🥉' : '${i + 1}.'));
        return ListTile(
          leading: Text(rankEmoji,
              style: const TextStyle(fontSize: 20)),
          title: Text(team.displayName,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          subtitle: Text('${team.wins}승 ${team.losses}패',
              style:
                  const TextStyle(color: Colors.white54)),
          trailing: Text(
            '${(team.winRate * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                color: team.winRate >= 0.5
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
