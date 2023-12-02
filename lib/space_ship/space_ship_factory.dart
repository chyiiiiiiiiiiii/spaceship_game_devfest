import 'package:spaceship_game/space_ship/spaceship.dart';
import 'package:spaceship_game/space_ship/space_ship_build_context.dart';

class SpaceShipFactory {
  SpaceShipFactory._();

  static SpaceShip create(SpaceShipBuildContext context) {
    SpaceShip result;

    /// collect all the Bullet definitions here
    switch (context.spaceShipType) {
      case SpaceShipEnum.simpleSpaceShip:
        {
          if (context.speed != SpaceShipBuildContext.defaultSpeed) {
            result = SimpleSpaceShip.fullInit(
                context.multiplier,
                context.joystick,
                context.size,
                context.speed,
                context.health,
                context.damage);
          } else {
            result = SimpleSpaceShip(context.position, context.joystick);
          }
        }
        break;
    }

    ///
    /// trigger any necessary behavior *before* the instance is handed to the
    /// caller.
    result.onCreate();

    return result;
  }
}
