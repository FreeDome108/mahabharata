/// Конфигурация приложения Mbharata Client
class AppConfig {
  // Версия приложения
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  
  // API конфигурация
  static const String baseUrl = 'https://app.mbharata.com';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Купольные настройки
  static const double domeRadius = 10.0;
  static const double domeFov = 75.0;
  static const double domeNear = 0.1;
  static const double domeFar = 1000.0;
  
  // Настройки рендеринга
  static const int maxFps = 60;
  static const int targetFps = 30;
  static const bool enableVSync = true;
  static const bool enableAntiAliasing = true;
  
  // Настройки аудио
  static const double audioVolume = 0.8;
  static const int audioSampleRate = 44100;
  static const int audioChannels = 2;
  static const bool enableSpatialAudio = true;
  
  // Настройки кэширования
  static const Duration cacheExpiration = Duration(days: 7);
  static const int maxCacheSize = 500 * 1024 * 1024; // 500MB
  static const int maxImageCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Настройки сети
  static const Duration networkTimeout = Duration(seconds: 15);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Настройки UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 3);
  static const double borderRadius = 12.0;
  static const double elevation = 4.0;
  
  // Настройки интерактивности
  static const double touchSensitivity = 1.0;
  static const double gestureThreshold = 10.0;
  static const bool enableHapticFeedback = true;
  
  // Настройки купольного отображения
  static const bool enableDomeProjection = true;
  static const bool enableFisheyeCorrection = true;
  static const bool enableSphericalMapping = true;
  static const double domeOptimizationLevel = 0.8;
  
  // Настройки производительности
  static const bool enableLOD = true;
  static const int lodLevels = 3;
  static const List<double> lodDistances = [10.0, 50.0, 100.0];
  static const bool enableFrustumCulling = true;
  static const bool enableOcclusionCulling = false;
  
  // Настройки отладки
  static const bool enableDebugMode = false;
  static const bool enablePerformanceOverlay = false;
  static const bool enableRenderDebug = false;
  
  // Поддерживаемые форматы
  static const List<String> supportedImageFormats = [
    'jpg', 'jpeg', 'png', 'webp', 'gif'
  ];
  
  static const List<String> supportedVideoFormats = [
    'mp4', 'mov', 'avi', 'webm'
  ];
  
  static const List<String> supportedAudioFormats = [
    'mp3', 'wav', 'ogg', 'aac', 'm4a'
  ];
  
  static const List<String> supported3DFormats = [
    'gltf', 'glb', 'obj', 'fbx', 'dae'
  ];
  
  // Языки приложения
  static const List<String> supportedLanguages = [
    'en', 'ru', 'hi', 'th'
  ];
  
  static const String defaultLanguage = 'en';
  
  // Настройки безопасности
  static const bool enableCertificatePinning = true;
  static const bool enableDataEncryption = true;
  static const Duration sessionTimeout = Duration(hours: 24);
  
  // Настройки аналитики
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = true;
  
  /// Получить полный URL API
  static String getApiUrl(String endpoint) {
    return '$baseUrl/api/$apiVersion/$endpoint';
  }
  
  /// Получить URL для статических файлов
  static String getStaticUrl(String path) {
    return '$baseUrl/static$path';
  }
  
  /// Получить URL для медиа файлов
  static String getMediaUrl(String path) {
    return '$baseUrl/media$path';
  }
  
  /// Проверить, поддерживается ли формат файла
  static bool isSupportedFormat(String filename, List<String> supportedFormats) {
    final extension = filename.split('.').last.toLowerCase();
    return supportedFormats.contains(extension);
  }
  
  /// Получить настройки купола
  static Map<String, dynamic> getDomeSettings() {
    return {
      'radius': domeRadius,
      'fov': domeFov,
      'near': domeNear,
      'far': domeFar,
      'projectionType': 'spherical',
      'fisheyeCorrection': enableFisheyeCorrection,
      'sphericalMapping': enableSphericalMapping,
      'optimizationLevel': domeOptimizationLevel,
    };
  }
  
  /// Получить настройки производительности
  static Map<String, dynamic> getPerformanceSettings() {
    return {
      'maxFps': maxFps,
      'targetFps': targetFps,
      'enableVSync': enableVSync,
      'enableAntiAliasing': enableAntiAliasing,
      'enableLOD': enableLOD,
      'lodLevels': lodLevels,
      'lodDistances': lodDistances,
      'enableFrustumCulling': enableFrustumCulling,
      'enableOcclusionCulling': enableOcclusionCulling,
    };
  }
}
