import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'command.dart';
import 'controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Flame.device.setPortrait();
  await Flame.device.fullScreen();

  final example = SpaceshipGame();

  runApp(
    GameWidget(game: example),
  );
}

/// This is companion code to the Case Study #8 'Level Generation' which
/// specifically talks about how we use the game configuration JSON data
/// about levels to load and use the Asteroids data as well as the
/// base-resolution to create the resolution multipier.
///
/// In this project  we do the following:
///     - we read the JSON data in controller.init()
///     - we commit that data to the Controller's state data
///     - We calculate the relative sizes of the objects by using
///       the resolution multiuplier.
///     - We create a timer which send a notification to our Controller
///       at 1 seconds intervals. Currently we igniore this but in the next
///     - iteration of code we will add the next-level logic
///
class SpaceshipGame extends FlameGame
    with DragCallbacks, TapDetector, HasCollisionDetection, KeyboardEvents {
  static const String description = '''
    In this example we showcase how to use the joystick by creating simple
    `CircleComponent`s that serve as the joystick's knob and background.
    Steer the player by using the joystick. We also show how to shoot bullets
    and how to find the angle of the bullet path relative to the ship's angle
    We also improve the code here for how to calculate the position of the
    bullet being fired when the ship is rotated.
    The main example here is the Factory Method Design patterns used for
    creation of different types of bullets.
  ''';

  @override

  /// use this flag to put the project into debug mode which will show hitboxes
  bool debugMode = false;

  /// controller used to coordinate all game actions
  Controller? controller;

  //
  // angle of the ship being displayed on canvas
  final TextPaint shipAngleTextPaint = TextPaint();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    FlameAudio.bgm.initialize();

    /// initialize resources
    ///
    loadResources();

    /// Add a controller
    ///
    /// this will load the level JSON Data for all the levels whch will be stored
    /// in Controller state data
    controller = Controller();

    add(controller!);

    /// note that we use 'await' which will wait to load the data before any
    /// of the other code continues thsi way we know that out Controller's state
    /// data is correct.
    await controller?.init();
  }

  @override
  void update(double dt) {
    //
    //  show the angle of the player
    debugPrint("current player angle: ${controller!.getSpaceship().angle}");
    debugPrint("<main update> number of children: ${children.length}");
    super.update(dt);
  }

  @override
  //
  //
  // We will handle the tap action by the user to shoot a bullet
  // each time the user taps and lifts their finger
  void onTap() {
    UserTapUpCommand(controller!.getSpaceship()).addToController(controller!);

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
        BulletFiredCommand().addToController(controller!);
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

  ///
  /// Helper Methods
  ///
  ///

  void loadResources() async {
    /// cache any needed resources
    ///
    await images.load('boom.png');
  }
}
