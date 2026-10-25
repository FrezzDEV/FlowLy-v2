import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared app-wide accent color. White is the default; the profile editor
/// lets the user choose another preset and the selection persists locally.
class FlowLyAccent {
  FlowLyAccent._();

  static const _preferenceKey = 'flowly.appearance.accentColor';
  static const defaultColor = Color(0xFFF5F5F5);
  static final ValueNotifier<Color> listenable =
      ValueNotifier<Color>(defaultColor);

  static Color get color => listenable.value;

  static Future<void> initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedValue = preferences.getInt(_preferenceKey);
      // Always resolve the accent from persistent storage on initialization.
      // This avoids retaining a stale in-memory color when no preference exists.
      listenable.value =
          storedValue == null ? defaultColor : Color(storedValue);
    } catch (_) {
      // Keep the default accent when platform storage is unavailable.
    }
  }

  static Future<void> setColor(Color value) async {
    listenable.value = value;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(_preferenceKey, value.toARGB32());
    } catch (_) {
      // The accent remains applied for the current session.
    }
  }
}
