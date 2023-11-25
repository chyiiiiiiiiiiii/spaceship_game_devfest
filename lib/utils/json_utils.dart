import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:spaceship_game/asteroid/asteroid_build_context.dart';

import '../controller.dart';
import '../game_bonus.dart';

///
/// JSON Utilities for the Asteroids game
///
/// Will primarily be used by the Controller to initialize the game
/// elements and game data such as levels, resolution multiplier etc...
///
class JSONUtils {
  /// read the JSON data from a hardcoded location (for now)
  ///
  static dynamic readJSONInitData() async {
    List levels = [];
    Map<String, dynamic> jsonDataResolution = <String, dynamic>{};
    List jsonDataLevels = [];
    final String response =
        await rootBundle.loadString('assets/game_config.json');
    final data = await json.decode(response);
    jsonDataResolution = data["game_data"]["resolution"];
    jsonDataLevels = data["game_data"]["levels"];
    debugPrint('{readJSONInitData} <resolution> : $jsonDataResolution');
    debugPrint(
        '{readJSONInitData} <levels>: $jsonDataLevels #: ${jsonDataLevels.length}');
    //_levels = _jsonData["levels"];
    return data;
  }

  /// extract the game levels from the dynamic JSON [data]
  ///
  static List<GameLevel> extractGameLevels(dynamic data) {
    List<GameLevel> result = List.empty(growable: true);

    List jsonDataLevels = [];
    jsonDataLevels = data["game_data"]["levels"];

    for (var level in jsonDataLevels) {
      GameLevel gameLevel = GameLevel();
      List<AsteroidBuildContext> asteroidContextList =
          _buildAsteroidData(level);
      List<GameBonusBuildContext> gameBonusContextList =
          _buildGameBonusData(level);
      gameLevel
        ..asteroidConfig = asteroidContextList
        ..gameBonusConfig = gameBonusContextList;
      gameLevel.init();
      result.add(gameLevel);
    }

    return result;
  }

  /// exatract the game resolution from dynamic JSON [data]
  ///
  static Vector2 extractBaseGameResolution(dynamic data) {
    Vector2 result = Vector2.zero();
    Map jsonDataResolution = {};

    jsonDataResolution = data["game_data"]["resolution"];
    result = Vector2(
        jsonDataResolution["x"].toDouble(), jsonDataResolution["y"].toDouble());

    return result;
  }

  /// Helper Methods
  ///
  ///

  /// Map JSON level data to an [AsteroidBuildContext]
  ///
  static List<AsteroidBuildContext> _buildAsteroidData(Map data) {
    List<AsteroidBuildContext> result = List.empty(growable: true);
    debugPrint('data: $data <length> ${data.length}');

    for (final element in data['asteroids']) {
      AsteroidBuildContext asteroid = AsteroidBuildContext();
      asteroid.asteroidType =
          AsteroidBuildContext.asteroidFromString(element['name']);

      asteroid.position = Vector2(
          element['position.x'].toDouble(), element['position.y'].toDouble());
      asteroid.velocity = Vector2(
          element['velocity.x'].toDouble(), element['velocity.y'].toDouble());

      result.add(asteroid);
    }

    return result;
  }

  /// Map JSON level data to an [AsteroidBuildContext]
  ///
  static List<GameBonusBuildContext> _buildGameBonusData(Map data) {
    List<GameBonusBuildContext> result = List.empty(growable: true);
    debugPrint('data: $data <length> ${data.length}');

    ///
    /// precondition
    ///
    /// check that the actual element exists in the JSON
    if (data['gameBonus'] == null) {
      return result;
    }

    for (final element in data['gameBonus']) {
      GameBonusBuildContext gameBonus = GameBonusBuildContext();
      gameBonus.gameBonusType =
          GameBonusBuildContext.gameBonusFromString(element['name']);
      gameBonus.position = Vector2(
          element['position.x'].toDouble(), element['position.y'].toDouble());
      gameBonus.velocity = Vector2(
          element['velocity.x'].toDouble(), element['velocity.y'].toDouble());
      gameBonus.timeTriggerSeconds = element['trigger.time.seconds'].toInt();

      result.add(gameBonus);
    }

    return result;
  }
}
