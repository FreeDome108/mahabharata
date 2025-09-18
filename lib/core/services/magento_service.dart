import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

/// Сервис для работы с Magento API
/// Обеспечивает облачную синхронизацию контента и пользовательских данных
class MagentoService {
  static MagentoService? _instance;
  static MagentoService get instance => _instance ??= MagentoService._();
  
  MagentoService._();
  
  Dio? _dio;
  bool _isInitialized = false;
  bool _isCloudEnabled = false;
  String? _baseUrl;
  String? _accessToken;
  
  /// Геттеры
  bool get isInitialized => _isInitialized;
  bool get isCloudEnabled => _isCloudEnabled;
  bool get isConnected => _dio != null && _isCloudEnabled;
  
  /// Инициализация сервиса
  Future<void> initialize({
    String? baseUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Загружаем настройки облачных функций
      _isCloudEnabled = prefs.getBool('cloud_enabled') ?? false;
      _baseUrl = baseUrl ?? prefs.getString('magento_base_url');
      _accessToken = prefs.getString('magento_access_token');
      
      if (_isCloudEnabled && _baseUrl != null) {
        await _initializeDio(baseUrl: _baseUrl!);
      }
      
      _isInitialized = true;
      debugPrint('MagentoService инициализирован. Облачные функции: $_isCloudEnabled');
    } catch (e) {
      debugPrint('Ошибка инициализации MagentoService: $e');
      _isInitialized = true; // Продолжаем работу без облачных функций
    }
  }
  
  /// Инициализация Dio клиента
  Future<void> _initializeDio({required String baseUrl}) async {
    try {
      _dio = Dio();
      _dio!.options.baseUrl = baseUrl;
      _dio!.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (_accessToken != null) {
        _dio!.options.headers['Authorization'] = 'Bearer $_accessToken';
      }
      
      debugPrint('Dio клиент инициализирован');
    } catch (e) {
      debugPrint('Ошибка инициализации Dio клиента: $e');
      _dio = null;
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
      
      // Инициализируем Dio
      await _initializeDio(baseUrl: baseUrl);
      
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
      _dio = null;
      _accessToken = null;
      
      debugPrint('Облачные функции отключены');
    } catch (e) {
      debugPrint('Ошибка отключения облачных функций: $e');
    }
  }
  
  /// Проверка подключения к Magento
  Future<void> _testConnection() async {
    if (_dio == null) {
      throw Exception('Dio клиент не инициализирован');
    }
    
    try {
      // Тестируем подключение через простой запрос к API
      final response = await _dio!.get('/rest/V1/store/storeConfigs');
      if (response.statusCode == 200) {
        debugPrint('Подключение к Magento успешно');
      } else {
        throw Exception('Ошибка подключения: ${response.statusCode}');
      }
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
    if (!_isCloudEnabled || _dio == null) {
      return false;
    }
    
    try {
      final response = await _dio!.post('/rest/V1/integration/customer/token', data: {
        'username': username,
        'password': password,
      });
      
      if (response.statusCode == 200 && response.data != null) {
        _accessToken = response.data.toString().replaceAll('"', '');
        _dio!.options.headers['Authorization'] = 'Bearer $_accessToken';
        
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
      
      _accessToken = null;
      
      if (_dio != null) {
        _dio!.options.headers.remove('Authorization');
      }
      
      debugPrint('Пользователь вышел из системы');
    } catch (e) {
      debugPrint('Ошибка выхода: $e');
    }
  }
  
  /// Синхронизация сезонов с облаком
  Future<List<Map<String, dynamic>>?> syncSeasons() async {
    if (!_isCloudEnabled || _dio == null) {
      return null;
    }
    
    try {
      // Получаем продукты с типом "mahabharata_season"
      final response = await _dio!.get('/rest/V1/products', queryParameters: {
        'searchCriteria[filterGroups][0][filters][0][field]': 'type_id',
        'searchCriteria[filterGroups][0][filters][0][value]': 'mahabharata_season',
        'searchCriteria[filterGroups][0][filters][0][conditionType]': 'eq',
      });
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final items = data['items'] as List<dynamic>? ?? [];
        
        final seasons = <Map<String, dynamic>>[];
        
        for (final item in items) {
          final Map<String, dynamic> itemMap = item as Map<String, dynamic>;
          seasons.add({
            'id': itemMap['id'],
            'name': itemMap['name'] ?? 'Без названия',
            'image': _getProductImage(itemMap),
            'order': _getCustomAttribute(itemMap, 'order') ?? 999,
            'cloud_id': itemMap['id'],
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
    if (!_isCloudEnabled || _dio == null) {
      return null;
    }
    
    try {
      final response = await _dio!.get('/rest/V1/products', queryParameters: {
        'searchCriteria[filterGroups][0][filters][0][field]': 'type_id',
        'searchCriteria[filterGroups][0][filters][0][value]': 'mahabharata_episode',
        'searchCriteria[filterGroups][0][filters][0][conditionType]': 'eq',
        'searchCriteria[filterGroups][1][filters][0][field]': 'season_id',
        'searchCriteria[filterGroups][1][filters][0][value]': seasonId,
        'searchCriteria[filterGroups][1][filters][0][conditionType]': 'eq',
      });
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final items = data['items'] as List<dynamic>? ?? [];
        
        final episodes = <Map<String, dynamic>>[];
        
        for (final item in items) {
          final Map<String, dynamic> itemMap = item as Map<String, dynamic>;
          episodes.add({
            'id': itemMap['id'],
            'name': itemMap['name'] ?? 'Без названия',
            'image': _getProductImage(itemMap),
            'file': _getCustomAttribute(itemMap, 'episode_file'),
            'audio_url': _getCustomAttribute(itemMap, 'audio_url'),
            'version': _getCustomAttribute(itemMap, 'version') ?? 1,
            'order': _getCustomAttribute(itemMap, 'order') ?? 999,
            'cloud_id': itemMap['id'],
            'season_id': seasonId,
            'last_sync': DateTime.now().millisecondsSinceEpoch,
          });
        }
        
        debugPrint('Синхронизировано ${episodes.length} эпизодов для сезона $seasonId');
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
    if (!_isCloudEnabled || _dio == null || _accessToken == null) {
      return false;
    }
    
    try {
      final response = await _dio!.post('/rest/V1/mahabharata/progress', data: progressData);
      if (response.statusCode == 200) {
        debugPrint('Прогресс пользователя синхронизирован');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Ошибка синхронизации прогресса: $e');
      return false;
    }
  }
  
  /// Получение прогресса пользователя из облака
  Future<Map<String, dynamic>?> getUserProgress() async {
    if (!_isCloudEnabled || _dio == null || _accessToken == null) {
      return null;
    }
    
    try {
      final response = await _dio!.get('/rest/V1/mahabharata/progress');
      
      if (response.statusCode == 200 && response.data != null) {
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
    if (!_isCloudEnabled || _dio == null) {
      return null;
    }
    
    try {
      final response = await _dio!.get('/rest/V1/mahabharata/episode/$cloudId/download');
      
      if (response.statusCode == 200 && 
          response.data != null && 
          response.data['download_url'] != null) {
        debugPrint('URL для загрузки эпизода: ${response.data['download_url']}');
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
      final mediaGallery = product['media_gallery_entries'] as List<dynamic>?;
      if (mediaGallery != null && mediaGallery.isNotEmpty) {
        final mediaEntry = mediaGallery.first as Map<String, dynamic>;
        return mediaEntry['file'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Получение кастомного атрибута продукта
  dynamic _getCustomAttribute(Map<String, dynamic> product, String attributeCode) {
    try {
      final customAttributes = product['custom_attributes'] as List<dynamic>?;
      if (customAttributes != null) {
        for (final attr in customAttributes) {
          final attrMap = attr as Map<String, dynamic>;
          if (attrMap['attribute_code'] == attributeCode) {
            return attrMap['value'];
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}