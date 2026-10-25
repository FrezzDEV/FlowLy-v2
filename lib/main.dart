import 'package:flutter/material.dart';
import 'app.dart';
import 'features/player/player_controller.dart';
import 'features/profile/profile_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlayerController.instance.initialize();
  await ProfileController.instance.initialize();
  runApp(const FlowLyApp());
}
