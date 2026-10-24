import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';
import 'features/search/search_screen.dart';
import 'features/library/library_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/player/draggable_player.dart';

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

class _AppShellState extends State<AppShell> {
  int _selected = 0;
  late final ValueNotifier<int> _selectedTab = ValueNotifier<int>(_selected);

  late final List<Widget> _pages = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  void dispose() {
    _selectedTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => ValueListenableBuilder<int>(
                valueListenable: _selectedTab,
                builder: (context, selected, child) => IndexedStack(
                  index: selected,
                  children: _pages,
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 60),
                NavigationBar(
                  height: 54,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                  selectedIndex: _selected,
                  onDestinationSelected: (index) {
                    setState(() => _selected = index);
                    _selectedTab.value = index;
                  },
                  backgroundColor: const Color(0xFF101114),
                  indicatorColor: Colors.transparent,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_rounded, size: 24),
                      selectedIcon: Icon(Icons.home_rounded, size: 26),
                      label: 'Главная',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.search_rounded, size: 24),
                      selectedIcon: Icon(Icons.search_rounded, size: 26),
                      label: 'Поиск',
                    ),
                    NavigationDestination(
                      icon: _LibraryNavIcon(color: Color(0xFF8E8E8E)),
                      selectedIcon: _LibraryNavIcon(color: Colors.white),
                      label: 'Библиотека',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded, size: 24),
                      selectedIcon: Icon(Icons.person_rounded, size: 26),
                      label: 'Профиль',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const DraggableView(),
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
        width: 24,
        height: 24,
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
