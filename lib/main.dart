import 'package:flutter/material.dart';
import 'app.dart';
import 'features/player/player_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlayerController.instance.initialize();
  runApp(const FlowLyApp());
}
