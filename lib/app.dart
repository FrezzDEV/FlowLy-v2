import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';
import 'features/search/search_screen.dart';
import 'features/library/library_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/player/animated_music_player.dart';

class FlowLyApp extends StatelessWidget {
  const FlowLyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF08090B);
    return MaterialApp(
      title: 'FlowLy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB6F36B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        navigationBarTheme: const NavigationBarThemeData(
          indicatorColor: Colors.transparent,
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 10, height: 1),
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        ),
        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  static const _playerTransitionDuration = Duration(milliseconds: 260);

  int _selected = 0;
  bool _showPlayer = false;
  bool _isDraggingPlayer = false;
  late final AnimationController _playerAnimation;

  late final List<Widget> _pages = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _playerAnimation = AnimationController(
      vsync: this,
      value: 0,
      duration: _playerTransitionDuration,
    );
  }

  @override
  void dispose() {
    _playerAnimation.dispose();
    super.dispose();
  }

  Future<void> _openFullPlayer() async {
    if (!mounted) return;
    if (!_showPlayer) {
      setState(() => _showPlayer = true);
    }
    await _playerAnimation.animateTo(
      1,
      duration: _playerTransitionDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _beginInteractiveDrag() {
    _playerAnimation.stop();
    _isDraggingPlayer = true;
    if (!_showPlayer) {
      setState(() => _showPlayer = true);
    }
  }

  void _updateInteractiveDrag(double deltaY) {
    if (!_isDraggingPlayer) return;
    final range = MediaQuery.sizeOf(context).height - 72.0;
    if (range <= 0) return;
    _playerAnimation.value =
        (_playerAnimation.value - deltaY / range).clamp(0.0, 1.0).toDouble();
  }

  void _finishInteractiveDrag(double velocityY) {
    _isDraggingPlayer = false;
    final target = velocityY.abs() > 600
        ? (velocityY < 0 ? 1.0 : 0.0)
        : (_playerAnimation.value > 0.5 ? 1.0 : 0.0);

    if (target == 1) {
      _openFullPlayer();
    } else {
      _closePlayer();
    }
  }

  Future<void> _closePlayer() async {
    if (!_showPlayer) return;
    await _playerAnimation.animateTo(
      0,
      duration: _playerTransitionDuration,
      curve: Curves.easeOutCubic,
    );
    if (mounted && !_isDraggingPlayer && _playerAnimation.value <= 0.001) {
      setState(() => _showPlayer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          body: IndexedStack(index: _selected, children: _pages),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MiniPlayer(
                  onOpen: _openFullPlayer,
                  onDragStart: _beginInteractiveDrag,
                  onDragUpdate: _updateInteractiveDrag,
                  onDragEnd: _finishInteractiveDrag,
                ),
                NavigationBar(
                  height: 54,
                  selectedIndex: _selected,
                  onDestinationSelected: (index) => setState(() => _selected = index),
                  backgroundColor: const Color(0xFF101114),
                  indicatorColor: Colors.transparent,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined, size: 16),
                      selectedIcon: Icon(Icons.home_rounded, size: 16),
                      label: 'Главная',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.search_rounded, size: 16),
                      label: 'Поиск',
                    ),
                    NavigationDestination(
                      icon: _LibraryNavIcon(color: Color(0xFF8E8E8E)),
                      selectedIcon: _LibraryNavIcon(color: Colors.white),
                      label: 'Библиотека',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded, size: 16),
                      selectedIcon: Icon(Icons.person_rounded, size: 16),
                      label: 'Профиль',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_showPlayer)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _playerAnimation,
              builder: (context, _) => PlayerTransitionOverlay(
                progress: _playerAnimation.value,
                onDragStart: _beginInteractiveDrag,
                onDragUpdate: _updateInteractiveDrag,
                onDragEnd: _finishInteractiveDrag,
                onClose: _closePlayer,
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom "Your Library" waveform-like glyph from the original FlowLy app.
class _LibraryNavIcon extends StatelessWidget {
  const _LibraryNavIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 16,
        height: 16,
        child: CustomPaint(painter: _LibraryNavPainter(color)),
      );
}

class _LibraryNavPainter extends CustomPainter {
  const _LibraryNavPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final centerY = 12.0;
    canvas.drawLine(Offset(3, centerY - 7), Offset(3, centerY + 7), paint);
    canvas.drawLine(Offset(9, centerY - 9), Offset(9, centerY + 8), paint);
    canvas.drawLine(Offset(15, centerY - 6), Offset(15, centerY + 8), paint);
    canvas.drawLine(Offset(20, centerY - 8), Offset(22, centerY + 7), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LibraryNavPainter oldDelegate) =>
      oldDelegate.color != color;
}
