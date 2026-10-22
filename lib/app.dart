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

class _AppShellState extends State<AppShell> {
  int _selected = 0;
  bool _showPlayer = false;

  late final List<Widget> _pages = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  void _openFullPlayer() {
    setState(() => _showPlayer = true);
  }

  void _beginInteractiveDrag() {}

  void _updateInteractiveDrag(double deltaY) {}

  void _finishInteractiveDrag(double velocityY) {
    if (velocityY < -700) {
      _openFullPlayer();
    } else if (velocityY > 700) {
      _closePlayer();
    }
  }

  void _closePlayer() {
    if (_showPlayer) {
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
                      icon: Icon(Icons.library_music_outlined, size: 16),
                      selectedIcon: Icon(Icons.library_music, size: 16),
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
            child: PlayerTransitionOverlay(
              progress: 1,
              onDragStart: _beginInteractiveDrag,
              onDragUpdate: _updateInteractiveDrag,
              onDragEnd: _finishInteractiveDrag,
              onClose: _closePlayer,
            ),
          ),
      ],
    );
  }
}
