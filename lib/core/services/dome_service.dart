import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../config/app_config.dart';

/// Сервис для работы с купольным отображением FreeDome
class DomeService {
  static DomeService? _instance;
  static DomeService get instance => _instance ??= DomeService._();
  
  DomeService._();
  
  // Настройки купола
  double _domeRadius = AppConfig.domeRadius;
  double _domeHeight = 5.0;
  double _domeFov = AppConfig.domeFov;
  double _domeNear = AppConfig.domeNear;
  double _domeFar = AppConfig.domeFar;
  
  // Позиция и ориентация камеры
  double _cameraX = 0.0;
  double _cameraY = 0.0;
  double _cameraZ = 0.0;
  double _cameraRotationX = 0.0;
  double _cameraRotationY = 0.0;
  double _cameraRotationZ = 0.0;
  
  // Настройки проекции
  bool _enableFisheyeCorrection = AppConfig.enableFisheyeCorrection;
  bool _enableSphericalMapping = AppConfig.enableSphericalMapping;
  double _optimizationLevel = AppConfig.domeOptimizationLevel;
  
  // Сенсоры
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  
  // Интерактивность
  bool _interactiveMode = false;
  double _touchSensitivity = AppConfig.touchSensitivity;
  double _gestureThreshold = AppConfig.gestureThreshold;
  
  // Производительность
  bool _enableLOD = AppConfig.enableLOD;
  List<double> _lodDistances = List.from(AppConfig.lodDistances);
  bool _enableFrustumCulling = AppConfig.enableFrustumCulling;
  
  // Стримы для обновления позиции
  final StreamController<Map<String, double>> _positionController = 
      StreamController<Map<String, double>>.broadcast();
  final StreamController<Map<String, double>> _rotationController = 
      StreamController<Map<String, double>>.broadcast();
  
  /// Инициализация купольного сервиса
  static Future<void> initialize() async {
    await instance._initialize();
  }
  
  Future<void> _initialize() async {
    // Инициализация сенсоров
    await _initializeSensors();
    
    // Установка начальной позиции камеры
    _cameraZ = _domeRadius;
    
    debugPrint('DomeService инициализирован');
  }
  
  /// Инициализация сенсоров
  Future<void> _initializeSensors() async {
    // Акселерометр для определения наклона устройства
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (_interactiveMode) {
        _updateCameraFromAccelerometer(event);
      }
    });
    
    // Гироскоп для определения поворота устройства
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (_interactiveMode) {
        _updateCameraFromGyroscope(event);
      }
    });
    
    // Магнетометр для определения ориентации
    _magnetometerSubscription = magnetometerEvents.listen((MagnetometerEvent event) {
      if (_interactiveMode) {
        _updateCameraFromMagnetometer(event);
      }
    });
  }
  
  /// Обновление позиции камеры на основе акселерометра
  void _updateCameraFromAccelerometer(AccelerometerEvent event) {
    // Преобразование данных акселерометра в углы поворота
    final roll = atan2(event.y, event.z);
    final pitch = atan2(-event.x, sqrt(event.y * event.y + event.z * event.z));
    
    _cameraRotationX = pitch;
    _cameraRotationZ = roll;
    
    _notifyRotationChanged();
  }
  
  /// Обновление позиции камеры на основе гироскопа
  void _updateCameraFromGyroscope(GyroscopeEvent event) {
    // Интегрирование данных гироскопа для получения углов
    _cameraRotationX += event.x * 0.01; // Коэффициент для сглаживания
    _cameraRotationY += event.y * 0.01;
    _cameraRotationZ += event.z * 0.01;
    
    // Ограничение углов
    _cameraRotationX = _cameraRotationX.clamp(-pi / 2, pi / 2);
    _cameraRotationY = _cameraRotationY.clamp(-pi, pi);
    _cameraRotationZ = _cameraRotationZ.clamp(-pi, pi);
    
    _notifyRotationChanged();
  }
  
  /// Обновление позиции камеры на основе магнетометра
  void _updateCameraFromMagnetometer(MagnetometerEvent event) {
    // Определение азимутального угла
    final azimuth = atan2(event.y, event.x);
    _cameraRotationY = azimuth;
    
    _notifyRotationChanged();
  }
  
  /// Уведомление об изменении поворота
  void _notifyRotationChanged() {
    _rotationController.add({
      'x': _cameraRotationX,
      'y': _cameraRotationY,
      'z': _cameraRotationZ,
    });
  }
  
  /// Уведомление об изменении позиции
  void _notifyPositionChanged() {
    _positionController.add({
      'x': _cameraX,
      'y': _cameraY,
      'z': _cameraZ,
    });
  }
  
  /// Установка позиции камеры
  void setCameraPosition(double x, double y, double z) {
    _cameraX = x;
    _cameraY = y;
    _cameraZ = z;
    _notifyPositionChanged();
  }
  
  /// Установка поворота камеры
  void setCameraRotation(double x, double y, double z) {
    _cameraRotationX = x;
    _cameraRotationY = y;
    _cameraRotationZ = z;
    _notifyRotationChanged();
  }
  
  /// Получение позиции камеры
  Map<String, double> getCameraPosition() {
    return {
      'x': _cameraX,
      'y': _cameraY,
      'z': _cameraZ,
    };
  }
  
  /// Получение поворота камеры
  Map<String, double> getCameraRotation() {
    return {
      'x': _cameraRotationX,
      'y': _cameraRotationY,
      'z': _cameraRotationZ,
    };
  }
  
  /// Включение интерактивного режима
  void enableInteractiveMode() {
    _interactiveMode = true;
    debugPrint('Интерактивный режим купола включен');
  }
  
  /// Отключение интерактивного режима
  void disableInteractiveMode() {
    _interactiveMode = false;
    debugPrint('Интерактивный режим купола отключен');
  }
  
  /// Обработка жестов
  void handleGesture({
    required String type,
    required double deltaX,
    required double deltaY,
    double? deltaZ,
  }) {
    if (!_interactiveMode) return;
    
    switch (type) {
      case 'pan':
        _handlePanGesture(deltaX, deltaY);
        break;
      case 'rotate':
        _handleRotateGesture(deltaX, deltaY);
        break;
      case 'zoom':
        if (deltaZ != null) {
          _handleZoomGesture(deltaZ);
        }
        break;
      case 'tilt':
        _handleTiltGesture(deltaX, deltaY);
        break;
    }
  }
  
  /// Обработка жеста панорамирования
  void _handlePanGesture(double deltaX, double deltaY) {
    final sensitivity = _touchSensitivity * 0.01;
    
    // Преобразование 2D жеста в 3D движение
    final panX = deltaX * sensitivity;
    final panY = -deltaY * sensitivity; // Инвертируем Y для естественного движения
    
    // Обновление позиции камеры
    _cameraX += panX;
    _cameraY += panY;
    
    // Ограничение движения в пределах купола
    _cameraX = _cameraX.clamp(-_domeRadius, _domeRadius);
    _cameraY = _cameraY.clamp(-_domeHeight, _domeHeight);
    
    _notifyPositionChanged();
  }
  
  /// Обработка жеста поворота
  void _handleRotateGesture(double deltaX, double deltaY) {
    final sensitivity = _touchSensitivity * 0.005;
    
    _cameraRotationY += deltaX * sensitivity;
    _cameraRotationX += deltaY * sensitivity;
    
    // Ограничение углов
    _cameraRotationX = _cameraRotationX.clamp(-pi / 2, pi / 2);
    _cameraRotationY = _cameraRotationY.clamp(-pi, pi);
    
    _notifyRotationChanged();
  }
  
  /// Обработка жеста масштабирования
  void _handleZoomGesture(double deltaZ) {
    final sensitivity = _touchSensitivity * 0.01;
    
    // Изменение расстояния до центра купола
    _cameraZ += deltaZ * sensitivity;
    
    // Ограничение масштабирования
    _cameraZ = _cameraZ.clamp(_domeNear, _domeFar);
    
    _notifyPositionChanged();
  }
  
  /// Обработка жеста наклона
  void _handleTiltGesture(double deltaX, double deltaY) {
    final sensitivity = _touchSensitivity * 0.003;
    
    _cameraRotationZ += deltaX * sensitivity;
    
    // Ограничение угла наклона
    _cameraRotationZ = _cameraRotationZ.clamp(-pi / 4, pi / 4);
    
    _notifyRotationChanged();
  }
  
  /// Применение сферической проекции
  Map<String, double> applySphericalProjection(double x, double y, double z) {
    if (!_enableSphericalMapping) {
      return {'x': x, 'y': y, 'z': z};
    }
    
    // Преобразование в сферические координаты
    final radius = sqrt(x * x + y * y + z * z);
    final theta = atan2(y, x);
    final phi = acos(z / radius);
    
    // Применение проекции купола
    final domeX = _domeRadius * sin(phi) * cos(theta);
    final domeY = _domeRadius * sin(phi) * sin(theta);
    final domeZ = _domeRadius * cos(phi);
    
    return {'x': domeX, 'y': domeY, 'z': domeZ};
  }
  
  /// Применение коррекции fisheye
  Map<String, double> applyFisheyeCorrection(double x, double y) {
    if (!_enableFisheyeCorrection) {
      return {'x': x, 'y': y};
    }
    
    // Простая коррекция fisheye
    final distance = sqrt(x * x + y * y);
    if (distance == 0) return {'x': x, 'y': y};
    
    final correctionFactor = sin(distance) / distance;
    
    return {
      'x': x * correctionFactor,
      'y': y * correctionFactor,
    };
  }
  
  /// Расчет LOD уровня
  int calculateLODLevel(double distance) {
    if (!_enableLOD) return 0;
    
    for (int i = 0; i < _lodDistances.length; i++) {
      if (distance <= _lodDistances[i]) {
        return i;
      }
    }
    
    return _lodDistances.length - 1;
  }
  
  /// Проверка видимости объекта (frustum culling)
  bool isObjectVisible(double x, double y, double z) {
    if (!_enableFrustumCulling) return true;
    
    // Простая проверка видимости
    final distance = sqrt(
      pow(x - _cameraX, 2) + 
      pow(y - _cameraY, 2) + 
      pow(z - _cameraZ, 2)
    );
    
    return distance >= _domeNear && distance <= _domeFar;
  }
  
  /// Получение настроек купола
  Map<String, dynamic> getDomeSettings() {
    return {
      'radius': _domeRadius,
      'height': _domeHeight,
      'fov': _domeFov,
      'near': _domeNear,
      'far': _domeFar,
      'fisheyeCorrection': _enableFisheyeCorrection,
      'sphericalMapping': _enableSphericalMapping,
      'optimizationLevel': _optimizationLevel,
      'interactiveMode': _interactiveMode,
      'touchSensitivity': _touchSensitivity,
      'gestureThreshold': _gestureThreshold,
      'enableLOD': _enableLOD,
      'lodDistances': _lodDistances,
      'enableFrustumCulling': _enableFrustumCulling,
    };
  }
  
  /// Обновление настроек купола
  void updateDomeSettings(Map<String, dynamic> settings) {
    if (settings.containsKey('radius')) _domeRadius = settings['radius'];
    if (settings.containsKey('height')) _domeHeight = settings['height'];
    if (settings.containsKey('fov')) _domeFov = settings['fov'];
    if (settings.containsKey('near')) _domeNear = settings['near'];
    if (settings.containsKey('far')) _domeFar = settings['far'];
    if (settings.containsKey('fisheyeCorrection')) _enableFisheyeCorrection = settings['fisheyeCorrection'];
    if (settings.containsKey('sphericalMapping')) _enableSphericalMapping = settings['sphericalMapping'];
    if (settings.containsKey('optimizationLevel')) _optimizationLevel = settings['optimizationLevel'];
    if (settings.containsKey('touchSensitivity')) _touchSensitivity = settings['touchSensitivity'];
    if (settings.containsKey('gestureThreshold')) _gestureThreshold = settings['gestureThreshold'];
    if (settings.containsKey('enableLOD')) _enableLOD = settings['enableLOD'];
    if (settings.containsKey('lodDistances')) _lodDistances = List<double>.from(settings['lodDistances']);
    if (settings.containsKey('enableFrustumCulling')) _enableFrustumCulling = settings['enableFrustumCulling'];
  }
  
  /// Стримы для подписки на изменения
  Stream<Map<String, double>> get positionStream => _positionController.stream;
  Stream<Map<String, double>> get rotationStream => _rotationController.stream;
  
  /// Освобождение ресурсов
  Future<void> dispose() async {
    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    await _magnetometerSubscription?.cancel();
    await _positionController.close();
    await _rotationController.close();
  }
}
