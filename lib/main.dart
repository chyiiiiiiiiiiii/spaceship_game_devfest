import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import './command.dart';
import './controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Flame.device.setPortrait();
  await Flame.device.fullScreen();

  final example = SpaceshipGame();

  runApp(
    GameWidget(game: example),
  );
}

class SpaceshipGame extends FlameGame
    with DragCallbacks, TapDetector, HasCollisionDetection, KeyboardEvents {
  @override

  /// If true, the components will be with HitBox
  bool debugMode = false;

  /// A game controller which manage the all actions in the game
  late final Controller controller;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    FlameAudio.bgm.initialize();

    /// initialize resources
    loadResources();

    /// Add a Controller to the game
    controller = Controller();
    add(controller);

    /// note that we use 'await' which will wait to load the data before any
    /// of the other code continues this way we know that out Controller's state
    /// data is correct.
    await controller.init();
  }

  @override
  //
  //
  // We will handle the tap action by the user to shoot a bullet
  // each time the user taps and lifts their finger
  void onTap() {
    UserTapUpCommand(controller.getSpaceship()).addToController(controller);

    super.onTap();
  }

  @override
  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isKeyDown = event is RawKeyDownEvent;

    final isDownSpace = keysPressed.contains(LogicalKeyboardKey.space);
    final isDownLeft = keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isDownRight = keysPressed.contains(LogicalKeyboardKey.arrowRight);
    final isDownUp = keysPressed.contains(LogicalKeyboardKey.arrowUp);
    final isDownDown = keysPressed.contains(LogicalKeyboardKey.arrowDown);

    if (isKeyDown) {
      if (isDownSpace) {
        BulletFiredCommand().addToController(controller);
        return KeyEventResult.handled;
      }

      if (isDownLeft) {
        return KeyEventResult.handled;
      }

      if (isDownRight) {
        return KeyEventResult.handled;
      }

      if (isDownUp) {
        return KeyEventResult.handled;
      }

      if (isDownDown) {
        return KeyEventResult.handled;
      }

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Cache and preload the assets
  void loadResources() async {
    await images.load('boom.png');
  }
}
