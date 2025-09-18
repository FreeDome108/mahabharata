import 'package:flutter/foundation.dart';
import 'package:flutter_magento/flutter_magento.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для работы с Magento API
/// Обеспечивает облачную синхронизацию контента и пользовательских данных
class MagentoService {
  static MagentoService? _instance;
  static MagentoService get instance => _instance ??= MagentoService._();

  MagentoService._();

  FlutterMagento? _magento;
  bool _isInitialized = false;
  bool _isCloudEnabled = false;
  String? _baseUrl;
  String? _accessToken;
  String? _refreshToken;

  /// Геттеры
  bool get isInitialized => _isInitialized;
  bool get isCloudEnabled => _isCloudEnabled;
  bool get isConnected => _client != null && _isCloudEnabled;

  /// Инициализация сервиса
  Future<void> initialize({
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Загружаем настройки облачных функций
      _isCloudEnabled = prefs.getBool('cloud_enabled') ?? false;
      _baseUrl = baseUrl ?? prefs.getString('magento_base_url');
      _accessToken = prefs.getString('magento_access_token');
      _refreshToken = prefs.getString('magento_refresh_token');

      if (_isCloudEnabled && _baseUrl != null) {
        await _initializeMagentoClient(
          baseUrl: _baseUrl!,
          consumerKey:
              consumerKey ?? prefs.getString('magento_consumer_key') ?? '',
          consumerSecret: consumerSecret ??
              prefs.getString('magento_consumer_secret') ??
              '',
        );
      }

      _isInitialized = true;
      debugPrint(
          'MagentoService инициализирован. Облачные функции: $_isCloudEnabled');
    } catch (e) {
      debugPrint('Ошибка инициализации MagentoService: $e');
      _isInitialized = true; // Продолжаем работу без облачных функций
    }
  }

  /// Инициализация Magento клиента
  Future<void> _initializeMagentoClient({
    required String baseUrl,
    required String consumerKey,
    required String consumerSecret,
  }) async {
    try {
      _client = MagentoClient(
        baseUrl: baseUrl,
        consumerKey: consumerKey,
        consumerSecret: consumerSecret,
      );

      // Если есть сохраненный токен, используем его
      if (_accessToken != null) {
        _client!.setAccessToken(_accessToken!);
      }

      debugPrint('Magento клиент инициализирован');
    } catch (e) {
      debugPrint('Ошибка инициализации Magento клиента: $e');
      _client = null;
      rethrow;
    }
  }

  /// Включение облачных функций
  Future<bool> enableCloudFeatures({
    required String baseUrl,
    required String consumerKey,
    required String consumerSecret,
  }) async {
    try {
      // Проверяем подключение к интернету
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('Нет подключения к интернету');
      }

      // Инициализируем клиент
      await _initializeMagentoClient(
        baseUrl: baseUrl,
        consumerKey: consumerKey,
        consumerSecret: consumerSecret,
      );

      // Проверяем подключение
      await _testConnection();

      // Сохраняем настройки
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cloud_enabled', true);
      await prefs.setString('magento_base_url', baseUrl);
      await prefs.setString('magento_consumer_key', consumerKey);
      await prefs.setString('magento_consumer_secret', consumerSecret);

      _isCloudEnabled = true;
      _baseUrl = baseUrl;

      debugPrint('Облачные функции включены');
      return true;
    } catch (e) {
      debugPrint('Ошибка включения облачных функций: $e');
      return false;
    }
  }

  /// Отключение облачных функций
  Future<void> disableCloudFeatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cloud_enabled', false);

      _isCloudEnabled = false;
      _client = null;
      _accessToken = null;
      _refreshToken = null;

      debugPrint('Облачные функции отключены');
    } catch (e) {
      debugPrint('Ошибка отключения облачных функций: $e');
    }
  }

  /// Проверка подключения к Magento
  Future<void> _testConnection() async {
    if (_client == null) {
      throw Exception('Magento клиент не инициализирован');
    }

    try {
      // Тестируем подключение через получение информации о магазине
      await _client!.get('/rest/V1/store/storeConfigs');
      debugPrint('Подключение к Magento успешно');
    } catch (e) {
      debugPrint('Ошибка подключения к Magento: $e');
      rethrow;
    }
  }

  /// Авторизация пользователя
  Future<bool> authenticateUser({
    required String username,
    required String password,
  }) async {
    if (!_isCloudEnabled || _client == null) {
      return false;
    }

    try {
      final response =
          await _client!.post('/rest/V1/integration/customer/token', {
        'username': username,
        'password': password,
      });

      if (response.data != null) {
        _accessToken = response.data.toString();
        _client!.setAccessToken(_accessToken!);

        // Сохраняем токен
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('magento_access_token', _accessToken!);

        debugPrint('Пользователь авторизован');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Ошибка авторизации: $e');
      return false;
    }
  }

  /// Выход пользователя
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('magento_access_token');
      await prefs.remove('magento_refresh_token');

      _accessToken = null;
      _refreshToken = null;

      if (_client != null) {
        _client!.clearAccessToken();
      }

      debugPrint('Пользователь вышел из системы');
    } catch (e) {
      debugPrint('Ошибка выхода: $e');
    }
  }

  /// Синхронизация сезонов с облаком
  Future<List<Map<String, dynamic>>?> syncSeasons() async {
    if (!_isCloudEnabled || _client == null) {
      return null;
    }

    try {
      final response = await _client!.get('/rest/V1/products', {
        'searchCriteria[filterGroups][0][filters][0][field]': 'type_id',
        'searchCriteria[filterGroups][0][filters][0][value]':
            'mahabharata_season',
        'searchCriteria[filterGroups][0][filters][0][conditionType]': 'eq',
      });

      if (response.data != null && response.data['items'] != null) {
        final seasons = <Map<String, dynamic>>[];

        for (final item in response.data['items']) {
          seasons.add({
            'id': item['id'],
            'name': item['name'],
            'image': _getProductImage(item),
            'order': _getCustomAttribute(item, 'order') ?? 999,
            'cloud_id': item['id'],
            'last_sync': DateTime.now().millisecondsSinceEpoch,
          });
        }

        debugPrint('Синхронизировано ${seasons.length} сезонов');
        return seasons;
      }

      return [];
    } catch (e) {
      debugPrint('Ошибка синхронизации сезонов: $e');
      return null;
    }
  }

  /// Синхронизация эпизодов сезона с облаком
  Future<List<Map<String, dynamic>>?> syncEpisodes(String seasonId) async {
    if (!_isCloudEnabled || _client == null) {
      return null;
    }

    try {
      final response = await _client!.get('/rest/V1/products', {
        'searchCriteria[filterGroups][0][filters][0][field]': 'type_id',
        'searchCriteria[filterGroups][0][filters][0][value]':
            'mahabharata_episode',
        'searchCriteria[filterGroups][0][filters][0][conditionType]': 'eq',
        'searchCriteria[filterGroups][1][filters][0][field]': 'season_id',
        'searchCriteria[filterGroups][1][filters][0][value]': seasonId,
        'searchCriteria[filterGroups][1][filters][0][conditionType]': 'eq',
      });

      if (response.data != null && response.data['items'] != null) {
        final episodes = <Map<String, dynamic>>[];

        for (final item in response.data['items']) {
          episodes.add({
            'id': item['id'],
            'name': item['name'],
            'image': _getProductImage(item),
            'file': _getCustomAttribute(item, 'episode_file'),
            'audio_url': _getCustomAttribute(item, 'audio_url'),
            'version': _getCustomAttribute(item, 'version') ?? 1,
            'order': _getCustomAttribute(item, 'order') ?? 999,
            'cloud_id': item['id'],
            'season_id': seasonId,
            'last_sync': DateTime.now().millisecondsSinceEpoch,
          });
        }

        debugPrint(
            'Синхронизировано ${episodes.length} эпизодов для сезона $seasonId');
        return episodes;
      }

      return [];
    } catch (e) {
      debugPrint('Ошибка синхронизации эпизодов: $e');
      return null;
    }
  }

  /// Синхронизация прогресса пользователя
  Future<bool> syncUserProgress(Map<String, dynamic> progressData) async {
    if (!_isCloudEnabled || _client == null || _accessToken == null) {
      return false;
    }

    try {
      await _client!.post('/rest/V1/mahabharata/progress', progressData);
      debugPrint('Прогресс пользователя синхронизирован');
      return true;
    } catch (e) {
      debugPrint('Ошибка синхронизации прогресса: $e');
      return false;
    }
  }

  /// Получение прогресса пользователя из облака
  Future<Map<String, dynamic>?> getUserProgress() async {
    if (!_isCloudEnabled || _client == null || _accessToken == null) {
      return null;
    }

    try {
      final response = await _client!.get('/rest/V1/mahabharata/progress');

      if (response.data != null) {
        debugPrint('Прогресс пользователя получен из облака');
        return Map<String, dynamic>.from(response.data);
      }

      return null;
    } catch (e) {
      debugPrint('Ошибка получения прогресса: $e');
      return null;
    }
  }

  /// Загрузка файла эпизода
  Future<String?> downloadEpisodeFile(String cloudId, String localPath) async {
    if (!_isCloudEnabled || _client == null) {
      return null;
    }

    try {
      final response =
          await _client!.get('/rest/V1/mahabharata/episode/$cloudId/download');

      if (response.data != null && response.data['download_url'] != null) {
        // TODO: Реализовать загрузку файла по URL
        debugPrint(
            'URL для загрузки эпизода: ${response.data['download_url']}');
        return response.data['download_url'];
      }

      return null;
    } catch (e) {
      debugPrint('Ошибка получения ссылки для загрузки: $e');
      return null;
    }
  }

  /// Проверка статуса подключения к интернету
  Future<bool> checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Получение изображения продукта
  String? _getProductImage(Map<String, dynamic> product) {
    try {
      if (product['media_gallery_entries'] != null &&
          (product['media_gallery_entries'] as List).isNotEmpty) {
        final mediaEntry = (product['media_gallery_entries'] as List).first;
        return mediaEntry['file'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получение кастомного атрибута продукта
  dynamic _getCustomAttribute(
      Map<String, dynamic> product, String attributeCode) {
    try {
      if (product['custom_attributes'] != null) {
        for (final attr in product['custom_attributes']) {
          if (attr['attribute_code'] == attributeCode) {
            return attr['value'];
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
