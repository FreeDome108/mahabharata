import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/audio_service.dart';
import '../services/dome_service.dart';
import '../services/hive_service.dart';
import '../services/comics_service.dart';
import '../services/magento_service.dart';
import '../config/app_config.dart';

/// Провайдеры приложения Mbharata Client
class AppProviders {
  static List<SingleChildWidget> get providers => [
        // Основные сервисы
        Provider<AudioService>(create: (_) => AudioService.instance),
        Provider<DomeService>(create: (_) => DomeService.instance),
        Provider<HiveService>(create: (_) => HiveService()),
        Provider<ComicsService>(create: (_) => ComicsService()),
        Provider<MagentoService>(create: (_) => MagentoService.instance),

        // Провайдеры состояния
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => DomeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CloudProvider()),
      ];
}

/// Провайдер состояния приложения
class AppStateProvider extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  String _currentLanguage = AppConfig.defaultLanguage;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentLanguage => _currentLanguage;

  /// Инициализация приложения
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      // Инициализация сервисов
      await AudioService.initialize();
      await DomeService.initialize();
      await HiveService.initialize();
      await MagentoService.instance.initialize();

      // Загрузка настроек
      await _loadSettings();

      // Инициализация CloudProvider
      // Это будет сделано через Consumer в UI

      _isInitialized = true;
    } catch (e) {
      _setError('Ошибка инициализации: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Загрузка настроек
  Future<void> _loadSettings() async {
    _currentLanguage = HiveService.getSetting('language',
            defaultValue: AppConfig.defaultLanguage) ??
        AppConfig.defaultLanguage;
  }

  /// Установка языка
  void setLanguage(String language) {
    if (AppConfig.supportedLanguages.contains(language)) {
      _currentLanguage = language;
      HiveService.saveSetting('language', language);
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Провайдер контента
class ContentProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _seasons = [];
  List<Map<String, dynamic>> _episodes = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get seasons => _seasons;
  List<Map<String, dynamic>> get episodes => _episodes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Загрузка сезонов
  Future<void> loadSeasons() async {
    _setLoading(true);
    _clearError();

    try {
      // Проверяем кэш
      if (HiveService.isSeasonsDataFresh()) {
        final cachedSeasons = HiveService.getSeasons();
        if (cachedSeasons != null) {
          _seasons = cachedSeasons;
          _setLoading(false);
          return;
        }
      }

      // Пытаемся загрузить из облака если доступно
      if (MagentoService.instance.isCloudEnabled &&
          MagentoService.instance.isConnected) {
        final cloudSeasons = await MagentoService.instance.syncSeasons();
        if (cloudSeasons != null && cloudSeasons.isNotEmpty) {
          // Объединяем облачные данные с локальными
          _seasons =
              _mergeCloudAndLocalSeasons(cloudSeasons, _getLocalSeasons());
          await HiveService.saveSeasons(_seasons);
          _setLoading(false);
          return;
        }
      }

      // Загружаем локальные данные
      _seasons = _getLocalSeasons();

      // Сохраняем в кэш
      await HiveService.saveSeasons(_seasons);
    } catch (e) {
      _setError('Ошибка загрузки сезонов: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Загрузка эпизодов сезона
  Future<void> loadEpisodes(String seasonId) async {
    _setLoading(true);
    _clearError();

    try {
      final season = _seasons.firstWhere((s) => s['id'].toString() == seasonId);
      _episodes = List<Map<String, dynamic>>.from(season['episodes'] ?? []);
    } catch (e) {
      _setError('Ошибка загрузки эпизодов: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Получение эпизода по ID
  Map<String, dynamic>? getEpisode(String episodeId) {
    try {
      return _episodes.firstWhere((e) => e['id'].toString() == episodeId);
    } catch (e) {
      return null;
    }
  }

  /// Загрузка локальных данных из папки files
  List<Map<String, dynamic>> _getLocalSeasons() {
    return [
      {
        'id': 1,
        'name': 'Проклятие Амбы\nКнига 1',
        'image': 'assets/images/season1_cover.jpg',
        'order': 1,
        'isLocal': true,
        'episodes': [
          {
            'id': 1,
            'name': 'Глава 1 - Книга 1',
            'image': 'assets/images/ch1_cover.jpg',
            'file': 'files/Ch1_Book01.comics',
            'version': 1,
            'date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'order': 1,
            'isLocal': true,
          },
        ],
      },
    ];
  }

  /// Объединение облачных и локальных сезонов
  List<Map<String, dynamic>> _mergeCloudAndLocalSeasons(
    List<Map<String, dynamic>> cloudSeasons,
    List<Map<String, dynamic>> localSeasons,
  ) {
    final mergedSeasons = <Map<String, dynamic>>[];

    // Добавляем локальные сезоны
    mergedSeasons.addAll(localSeasons);

    // Добавляем облачные сезоны, которых нет в локальных
    for (final cloudSeason in cloudSeasons) {
      final existsLocally = localSeasons.any((local) =>
          local['id'] == cloudSeason['id'] ||
          local['cloud_id'] == cloudSeason['cloud_id']);

      if (!existsLocally) {
        mergedSeasons.add({
          ...cloudSeason,
          'isLocal': false,
          'isCloud': true,
        });
      }
    }

    // Сортируем по порядку
    mergedSeasons
        .sort((a, b) => (a['order'] ?? 999).compareTo(b['order'] ?? 999));

    return mergedSeasons;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Провайдер плеера
class PlayerProvider extends ChangeNotifier {
  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  double _volume = AppConfig.audioVolume;
  String? _currentEpisodeId;

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  Duration get position => _position;
  Duration? get duration => _duration;
  double get volume => _volume;
  String? get currentEpisodeId => _currentEpisodeId;

  /// Воспроизведение эпизода
  Future<void> playEpisode(String episodeId, String audioUrl) async {
    try {
      _currentEpisodeId = episodeId;
      await AudioService.instance.playAudio(audioUrl);
      _isPlaying = true;
      _isPaused = false;
      notifyListeners();
    } catch (e) {
      // Обработка ошибки
    }
  }

  /// Пауза воспроизведения
  Future<void> pause() async {
    await AudioService.instance.pauseAudio();
    _isPaused = true;
    _isPlaying = false;
    notifyListeners();
  }

  /// Возобновление воспроизведения
  Future<void> resume() async {
    // TODO: Реализовать возобновление
    _isPaused = false;
    _isPlaying = true;
    notifyListeners();
  }

  /// Остановка воспроизведения
  Future<void> stop() async {
    await AudioService.instance.stopAudio();
    _isPlaying = false;
    _isPaused = false;
    _position = Duration.zero;
    _currentEpisodeId = null;
    notifyListeners();
  }

  /// Установка громкости
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await AudioService.instance.setVolume(_volume);
    notifyListeners();
  }

  /// Установка позиции
  Future<void> seekTo(Duration position) async {
    await AudioService.instance.seekTo(position);
    _position = position;
    notifyListeners();
  }

  /// Обновление позиции
  void updatePosition(Duration position) {
    _position = position;
    notifyListeners();
  }

  /// Обновление длительности
  void updateDuration(Duration? duration) {
    _duration = duration;
    notifyListeners();
  }
}

/// Провайдер купола
class DomeProvider extends ChangeNotifier {
  bool _domeMode = false;
  bool _interactiveMode = false;
  Map<String, double> _cameraPosition = {'x': 0.0, 'y': 0.0, 'z': 10.0};
  Map<String, double> _cameraRotation = {'x': 0.0, 'y': 0.0, 'z': 0.0};

  bool get domeMode => _domeMode;
  bool get interactiveMode => _interactiveMode;
  Map<String, double> get cameraPosition => _cameraPosition;
  Map<String, double> get cameraRotation => _cameraRotation;

  /// Включение купольного режима
  void enableDomeMode() {
    _domeMode = true;
    DomeService.instance.enableInteractiveMode();
    _interactiveMode = true;
    notifyListeners();
  }

  /// Отключение купольного режима
  void disableDomeMode() {
    _domeMode = false;
    DomeService.instance.disableInteractiveMode();
    _interactiveMode = false;
    notifyListeners();
  }

  /// Обновление позиции камеры
  void updateCameraPosition(Map<String, double> position) {
    _cameraPosition = position;
    DomeService.instance.setCameraPosition(
      position['x'] ?? 0.0,
      position['y'] ?? 0.0,
      position['z'] ?? 10.0,
    );
    notifyListeners();
  }

  /// Обновление поворота камеры
  void updateCameraRotation(Map<String, double> rotation) {
    _cameraRotation = rotation;
    DomeService.instance.setCameraRotation(
      rotation['x'] ?? 0.0,
      rotation['y'] ?? 0.0,
      rotation['z'] ?? 0.0,
    );
    notifyListeners();
  }

  /// Обработка жестов
  void handleGesture({
    required String type,
    required double deltaX,
    required double deltaY,
    double? deltaZ,
  }) {
    DomeService.instance.handleGesture(
      type: type,
      deltaX: deltaX,
      deltaY: deltaY,
      deltaZ: deltaZ,
    );
  }
}

/// Провайдер настроек
class SettingsProvider extends ChangeNotifier {
  bool _darkMode = false;
  String _language = AppConfig.defaultLanguage;
  double _audioVolume = AppConfig.audioVolume;
  bool _enableSpatialAudio = AppConfig.enableSpatialAudio;
  bool _enableHapticFeedback = AppConfig.enableHapticFeedback;

  bool get darkMode => _darkMode;
  String get language => _language;
  double get audioVolume => _audioVolume;
  bool get enableSpatialAudio => _enableSpatialAudio;
  bool get enableHapticFeedback => _enableHapticFeedback;

  /// Установка темной темы
  void setDarkMode(bool darkMode) {
    _darkMode = darkMode;
    HiveService.saveSetting('darkMode', darkMode);
    notifyListeners();
  }

  /// Установка языка
  void setLanguage(String language) {
    if (AppConfig.supportedLanguages.contains(language)) {
      _language = language;
      HiveService.saveSetting('language', language);
      notifyListeners();
    }
  }

  /// Установка громкости
  void setAudioVolume(double volume) {
    _audioVolume = volume.clamp(0.0, 1.0);
    HiveService.saveSetting('audioVolume', _audioVolume);
    notifyListeners();
  }

  /// Включение пространственного аудио
  void setEnableSpatialAudio(bool enable) {
    _enableSpatialAudio = enable;
    HiveService.saveSetting('enableSpatialAudio', enable);
    notifyListeners();
  }

  /// Включение тактильной обратной связи
  void setEnableHapticFeedback(bool enable) {
    _enableHapticFeedback = enable;
    HiveService.saveSetting('enableHapticFeedback', enable);
    notifyListeners();
  }

  /// Загрузка настроек
  Future<void> loadSettings() async {
    _darkMode =
        HiveService.getSetting('darkMode', defaultValue: false) ?? false;
    _language = HiveService.getSetting('language',
            defaultValue: AppConfig.defaultLanguage) ??
        AppConfig.defaultLanguage;
    _audioVolume = HiveService.getSetting('audioVolume',
            defaultValue: AppConfig.audioVolume) ??
        AppConfig.audioVolume;
    _enableSpatialAudio = HiveService.getSetting('enableSpatialAudio',
            defaultValue: AppConfig.enableSpatialAudio) ??
        AppConfig.enableSpatialAudio;
    _enableHapticFeedback = HiveService.getSetting('enableHapticFeedback',
            defaultValue: AppConfig.enableHapticFeedback) ??
        AppConfig.enableHapticFeedback;
    notifyListeners();
  }
}

/// Провайдер облачных функций
class CloudProvider extends ChangeNotifier {
  bool _isCloudEnabled = false;
  bool _isConnected = false;
  bool _isSyncing = false;
  String? _error;
  String? _userEmail;
  DateTime? _lastSync;

  bool get isCloudEnabled => _isCloudEnabled;
  bool get isConnected => _isConnected;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String? get userEmail => _userEmail;
  DateTime? get lastSync => _lastSync;
  bool get isAuthenticated => _userEmail != null;

  /// Инициализация облачного провайдера
  Future<void> initialize() async {
    try {
      _isCloudEnabled = MagentoService.instance.isCloudEnabled;
      _isConnected = MagentoService.instance.isConnected;
      await _loadUserInfo();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка инициализации облачных функций: $e');
    }
  }

  /// Включение облачных функций
  Future<bool> enableCloudFeatures({
    required String baseUrl,
    required String consumerKey,
    required String consumerSecret,
  }) async {
    _setSyncing(true);
    _clearError();

    try {
      final success = await MagentoService.instance.enableCloudFeatures(
        baseUrl: baseUrl,
        consumerKey: consumerKey,
        consumerSecret: consumerSecret,
      );

      if (success) {
        _isCloudEnabled = true;
        _isConnected = true;
        await _saveCloudSettings(enabled: true);
        notifyListeners();
      } else {
        _setError('Не удалось подключиться к облачному сервису');
      }

      return success;
    } catch (e) {
      _setError('Ошибка подключения к облаку: $e');
      return false;
    } finally {
      _setSyncing(false);
    }
  }

  /// Отключение облачных функций
  Future<void> disableCloudFeatures() async {
    try {
      await MagentoService.instance.disableCloudFeatures();
      _isCloudEnabled = false;
      _isConnected = false;
      _userEmail = null;
      _lastSync = null;
      await _saveCloudSettings(enabled: false);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка отключения облачных функций: $e');
    }
  }

  /// Авторизация пользователя
  Future<bool> authenticateUser({
    required String email,
    required String password,
  }) async {
    if (!_isCloudEnabled) {
      _setError('Облачные функции отключены');
      return false;
    }

    _setSyncing(true);
    _clearError();

    try {
      final success = await MagentoService.instance.authenticateUser(
        username: email,
        password: password,
      );

      if (success) {
        _userEmail = email;
        await _saveUserInfo(email);
        await _performInitialSync();
        notifyListeners();
      } else {
        _setError('Неверные учетные данные');
      }

      return success;
    } catch (e) {
      _setError('Ошибка авторизации: $e');
      return false;
    } finally {
      _setSyncing(false);
    }
  }

  /// Выход пользователя
  Future<void> logout() async {
    try {
      await MagentoService.instance.logout();
      _userEmail = null;
      _lastSync = null;
      await _clearUserInfo();
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка выхода: $e');
    }
  }

  /// Синхронизация данных
  Future<bool> syncData() async {
    if (!_isCloudEnabled || !_isConnected) {
      return false;
    }

    _setSyncing(true);
    _clearError();

    try {
      // Проверяем подключение к интернету
      final hasConnection = await MagentoService.instance.checkConnectivity();
      if (!hasConnection) {
        _setError('Нет подключения к интернету');
        return false;
      }

      // Синхронизируем сезоны
      final seasons = await MagentoService.instance.syncSeasons();
      if (seasons != null) {
        // TODO: Сохранить синхронизированные сезоны в локальное хранилище
      }

      // Синхронизируем прогресс пользователя
      if (_userEmail != null) {
        // TODO: Получить локальный прогресс и синхронизировать с облаком
      }

      _lastSync = DateTime.now();
      await _saveLastSyncTime();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Ошибка синхронизации: $e');
      return false;
    } finally {
      _setSyncing(false);
    }
  }

  /// Автоматическая синхронизация
  Future<void> autoSync() async {
    if (!_isCloudEnabled || _isSyncing) {
      return;
    }

    // Синхронизируем только если прошло более 5 минут с последней синхронизации
    if (_lastSync != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSync!);
      if (timeSinceLastSync.inMinutes < 5) {
        return;
      }
    }

    await syncData();
  }

  /// Проверка статуса подключения
  Future<void> checkConnectionStatus() async {
    if (!_isCloudEnabled) {
      return;
    }

    try {
      final hasConnection = await MagentoService.instance.checkConnectivity();
      if (_isConnected != hasConnection) {
        _isConnected = hasConnection;
        notifyListeners();
      }
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Первоначальная синхронизация после авторизации
  Future<void> _performInitialSync() async {
    try {
      await syncData();
    } catch (e) {
      // Игнорируем ошибки первоначальной синхронизации
    }
  }

  /// Загрузка информации о пользователе
  Future<void> _loadUserInfo() async {
    try {
      _userEmail = HiveService.getSetting('cloud_user_email');
      final lastSyncMillis = HiveService.getSetting<int>('cloud_last_sync');
      if (lastSyncMillis != null) {
        _lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
      }
    } catch (e) {
      // Игнорируем ошибки загрузки
    }
  }

  /// Сохранение информации о пользователе
  Future<void> _saveUserInfo(String email) async {
    try {
      HiveService.saveSetting('cloud_user_email', email);
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }

  /// Очистка информации о пользователе
  Future<void> _clearUserInfo() async {
    try {
      HiveService.removeSetting('cloud_user_email');
      HiveService.removeSetting('cloud_last_sync');
    } catch (e) {
      // Игнорируем ошибки очистки
    }
  }

  /// Сохранение настроек облачных функций
  Future<void> _saveCloudSettings({required bool enabled}) async {
    try {
      HiveService.saveSetting('cloud_enabled', enabled);
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }

  /// Сохранение времени последней синхронизации
  Future<void> _saveLastSyncTime() async {
    try {
      if (_lastSync != null) {
        HiveService.saveSetting(
            'cloud_last_sync', _lastSync!.millisecondsSinceEpoch);
      }
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }

  void _setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
