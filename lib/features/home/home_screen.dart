// Callers: lib/main.dart (home route)
// Purpose: Main menu — navigate to Dungeon, PvP, Character screens
// Reads: characterProvider (activeCharacter.name, level)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../character/character_notifier.dart';
import '../character/character_screen.dart';
import '../dungeon/dungeon_screen.dart';
import '../legacy/legacy_notifier.dart';
import '../legacy/legacy_screen.dart';
import '../pvp/pvp_screen.dart';
import '../run/run_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(characterProvider.notifier).load();
      await ref.read(legacyProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final charState = ref.watch(characterProvider);
    final character = charState.activeCharacter;
    final legacy = ref.watch(legacyProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A2E), Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
                      Text(
                '아기의 꿈',
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.soul,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(color: AppColors.dungeon.withValues(alpha: 0.6), blurRadius: 24),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '내면 세계로의 여정',
                style: AppTextStyles.bodySmall.copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 10),
              if (character != null)
                Text(
                  '${character.name}  Lv.${character.level}',
                  style: AppTextStyles.bodyMedium,
                ),
              if (legacy.soulFragments > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '💎 ${legacy.soulFragments} 영혼 파편',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.soul),
                  ),
                ),
              const Spacer(),
              _MenuButton(
                icon: '😴',
                label: '낮잠 런',
                subtitle: '꿈속 여정 — 추억을 모아 강해져',
                color: const Color(0xFF4DB6AC),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RunScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: '🗺️',
                label: '던전 탐험',
                subtitle: '로그라이크 던전 도전',
                color: const Color(0xFF8B2FC9),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DungeonScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: '⚔️',
                label: '비동기 PvP',
                subtitle: '다른 유저의 팀과 대결',
                color: const Color(0xFFE07840),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PvpScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: '👤',
                label: '캐릭터',
                subtitle: '성장 & 장비 관리',
                color: const Color(0xFF4A90D9),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CharacterScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: '⚗️',
                label: '유산',
                subtitle: '영혼 파편으로 영구 강화',
                color: const Color(0xFF9C27B0),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LegacyScreen()),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text('v0.1.0', style: AppTextStyles.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: AppTextStyles.titleMedium.copyWith(color: color)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
