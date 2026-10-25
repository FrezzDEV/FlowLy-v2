import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowly/core/theme/flowly_accent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const preferenceKey = 'flowly.appearance.accentColor';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlowLyAccent.listenable.value = FlowLyAccent.defaultColor;
  });

  test('restores the selected accent from persistent storage', () async {
    const savedAccent = Color(0xFF73C9FF);
    SharedPreferences.setMockInitialValues({
      preferenceKey: savedAccent.toARGB32(),
    });
    FlowLyAccent.listenable.value = const Color(0xFFFF70A6);

    await FlowLyAccent.initialize();

    expect(FlowLyAccent.color, savedAccent);
  });

  test('resets to the default accent when no saved value exists', () async {
    FlowLyAccent.listenable.value = const Color(0xFFB28BFF);

    await FlowLyAccent.initialize();

    expect(FlowLyAccent.color, FlowLyAccent.defaultColor);
  });

  test('persists the selected accent color', () async {
    const selectedAccent = Color(0xFFFFC66D);

    await FlowLyAccent.setColor(selectedAccent);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt(preferenceKey),
      selectedAccent.toARGB32(),
    );
  });
}
