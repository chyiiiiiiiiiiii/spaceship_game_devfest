import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:spaceship_game/game.dart';

import '../bullet/bullet.dart';
import '../other/utils.dart';

enum SpaceShipEnum { simpleSpaceShip }

abstract class SpaceShip extends SpriteComponent
    with HasGameRef<SpaceshipGame>, CollisionCallbacks {
  // default values
  static const double defaultSpeed = 100.00;
  static const double defaultMaxSpeed = 300.00;
  static const int defaultDamage = 1;
  static const int defaultHealth = 1;
  static final defaultSize = Vector2.all(5.0);

  // velocity vector for the asteroid.
  late Vector2 _velocity;

  // speed of the asteroid
  late double _speed;

  // health of the asteroid
  late final int? _health;

  // damage that the asteroid does
  late final int? _damage;

  // resolution multiplier
  late final Vector2 _resolutionMultiplier;

  /// Pixels/s
  late final double _maxSpeed = defaultMaxSpeed;

  /// current bullet type
  final BulletEnum _currentBulletType = BulletEnum.fastBullet;

  /// Single pixel at the location of the tip of the spaceship
  /// We use it to quickly calculate the position of the rotated nose of the
  /// ship so we can get the position of where the bullets are shooting from.
  /// We make it transparent so it is not visible at all.
  static final _paint = Paint()..color = Colors.transparent;

  /// Muzzle pixel for shooting
  final RectangleComponent _muzzleComponent =
      RectangleComponent(size: Vector2(1, 1), paint: _paint);

  late final JoystickComponent _joystick;

  //
  // default constructor with default values
  SpaceShip(Vector2 resolutionMultiplier, JoystickComponent joystick)
      : _health = defaultHealth,
        _damage = defaultDamage,
        _resolutionMultiplier = resolutionMultiplier,
        _joystick = joystick,
        super(
          size: defaultSize,
          anchor: Anchor.center,
        );

  //
  // named constructor
  SpaceShip.fullInit(Vector2 resolutionMultiplier, JoystickComponent joystick,
      {Vector2? size, double? speed, int? health, int? damage})
      : _resolutionMultiplier = resolutionMultiplier,
        _joystick = joystick,
        _speed = speed ?? defaultSpeed,
        _health = health ?? defaultHealth,
        _damage = damage ?? defaultDamage,
        super(
          size: size,
          anchor: Anchor.center,
        );

  ///////////////////////////////////////////////////////
  // getters
  //
  BulletEnum get getBulletType {
    return _currentBulletType;
  }

  RectangleComponent get getMuzzleComponent {
    return _muzzleComponent;
  }

  void onCreate() {
    anchor = Anchor.center;

    // 設置飛船的體積
    size = Vector2.all(60.0);

    // 新增碰撞邊界
    add(RectangleHitbox());
  }

  void onDestroy();

  //
  // Called when the Bullet has been hit. The ‘other’ is what the bullet hit, or was hit by.
  void onHit(PositionComponent other);

  Vector2 getNextPosition() {
    return Utils.wrapPosition(gameRef.size, position);
  }
}

/// This class creates a fast bullet implementation of the [Bullet] contract and
/// renders the bullet as a simple green square.
/// Speed has been defaulted to 150 p/s but can be changed through the
/// constructor. It is set with a damage of 1 which is the lowest damage and
/// with health of 1 which means that it will be destroyed on impact since it
/// is also the lowest health you can have.
///
class SimpleSpaceShip extends SpaceShip {
  static const double defaultSpeed = 300.00;
  static final Vector2 defaultSize = Vector2.all(2.00);

  SimpleSpaceShip(Vector2 resolutionMultiplier, JoystickComponent joystick)
      : super.fullInit(resolutionMultiplier, joystick,
            size: defaultSize,
            speed: defaultSpeed,
            health: SpaceShip.defaultHealth,
            damage: SpaceShip.defaultDamage);

  //
  // named constructor
  SimpleSpaceShip.fullInit(
      Vector2 resolutionMultiplier,
      JoystickComponent joystick,
      Vector2? size,
      double? speed,
      int? health,
      int? damage)
      : super.fullInit(resolutionMultiplier, joystick,
            size: size, speed: speed, health: health, damage: damage);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    size.y = size.x;

    // 設置飛船樣貌、外觀
    sprite = await gameRef.loadSprite('asteroids_ship.png');
    // 飛船的初始位置，在螢幕中間
    position = gameRef.size / 2;

    _muzzleComponent.position.x = size.x / 2;
    _muzzleComponent.position.y = size.y / 10;

    add(_muzzleComponent);
  }

  @override
  void update(double dt) {
    final isUsingJoystick = !_joystick.delta.isZero();
    final joystickAngle = _joystick.delta.screenAngle();

    // 檢查現在是否使用搖桿操作飛船
    if (isUsingJoystick) {
      // 更新飛船位置，透過 delta 和速度去計算出一幀的移動量，添加新的移動距離
      getNextPosition().add(_joystick.relativeDelta * _maxSpeed * dt);

      // 更新飛船角度，根據搖桿的角度
      angle = joystickAngle;

      return;
    }

    // 檢查現在是否使用鍵盤操作飛船
    final isUsingKeyboard = !gameRef.keyboardDirection.isZero();
    if (isUsingKeyboard) {
      // 更新飛船位置，透過 delta 和速度去計算出一幀的移動量，添加新的移動距離
      getNextPosition().add(gameRef.keyboardDirection * _maxSpeed * dt);

      // 更新飛船角度，根據鍵盤方向鍵的按壓去判斷飛船的角度
      final keyboardAngle = gameRef.keyboardDirection.screenAngle();
      angle = keyboardAngle + joystickAngle;

      return;
    }
  }

  @override
  void onDestroy() {}

  @override
  void onHit(PositionComponent other) {}
}
