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
  int _selected = 0;
  late final AnimationController _playerAnimation;
  bool _showPlayer = false;

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
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 350),
      value: 0,
    );
    _playerAnimation.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _showPlayer && mounted) {
        setState(() => _showPlayer = false);
      }
    });
  }

  @override
  void dispose() {
    _playerAnimation.dispose();
    super.dispose();
  }

  void _openFullPlayer() {
    if (!_showPlayer) setState(() => _showPlayer = true);
    _playerAnimation.animateTo(
      1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  void _beginInteractiveDrag() {
    _playerAnimation.stop();
    if (!_showPlayer) setState(() => _showPlayer = true);
  }

  void _updateInteractiveDrag(double deltaY) {
    final height = MediaQuery.sizeOf(context).height;
    _playerAnimation.value =
        (_playerAnimation.value - deltaY / (height * 0.78)).clamp(0.0, 1.0);
  }

  void _finishInteractiveDrag(double velocityY) {
    final shouldExpand = velocityY < -700 ||
        (velocityY <= 700 && _playerAnimation.value >= 0.5);
    if (shouldExpand) {
      _playerAnimation.animateTo(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else if (_playerAnimation.value == 0) {
      setState(() => _showPlayer = false);
    } else {
      _playerAnimation.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _closePlayer() {
    if (_playerAnimation.value == 0) {
      setState(() => _showPlayer = false);
      return;
    }
    _playerAnimation
        .animateBack(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        )
        .whenComplete(() {
      if (!mounted) return;
      if (_playerAnimation.value <= 0.001 && _showPlayer) {
        setState(() => _showPlayer = false);
      }
    });
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
                  selectedIndex: _selected,
                  onDestinationSelected: (index) => setState(() => _selected = index),
                  backgroundColor: const Color(0xFF101114),
                  indicatorColor: Colors.transparent,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Главная',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.search_rounded),
                      label: 'Поиск',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.library_music_outlined),
                      selectedIcon: Icon(Icons.library_music),
                      label: 'Библиотека',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
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
