import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../config/app_config.dart';
import 'anantasound_service.dart';

/// Сервис для работы с аудио и пространственным звуком
class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  
  AudioService._();
  
  late AudioSession _audioSession;
  late AudioPlayer _audioPlayer;
  final List<AudioSource> _audioSources = [];
  final Map<String, AudioPlayer> _spatialPlayers = {};
  
  // Настройки пространственного аудио
  double _listenerX = 0.0;
  double _listenerY = 0.0;
  double _listenerZ = 0.0;
  double _listenerRotation = 0.0;
  
  // Настройки купольного аудио
  bool _domeMode = false;
  double _domeRadius = AppConfig.domeRadius;
  double _domeHeight = 5.0;
  
  // AnantaSound интеграция
  final AnantaSoundService _anantaSound = AnantaSoundService.instance;
  final List<QuantumSoundField> _quantumFields = [];
  final List<InterferenceField> _interferenceFields = [];
  StreamSubscription<SystemStatistics>? _statisticsSubscription;
  StreamSubscription<List<QuantumSoundField>>? _fieldsSubscription;
  
  /// Инициализация аудио сервиса
  static Future<void> initialize() async {
    await instance._initialize();
  }
  
  Future<void> _initialize() async {
    // Настройка аудио сессии
    _audioSession = await AudioSession.instance;
    await _audioSession.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    
    // Инициализация основного плеера
    _audioPlayer = AudioPlayer();
    
    // Настройка обработчиков событий
    _audioPlayer.playerStateStream.listen(_onPlayerStateChanged);
    _audioPlayer.positionStream.listen(_onPositionChanged);
    _audioPlayer.durationStream.listen(_onDurationChanged);
    
    // Инициализация AnantaSound
    await _initializeAnantaSound();
  }
  
  /// Инициализация AnantaSound системы
  Future<void> _initializeAnantaSound() async {
    try {
      await AnantaSoundService.initialize();
      
      // Подписка на статистику
      _statisticsSubscription = _anantaSound.statisticsStream.listen(_onStatisticsUpdate);
      
      // Подписка на обновления полей
      _fieldsSubscription = _anantaSound.fieldsStream.listen(_onFieldsUpdate);
      
      debugPrint('AnantaSound интегрирован в AudioService');
    } catch (e) {
      debugPrint('Ошибка инициализации AnantaSound: $e');
    }
  }
  
  /// Воспроизведение аудио файла
  Future<void> playAudio(String url, {bool loop = false}) async {
    try {
      final audioSource = AudioSource.uri(Uri.parse(url));
      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
      
      if (loop) {
        _audioPlayer.setLoopMode(LoopMode.one);
      }
    } catch (e) {
      debugPrint('Ошибка воспроизведения аудио: $e');
    }
  }
  
  /// Воспроизведение локального аудио файла
  Future<void> playLocalAudio(String path, {bool loop = false}) async {
    try {
      final audioSource = AudioSource.uri(Uri.file(path));
      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
      
      if (loop) {
        _audioPlayer.setLoopMode(LoopMode.one);
      }
    } catch (e) {
      debugPrint('Ошибка воспроизведения локального аудио: $e');
    }
  }
  
  /// Пауза воспроизведения
  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
  }
  
  /// Остановка воспроизведения
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }
  
  /// Установка громкости
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }
  
  /// Получение текущей громкости
  double getVolume() {
    return _audioPlayer.volume;
  }
  
  /// Установка позиции воспроизведения
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }
  
  /// Получение текущей позиции
  Duration getCurrentPosition() {
    return _audioPlayer.position;
  }
  
  /// Получение длительности
  Duration? getDuration() {
    return _audioPlayer.duration;
  }
  
  /// Проверка воспроизведения
  bool get isPlaying => _audioPlayer.playing;
  
  /// Проверка паузы
  bool get isPaused => _audioPlayer.playerState.processingState == ProcessingState.ready && !_audioPlayer.playing;
  
  /// Добавление пространственного аудио источника
  Future<void> addSpatialAudioSource({
    required String id,
    required String url,
    required double x,
    required double y,
    required double z,
    double volume = 1.0,
    bool loop = false,
  }) async {
    try {
      final player = AudioPlayer();
      final audioSource = AudioSource.uri(Uri.parse(url));
      
      await player.setAudioSource(audioSource);
      await player.setVolume(volume);
      
      if (loop) {
        player.setLoopMode(LoopMode.one);
      }
      
      _spatialPlayers[id] = player;
      
      // Применяем пространственные настройки
      await _updateSpatialAudioPosition(id, x, y, z);
      
    } catch (e) {
      debugPrint('Ошибка добавления пространственного аудио: $e');
    }
  }
  
  /// Обновление позиции пространственного аудио
  Future<void> updateSpatialAudioPosition(String id, double x, double y, double z) async {
    await _updateSpatialAudioPosition(id, x, y, z);
  }
  
  Future<void> _updateSpatialAudioPosition(String id, double x, double y, double z) async {
    final player = _spatialPlayers[id];
    if (player == null) return;
    
    // Расчет расстояния до слушателя
    final distance = sqrt(pow(x - _listenerX, 2) + pow(y - _listenerY, 2) + pow(z - _listenerZ, 2));
    
    // Расчет громкости на основе расстояния (затухание)
    final maxDistance = _domeRadius * 2;
    final volume = (1.0 - (distance / maxDistance)).clamp(0.0, 1.0);
    
    // Расчет панорамы на основе угла
    final angle = atan2(y - _listenerY, x - _listenerX) - _listenerRotation;
    final pan = sin(angle).clamp(-1.0, 1.0);
    
    await player.setVolume(volume);
    // Примечание: just_audio не поддерживает панораму напрямую
    // Для полной реализации пространственного аудио нужна дополнительная библиотека
  }
  
  /// Установка позиции слушателя
  void setListenerPosition(double x, double y, double z, double rotation) {
    _listenerX = x;
    _listenerY = y;
    _listenerZ = z;
    _listenerRotation = rotation;
    
    // Обновляем все пространственные источники
    for (final entry in _spatialPlayers.entries) {
      // Здесь нужно сохранить позиции источников для обновления
      // Для упрощения пропускаем
    }
  }
  
  /// Включение купольного режима
  void enableDomeMode({double? radius, double? height}) {
    _domeMode = true;
    if (radius != null) _domeRadius = radius;
    if (height != null) _domeHeight = height;
  }
  
  /// Отключение купольного режима
  void disableDomeMode() {
    _domeMode = false;
  }
  
  /// Воспроизведение пространственного аудио
  Future<void> playSpatialAudio(String id) async {
    final player = _spatialPlayers[id];
    if (player != null) {
      await player.play();
    }
  }
  
  /// Пауза пространственного аудио
  Future<void> pauseSpatialAudio(String id) async {
    final player = _spatialPlayers[id];
    if (player != null) {
      await player.pause();
    }
  }
  
  /// Остановка пространственного аудио
  Future<void> stopSpatialAudio(String id) async {
    final player = _spatialPlayers[id];
    if (player != null) {
      await player.stop();
    }
  }
  
  /// Удаление пространственного аудио источника
  Future<void> removeSpatialAudioSource(String id) async {
    final player = _spatialPlayers.remove(id);
    if (player != null) {
      await player.dispose();
    }
  }
  
  /// Очистка всех пространственных источников
  Future<void> clearSpatialAudioSources() async {
    for (final player in _spatialPlayers.values) {
      await player.dispose();
    }
    _spatialPlayers.clear();
  }
  
  /// Обработчики событий
  void _onPlayerStateChanged(PlayerState state) {
    debugPrint('Состояние плеера: ${state.processingState}');
  }
  
  void _onPositionChanged(Duration position) {
    // Обновление UI позиции
  }
  
  void _onDurationChanged(Duration? duration) {
    // Обновление UI длительности
  }
  
  /// Создание квантового звукового поля
  QuantumSoundField createQuantumSoundField(
    double frequency,
    SphericalCoord position,
    QuantumSoundState state,
  ) {
    return _anantaSound.createQuantumSoundField(frequency, position, state);
  }

  /// Добавление интерференционного поля
  void addInterferenceField(InterferenceField field) {
    _anantaSound.addInterferenceField(field);
    _interferenceFields.add(field);
  }

  /// Обработка звукового поля через AnantaSound
  void processQuantumSoundField(QuantumSoundField field) {
    _anantaSound.processSoundField(field);
  }

  /// Получение статистики AnantaSound
  SystemStatistics getAnantaSoundStatistics() {
    return _anantaSound.getStatistics();
  }

  /// Установка квантовой неопределенности
  void setQuantumUncertainty(double uncertainty) {
    _anantaSound.setQuantumUncertainty(uncertainty);
  }

  /// Получение квантовой неопределенности
  double get quantumUncertainty => _anantaSound.quantumUncertainty;

  /// Проверка инициализации AnantaSound
  bool get isAnantaSoundInitialized => _anantaSound.isInitialized;

  /// Получение купольного резонатора
  DomeAcousticResonator? get domeResonator => _anantaSound.domeResonator;

  /// Создание пространственного аудио с квантовыми эффектами
  Future<void> addQuantumSpatialAudioSource({
    required String id,
    required String url,
    required double x,
    required double y,
    required double z,
    double volume = 1.0,
    bool loop = false,
    QuantumSoundState quantumState = QuantumSoundState.coherent,
  }) async {
    try {
      // Создание квантового поля
      final position = SphericalCoord(
        r: sqrt(x * x + y * y + z * z),
        theta: acos(z / sqrt(x * x + y * y + z * z)),
        phi: atan2(y, x),
        height: z,
      );

      final quantumField = createQuantumSoundField(
        frequency: 440.0, // Базовая частота
        position: position,
        state: quantumState,
      );

      // Обработка через AnantaSound
      processQuantumSoundField(quantumField);

      // Добавление обычного пространственного аудио
      await addSpatialAudioSource(
        id: id,
        url: url,
        x: x,
        y: y,
        z: z,
        volume: volume,
        loop: loop,
      );

      debugPrint('Квантовое пространственное аудио добавлено: $id');
    } catch (e) {
      debugPrint('Ошибка добавления квантового пространственного аудио: $e');
    }
  }

  /// Обработчики AnantaSound событий
  void _onStatisticsUpdate(SystemStatistics stats) {
    debugPrint('AnantaSound статистика: ${stats.activeFields} полей, '
        '${stats.entangledPairs} запутанных пар, '
        'когерентность: ${(stats.coherenceRatio * 100).toStringAsFixed(1)}%');
  }

  void _onFieldsUpdate(List<QuantumSoundField> fields) {
    _quantumFields.clear();
    _quantumFields.addAll(fields);
    
    // Обновление пространственных источников на основе квантовых полей
    for (final field in fields) {
      final key = 'quantum_${field.position.r}_${field.position.theta}_${field.position.phi}';
      
      // Применение квантовых эффектов к существующим источникам
      if (_spatialPlayers.containsKey(key)) {
        final player = _spatialPlayers[key]!;
        final quantumVolume = field.amplitude.magnitude;
        player.setVolume(quantumVolume.clamp(0.0, 1.0));
      }
    }
  }

  /// Освобождение ресурсов
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await clearSpatialAudioSources();
    
    // Очистка AnantaSound подписок
    await _statisticsSubscription?.cancel();
    await _fieldsSubscription?.cancel();
    await _anantaSound.dispose();
  }
  
  /// Получение информации о пространственных источниках
  Map<String, Map<String, dynamic>> getSpatialAudioInfo() {
    final info = <String, Map<String, dynamic>>{};
    
    for (final entry in _spatialPlayers.entries) {
      final player = entry.value;
      info[entry.key] = {
        'isPlaying': player.playing,
        'volume': player.volume,
        'position': player.position,
        'duration': player.duration,
      };
    }
    
    return info;
  }
  
  /// Настройки купольного аудио
  Map<String, dynamic> getDomeAudioSettings() {
    return {
      'domeMode': _domeMode,
      'domeRadius': _domeRadius,
      'domeHeight': _domeHeight,
      'listenerPosition': {
        'x': _listenerX,
        'y': _listenerY,
        'z': _listenerZ,
        'rotation': _listenerRotation,
      },
      'spatialSourcesCount': _spatialPlayers.length,
    };
  }
}
