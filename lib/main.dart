import 'package:flutter/material.dart';
import 'app.dart';
import 'core/theme/flowly_accent.dart';
import 'features/player/player_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlayerController.instance.initialize();
  await FlowLyAccent.initialize();
  runApp(const FlowLyApp());
}
