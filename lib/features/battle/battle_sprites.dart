// Placeholder sprite widgets — swap emoji/gradient for real assets when art is ready.
// EnemySprite and PlayerSprite both idle-bob continuously.
import 'package:flutter/material.dart';
import '../../core/enums/element_type.dart';
import '../../core/models/character.dart';
import '../../core/models/enemy.dart';

class EnemySprite extends StatefulWidget {
  final Enemy enemy;
  final double size;
  const EnemySprite({super.key, required this.enemy, this.size = 100});

  @override
  State<EnemySprite> createState() => _EnemySpriteState();
}

class _EnemySpriteState extends State<EnemySprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bob;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _bob = Tween<double>(begin: -5.0, end: 5.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _enemyTheme(widget.enemy.element, widget.enemy.grade);
    return AnimatedBuilder(
      animation: _bob,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _bob.value), child: child),
      child: _SpriteFrame(
        size: widget.size,
        emoji: theme.emoji,
        gradientColors: theme.colors,
        glowColor: theme.glow,
        isBoss: widget.enemy.grade == EnemyGrade.boss,
      ),
    );
  }
}

class PlayerSprite extends StatefulWidget {
  final Character character;
  final double size;
  const PlayerSprite({super.key, required this.character, this.size = 90});

  @override
  State<PlayerSprite> createState() => _PlayerSpriteState();
}

class _PlayerSpriteState extends State<PlayerSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bob;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _bob = Tween<double>(begin: -4.0, end: 4.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _playerTheme(widget.character.element);
    return AnimatedBuilder(
      animation: _bob,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _bob.value), child: child),
      child: _SpriteFrame(
        size: widget.size,
        emoji: theme.emoji,
        gradientColors: theme.colors,
        glowColor: theme.glow,
        isBoss: false,
      ),
    );
  }
}

class _SpriteFrame extends StatelessWidget {
  final double size;
  final String emoji;
  final List<Color> gradientColors;
  final Color glowColor;
  final bool isBoss;

  const _SpriteFrame({
    required this.size,
    required this.emoji,
    required this.gradientColors,
    required this.glowColor,
    required this.isBoss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.55),
            blurRadius: isBoss ? 28 : 18,
            spreadRadius: isBoss ? 4 : 2,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.15),
            blurRadius: 50,
            spreadRadius: 8,
          ),
        ],
        border: Border.all(
          color: isBoss
              ? Colors.red.shade300.withValues(alpha: 0.8)
              : glowColor.withValues(alpha: 0.6),
          width: isBoss ? 2.0 : 1.5,
        ),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }
}

class _SpriteTheme {
  final String emoji;
  final List<Color> colors;
  final Color glow;
  const _SpriteTheme(this.emoji, this.colors, this.glow);
}

_SpriteTheme _enemyTheme(ElementType element, EnemyGrade grade) {
  switch (element) {
    case ElementType.fire:
      return grade == EnemyGrade.boss
          ? _SpriteTheme('🐉', [const Color(0xFF6A0000), const Color(0xFFB71C1C)], const Color(0xFFFF5722))
          : _SpriteTheme('👺', [const Color(0xFF3E0A00), const Color(0xFF7B1900)], const Color(0xFFE07840));
    case ElementType.water:
      return grade == EnemyGrade.boss
          ? _SpriteTheme('🦑', [const Color(0xFF002244), const Color(0xFF0D47A1)], const Color(0xFF29B6F6))
          : _SpriteTheme('🐟', [const Color(0xFF061428), const Color(0xFF0A2A6E)], const Color(0xFF42A5F5));
    case ElementType.earth:
      return grade == EnemyGrade.boss
          ? _SpriteTheme('🦎', [const Color(0xFF102010), const Color(0xFF1B5E20)], const Color(0xFF66BB6A))
          : _SpriteTheme('🌵', [const Color(0xFF081508), const Color(0xFF143214)], const Color(0xFF4CAF50));
    case ElementType.wind:
      return grade == EnemyGrade.boss
          ? _SpriteTheme('🌪️', [const Color(0xFF003040), const Color(0xFF006064)], const Color(0xFF26C6DA))
          : _SpriteTheme('🦋', [const Color(0xFF001820), const Color(0xFF002B30)], const Color(0xFF00BCD4));
    case ElementType.none:
      return _SpriteTheme('👾', [const Color(0xFF12102A), const Color(0xFF1E1A3A)], const Color(0xFF7E57C2));
  }
}

_SpriteTheme _playerTheme(ElementType element) {
  switch (element) {
    case ElementType.fire:
      return _SpriteTheme('🧙', [const Color(0xFF2A0A00), const Color(0xFF5C1500)], const Color(0xFFE07840));
    case ElementType.water:
      return _SpriteTheme('🧜', [const Color(0xFF021020), const Color(0xFF082040)], const Color(0xFF42A5F5));
    case ElementType.earth:
      return _SpriteTheme('🧝', [const Color(0xFF081008), const Color(0xFF102010)], const Color(0xFF4CAF50));
    case ElementType.wind:
      return _SpriteTheme('🧚', [const Color(0xFF001015), const Color(0xFF002028)], const Color(0xFF00BCD4));
    case ElementType.none:
      return _SpriteTheme('⚔️', [const Color(0xFF10101E), const Color(0xFF1A1A30)], const Color(0xFF7E57C2));
  }
}

/// Accent color for an element — used for glow and HP bars.
Color elemAccentColor(ElementType element) => switch (element) {
      ElementType.fire  => const Color(0xFFE07840),
      ElementType.water => const Color(0xFF42A5F5),
      ElementType.earth => const Color(0xFF4CAF50),
      ElementType.wind  => const Color(0xFF00BCD4),
      ElementType.none  => const Color(0xFF7E57C2),
    };

/// Single emoji icon for an element.
String elemIcon(ElementType element) => switch (element) {
      ElementType.fire  => '🔥',
      ElementType.water => '💧',
      ElementType.earth => '🌍',
      ElementType.wind  => '🌪',
      ElementType.none  => '⚪',
    };
