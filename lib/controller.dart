import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spaceship_game/asteroid/asteroid_build_context.dart';
import 'package:spaceship_game/asteroid/asteroid_factory.dart';
import 'package:spaceship_game/game.dart';
import 'package:spaceship_game/game_bonus/game_bonus_build_context.dart';
import 'package:spaceship_game/game_bonus/game_bonus_factory.dart';
import 'package:spaceship_game/space_ship/space_ship_build_context.dart';
import 'package:spaceship_game/space_ship/space_ship_factory.dart';

import 'asteroid/asteroid.dart';
import 'command/command.dart';
import 'game_bonus/game_bonus.dart';
import 'other/json_utils.dart';
import 'score_board/score_board.dart';
import 'space_ship/spaceship.dart';

/// 管理者，掌握遊戲內的元件與操作
class Controller extends Component with HasGameRef<SpaceshipGame> {
  /// the number of lives that a player starts with (which is the start life
  /// and 3 extra lives)
  static const defaultNumberOfLives = 1;
  static const defaultStartLevel = 0;

  // pause between levels or new lives in seconds
  static const timeoutPauseInSeconds = 3;
  int _pauseCountdown = 0;
  bool _levelDoneFlag = false;
  int _createPlayerCountdown = 0;
  bool _playerDiedFlag = false;

  /// the broker which is a dedicated helper that executes all the commands
  /// on behalf o teh controller
  final Broker _broker = Broker();

  late JoystickComponent _joystick;

  /// all the game levels loaded from JSON
  late List<GameLevel> _gameLevels;
  int _currentGameLevelIndex = 0;

  /// a stack used to hold all the objects from the current level. Once this
  /// list/stack is empty we can go to the next level.
  List currentLevelObjectStack = List.empty(growable: true);

  /// JSON Data from initialization
  late dynamic jsonData;

  /// 遊戲設計的解析度
  late Vector2 _baseResolution;

  /// 計算不同顯示裝置上的參數比例，可適用於元件的位置、大小、速度，保持最佳的顯示效果
  final Vector2 _resolutionMultiplier = Vector2.all(1.0);

  late ScoreBoard _scoreboard;

  /// The SpaceShip being controlled by Joystick
  ///
  late SpaceShip player;

  /// Parallax image assets
  ///
  final _parallaxImages = [
    ParallaxImageData('small_stars.png'),
    ParallaxImageData('big_stars.png'),
  ];

  late final ParallaxComponent parallax;
  final double parallaxSpeed = 25.0;

  /// Restart when the game over.
  ///
  late ButtonComponent restartButton;

  /// add a timer which will notify the controller of the passage of time
  /// timer used to notify the controller about the passage of time
  ///
  late final TimerComponent controllerTimer;

  JoystickComponent getJoystick() {
    return _joystick;
  }

  SpaceShip getSpaceship() {
    return player;
  }

  Images getGameImages() {
    return gameRef.images;
  }

  /// initialization 'hook' this should be called right after the Controller
  /// has been created
  ///
  /// It will initialize the inner state of the
  Future<void> init() async {
    jsonData = await JSONUtils.readJSONInitData();

    /// read in the resolution and calculate the resolution multiplier
    ///
    _baseResolution = JSONUtils.extractBaseGameResolution(jsonData);

    /// calculate the multiplier
    _resolutionMultiplier.x = gameRef.size.x / _baseResolution.x;
    _resolutionMultiplier.y = gameRef.size.y / _baseResolution.y;

    await addScoreBoard();
    await addParallax();
    addJoystick();

    controllerTimer = TimerComponent(
      period: 1,
      repeat: true,
      onTick: () {
        timerNotification();
      },
    );
    add(controllerTimer);

    spawnNewPlayer();
  }

  /// timer hook
  /// We will monitor here the exact passage of time in seconds for the game
  void timerNotification() {
    /// Update time passage in scoreboard
    ///
    UpdateScoreboardTimePassageInfoCommand(_scoreboard).addToController(this);

    if (_scoreboard.getCurrentLevel > 0) {
      int currentTimeTick = _scoreboard.getTimeSinceStartOfLevel;
      if (_gameLevels[_scoreboard.getCurrentLevel - 1]
          .shouldSpawnBonus(currentTimeTick)) {
        GameBonusBuildContext? context =
            _gameLevels[_scoreboard.getCurrentLevel - 1]
                .getBonus(currentTimeTick);

        if (context != null) {
          /// build the bonus and add it to the game
          ///
          GameBonus? bonus = GameBonusFactory.create(context);
          currentLevelObjectStack.add(bonus);

          if (bonus == null) {
            return;
          }

          add(bonus);
        }
      }
    }

    if (isCurrentLevelFinished()) {
      loadNextGameLevel();
    }

    if (shouldCreatePlayer()) {
      spawnNewPlayer();
    }
  }

  @override
  void update(double dt) {
    _broker.process();
    super.update(dt);

    /// 更新視差背景
    if (children.contains(player)) {
      parallax.parallax?.baseVelocity =
          (gameRef.keyboardDirection + _joystick.relativeDelta) * 200;
    } else {
      parallax.parallax?.baseVelocity = Vector2.zero();
    }
  }

  @override
  void render(Canvas canvas) {
    TextPaint(
      style: const TextStyle(
        fontSize: 18.0,
        fontFamily: 'Awesome Font',
        color: Colors.grey,
      ),
    ).render(
      canvas,
      '(使用"方向鍵"操控)',
      Vector2(gameRef.size.x - 180, gameRef.size.y - 60),
    );
  }

  Future<void> addScoreBoard() async {
    // 取得遊戲關卡資訊
    _gameLevels = JSONUtils.extractGameLevels(jsonData);

    // 創建計分板
    _scoreboard =
        ScoreBoard(defaultNumberOfLives, defaultStartLevel, _gameLevels.length);

    // 創建本地資料庫
    final sharedPreferences = await SharedPreferences.getInstance();

    // 載入最高分數
    int? userHighScore = sharedPreferences.getInt('highScore') ?? 0;
    _scoreboard.highScore = userHighScore;

    // 添加計分板到遊戲裡
    add(_scoreboard);
  }

  void resetLevel() {
    for (final asteroid in currentLevelObjectStack) {
      remove(asteroid);
    }
    currentLevelObjectStack.clear();
    _currentGameLevelIndex = 0;
  }

  void resetScoreBoard() {
    addCommand(ResetScoreboardCommand(_scoreboard));
  }

  Future<void> addParallax() async {
    parallax = await gameRef.loadParallaxComponent(
      _parallaxImages,
      baseVelocity: Vector2(0, 0),
      velocityMultiplierDelta: Vector2(1.0, 1.5),
      repeat: ImageRepeat.repeat,
    );

    add(parallax);
  }

  void addJoystick() {
    // joystick knob and background skin styles
    final knobPaint = BasicPalette.lightBlue.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.lightBlue.withAlpha(100).paint();
    //
    // Actual Joystick component creation
    _joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: knobPaint),
      background: CircleComponent(radius: 70, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 20, bottom: 20),
    );

    ///
    /// we add the player and joystick to the controller's tree of components
    add(_joystick);
  }

  void removeJoystick() {
    remove(_joystick);
  }

  void addRestartButton() {
    restartButton = ButtonComponent(
      size: Vector2.all(100),
      button: PositionComponent(
        children: [
          TextComponent(
            text: '重新開始',
          ),
        ],
      ),
      position: Vector2(
        gameRef.size.x / 2 - 50,
        gameRef.size.y / 2 - 50,
      ),
      onPressed: () {
        restart();
      },
    );

    add(restartButton);
  }

  void removeRestartButton() {
    remove(restartButton);
  }

  void addCommand(Command command) {
    _broker.addCommand(command);
  }

  /// getters
  ///
  List<GameLevel> get getLevels {
    return _gameLevels;
  }

  Vector2 get getBaseResolution {
    return _baseResolution;
  }

  Vector2 get getResolutionMultiplier {
    return _resolutionMultiplier;
  }

  ScoreBoard get getScoreBoard {
    return _scoreboard;
  }

  /// 載入下一個遊戲關卡
  void loadNextGameLevel() {
    // reset data
    List<Asteroid> asteroids = List.empty(growable: true);

    currentLevelObjectStack.clear();

    // make sure that there are more levels left
    //
    if (_currentGameLevelIndex < _gameLevels.length) {
      // load the asteroid elements
      //
      for (var asteroid in _gameLevels[_currentGameLevelIndex].asteroidConfig) {
        // add the multiplier to the asteroid context
        asteroid.multiplier = _resolutionMultiplier;

        // create each asteroid
        Asteroid newAsteroid = AsteroidFactory.create(asteroid);
        asteroids.add(newAsteroid);

        currentLevelObjectStack.add(asteroids.last);
      }
      // add all the asteroids to the component tree so that they are part of
      // the game play
      addAll(asteroids);
      // load the game bonus elements

      // update the level counter
      _currentGameLevelIndex++;
      UpdateScoreboardLevelInfoCommand(getScoreBoard).addToController(this);
    }
  }

  void spawnNewPlayer() {
    //
    // creating the player that will be controlled by our joystick
    SpaceShipBuildContext context = SpaceShipBuildContext()
      ..spaceShipType = SpaceShipEnum.simpleSpaceShip
      ..joystick = _joystick;
    player = SpaceShipFactory.create(context);
    add(player);
  }

  /// 檢查目前關卡是否完成了
  bool isCurrentLevelFinished() {
    if (currentLevelObjectStack.isEmpty) {
      if (_levelDoneFlag == false) {
        _levelDoneFlag = true;
        _pauseCountdown = timeoutPauseInSeconds;
        return false;
      }
      if (_levelDoneFlag == true) {
        if (_pauseCountdown == 0) {
          _levelDoneFlag = false;
          return true;
        } else {
          _pauseCountdown--;
          return false;
        }
      }
      return false;
    } else {
      return false;
    }
  }

  /// check if the current level is done.
  ///
  /// We also add a'barrier' of a couple seconds to pause teh level generation
  /// so that the player has a few seconds in between levels
  ///
  bool shouldCreatePlayer() {
    if (!children.any((element) => element is SpaceShip)) {
      if (_playerDiedFlag == false) {
        _playerDiedFlag = true;
        _createPlayerCountdown = timeoutPauseInSeconds;
        return false;
      }
      if (_playerDiedFlag == true && _scoreboard.getLivesLeft > 0) {
        if (_createPlayerCountdown == 0) {
          _playerDiedFlag = false;
          return true;
        } else {
          _createPlayerCountdown--;
          return false;
        }
      }
      return false;
    } else {
      return false;
    }
  }

  void restart() {
    resetLevel();
    resetScoreBoard();
    addJoystick();
    spawnNewPlayer();
    removeRestartButton();
  }
}

class GameLevel {
  List<AsteroidBuildContext> asteroidConfig = [];
  List<GameBonusBuildContext> gameBonusConfig = [];
  final Map<int, GameBonusBuildContext> _gameBonusMap = {};

  GameLevel();

  void init() {
    for (GameBonusBuildContext bonus in gameBonusConfig) {
      _gameBonusMap[bonus.timeTriggerSeconds] = bonus;
    }
  }

  /// business methods
  ///
  bool shouldSpawnBonus(int timeTick) {
    if (_gameBonusMap[timeTick] != null) {
      return true;
    } else {
      return false;
    }
  }

  GameBonusBuildContext? getBonus(int timeTick) {
    return _gameBonusMap[timeTick];
  }

  @override

  /// We are defining our own stringify method so that we can see our
  /// values when debugging.
  ///
  String toString() {
    return 'level data: [ asteroids: $asteroidConfig ] , gameBonus: [$gameBonusConfig]';
  }
}
