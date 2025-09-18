import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';

/// Сервис для работы с локальным хранилищем Hive
class HiveService {
  static const String _seasonsBox = 'seasons';
  static const String _episodesBox = 'episodes';
  static const String _settingsBox = 'settings';
  static const String _cacheBox = 'cache';
  static const String _userBox = 'user';

  /// Инициализация Hive сервиса
  static Future<void> initialize() async {
    // Регистрация адаптеров для типов данных
    // Hive.registerAdapter(SeasonAdapter());
    // Hive.registerAdapter(EpisodeAdapter());
    // Hive.registerAdapter(SettingsAdapter());

    // Открытие боксов
    await Hive.openBox(_seasonsBox);
    await Hive.openBox(_episodesBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_cacheBox);
    await Hive.openBox(_userBox);
  }

  /// Получение бокса сезонов
  static Box get seasonsBox => Hive.box(_seasonsBox);

  /// Получение бокса эпизодов
  static Box get episodesBox => Hive.box(_episodesBox);

  /// Получение бокса настроек
  static Box get settingsBox => Hive.box(_settingsBox);

  /// Получение бокса кэша
  static Box get cacheBox => Hive.box(_cacheBox);

  /// Получение бокса пользователя
  static Box get userBox => Hive.box(_userBox);

  /// Сохранение сезонов
  static Future<void> saveSeasons(List<Map<String, dynamic>> seasons) async {
    await seasonsBox.put('seasons_data', seasons);
    await seasonsBox.put('last_updated', DateTime.now().millisecondsSinceEpoch);
  }

  /// Получение сезонов
  static List<Map<String, dynamic>>? getSeasons() {
    final data = seasonsBox.get('seasons_data');
    return data != null ? List<Map<String, dynamic>>.from(data) : null;
  }

  /// Проверка актуальности данных сезонов
  static bool isSeasonsDataFresh() {
    final lastUpdated = seasonsBox.get('last_updated');
    if (lastUpdated == null) return false;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdated);
    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime);

    return difference < AppConfig.cacheExpiration;
  }

  /// Сохранение эпизода
  static Future<void> saveEpisode(
      String episodeId, Map<String, dynamic> episode) async {
    await episodesBox.put(episodeId, episode);
  }

  /// Получение эпизода
  static Map<String, dynamic>? getEpisode(String episodeId) {
    return episodesBox.get(episodeId);
  }

  /// Сохранение настроек
  static Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  /// Получение настройки
  static T? getSetting<T>(String key, {T? defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  /// Удаление настройки
  static Future<void> removeSetting(String key) async {
    await settingsBox.delete(key);
  }

  /// Сохранение в кэш
  static Future<void> saveToCache(String key, dynamic value) async {
    await cacheBox.put(key, value);
    await cacheBox.put(
        '${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// Получение из кэша
  static T? getFromCache<T>(String key) {
    final timestamp = cacheBox.get('${key}_timestamp');
    if (timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);

    if (difference > AppConfig.cacheExpiration) {
      // Удаляем устаревший кэш
      cacheBox.delete(key);
      cacheBox.delete('${key}_timestamp');
      return null;
    }

    return cacheBox.get(key) as T?;
  }

  /// Очистка кэша
  static Future<void> clearCache() async {
    await cacheBox.clear();
  }

  /// Очистка всех данных
  static Future<void> clearAll() async {
    await seasonsBox.clear();
    await episodesBox.clear();
    await settingsBox.clear();
    await cacheBox.clear();
    await userBox.clear();
  }

  /// Получение размера кэша
  static int getCacheSize() {
    return cacheBox.length;
  }

  /// Очистка устаревшего кэша
  static Future<void> cleanExpiredCache() async {
    final keys = cacheBox.keys.toList();
    final now = DateTime.now();

    for (final key in keys) {
      if (key.toString().endsWith('_timestamp')) continue;

      final timestamp = cacheBox.get('${key}_timestamp');
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final difference = now.difference(cacheTime);

        if (difference > AppConfig.cacheExpiration) {
          await cacheBox.delete(key);
          await cacheBox.delete('${key}_timestamp');
        }
      }
    }
  }

  /// Сохранение данных пользователя
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await userBox.put('user_data', userData);
  }

  /// Получение данных пользователя
  static Map<String, dynamic>? getUserData() {
    return userBox.get('user_data');
  }

  /// Сохранение токена авторизации
  static Future<void> saveAuthToken(String token) async {
    await userBox.put('auth_token', token);
  }

  /// Получение токена авторизации
  static String? getAuthToken() {
    return userBox.get('auth_token');
  }

  /// Удаление токена авторизации
  static Future<void> removeAuthToken() async {
    await userBox.delete('auth_token');
  }

  /// Проверка авторизации
  static bool isAuthenticated() {
    return getAuthToken() != null;
  }
}
