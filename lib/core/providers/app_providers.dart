import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_service.dart';
import '../services/dome_service.dart';
import '../services/hive_service.dart';
import '../config/app_config.dart';

/// Провайдеры приложения Mbharata Client
class AppProviders {
  static List<Provider> get providers => [
    // Основные сервисы
    Provider<AudioService>(create: (_) => AudioService.instance),
    Provider<DomeService>(create: (_) => DomeService.instance),
    Provider<HiveService>(create: (_) => HiveService()),
    
    // Провайдеры состояния
    ChangeNotifierProvider(create: (_) => AppStateProvider()),
    ChangeNotifierProvider(create: (_) => ContentProvider()),
    ChangeNotifierProvider(create: (_) => PlayerProvider()),
    ChangeNotifierProvider(create: (_) => DomeProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
      
      // Загрузка настроек
      await _loadSettings();
      
      _isInitialized = true;
    } catch (e) {
      _setError('Ошибка инициализации: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Загрузка настроек
  Future<void> _loadSettings() async {
    _currentLanguage = HiveService.getSetting('language', defaultValue: AppConfig.defaultLanguage) ?? AppConfig.defaultLanguage;
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
      
      // Загружаем с сервера
      // TODO: Реализовать загрузку с API
      _seasons = _getMockSeasons();
      
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
  
  /// Mock данные для тестирования
  List<Map<String, dynamic>> _getMockSeasons() {
    return [
      {
        'id': 1,
        'name': 'Проклятие Амбы\nКнига 1',
        'image': '/Images/a2e12519393f4938aa6a4518f104a827.jpg',
        'order': 1,
        'episodes': [
          {
            'id': 1,
            'name': 'Тлен',
            'image': '/Images/b732c30bc25b4271afc8aa23a614b112*.jpg',
            'file': '/Files/d00c610a6f4647dcbd8116014674d255.comics',
            'version': 9,
            'date': 1547251200,
            'order': 1,
          },
          {
            'id': 2,
            'name': 'Обряд сваямвара',
            'image': '/Images/dc882acefd174cbabe1df9204a558497*.jpg',
            'file': '/Files/d94d8557c94e41ebb760347f2ad9d2f1.comics',
            'version': 9,
            'date': 1549929600,
            'order': 2,
          },
        ],
      },
    ];
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
    _darkMode = HiveService.getSetting('darkMode', defaultValue: false) ?? false;
    _language = HiveService.getSetting('language', defaultValue: AppConfig.defaultLanguage) ?? AppConfig.defaultLanguage;
    _audioVolume = HiveService.getSetting('audioVolume', defaultValue: AppConfig.audioVolume) ?? AppConfig.audioVolume;
    _enableSpatialAudio = HiveService.getSetting('enableSpatialAudio', defaultValue: AppConfig.enableSpatialAudio) ?? AppConfig.enableSpatialAudio;
    _enableHapticFeedback = HiveService.getSetting('enableHapticFeedback', defaultValue: AppConfig.enableHapticFeedback) ?? AppConfig.enableHapticFeedback;
    notifyListeners();
  }
}
