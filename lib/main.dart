import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:spaceship_game/game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Flame.device.setPortrait();
  await Flame.device.fullScreen();

  final example = SpaceshipGame();

  runApp(
    GameWidget(game: example),
  );
}
