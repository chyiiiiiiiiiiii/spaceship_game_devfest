import 'dart:math';

import 'package:flame/components.dart';

class Utils {
  /// 隨機生成向量
  static Vector2 randomVector() {
    Vector2 result;

    final Random rnd = Random();
    const int min = -1;
    const int max = 1;
    double numX = min + ((max - min) * rnd.nextDouble());
    double numY = min + ((max - min) * rnd.nextDouble());
    result = Vector2(numX, numY);

    return result;
  }

  /// 生成隨機向量，並添加速度，也就是一秒可移動多少像素
  static Vector2 randomSpeed({required double movePixels}) {
    return randomVector()..scale(movePixels);
  }

  /// 随机生成一个位置
  static Vector2 generateRandomPosition({
    required Vector2 screenSize,
    Vector2? margins,
  }) {
    var result = Vector2.zero();
    var randomGenerator = Random();

    final marginX = (margins?.x ?? 0);
    final marginY = (margins?.y ?? 0);

    result = Vector2(
        randomGenerator
                .nextInt(screenSize.x.toInt() - 2 * marginX.toInt())
                .toDouble() +
            marginX,
        randomGenerator
                .nextInt(screenSize.y.toInt() - 2 * marginY.toInt())
                .toDouble() +
            marginY);

    return result;
  }

  /// 隨機生成一個向量並添加隨機速度
  static Vector2 generateRandomVelocity(Vector2 screenSize, int min, int max) {
    var result = Vector2.zero();
    var randomGenerator = Random();
    double velocity;

    while (result == Vector2.zero()) {
      result = Vector2(
          (randomGenerator.nextInt(3) - 1) * randomGenerator.nextDouble(),
          (randomGenerator.nextInt(3) - 1) * randomGenerator.nextDouble());
    }
    result.normalize();
    velocity = (randomGenerator.nextInt(max - min) + min).toDouble();

    return result * velocity;
  }

  /// 隨機生成向量，以象限代表，中間為(0,0)
  static Vector2 generateRandomDirection() {
    var result = Vector2.zero();
    var randomGenerator = Random();

    while (result == Vector2.zero()) {
      result = Vector2(
          (randomGenerator.nextInt(3) - 1), (randomGenerator.nextInt(3) - 1));
    }

    return result;
  }

  /// 根據範圍，隨機生成移動像素，也就是一秒可移動多少像素
  static double generateRandomSpeed(int min, int max) {
    var randomGenerator = Random();
    double speed;

    speed = (randomGenerator.nextInt(max - min) + min).toDouble();

    return speed;
  }

  /// 檢查目標物位置是否跑出螢幕邊界
  static bool isPositionOutOfBounds(Vector2 bounds, Vector2 position) {
    bool result = false;

    if (position.x < 0 || position.x > bounds.x) {
      result = true;
    }

    if (position.y < 0 || position.y > bounds.y) {
      result = true;
    }

    return result;
  }

  /// 確保物體都在螢幕、畫面內
  /// 如果超出螢幕，就會從另一端出現
  static Vector2 wrapPosition(Vector2 bounds, Vector2 position) {
    Vector2 result = position;

    if (position.x >= bounds.x) {
      result.x = 0;
    } else if (position.x <= 0) {
      result.x = bounds.x;
    }

    if (position.y >= bounds.y) {
      result.y = 0;
    } else if (position.y <= 0) {
      result.y = bounds.y;
    }

    return result;
  }

  static Vector2 vector2Multiply(Vector2 v1, Vector2 v2) {
    v1.multiply(v2);
    return v1;
  }
}
