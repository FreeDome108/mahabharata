import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

/// Сервис для работы с файлами комиксов
class ComicsService {
  static final ComicsService _instance = ComicsService._internal();
  factory ComicsService() => _instance;
  ComicsService._internal();

  /// Чтение файла комикса из assets
  Future<Map<String, dynamic>?> readComicsFile(String filePath) async {
    try {
      // Читаем файл как байты из assets
      final ByteData data = await rootBundle.load(filePath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Распаковываем ZIP архив
      final Archive archive = ZipDecoder().decodeBytes(bytes);
      
      // Ищем файл metadata.json или info.json
      ArchiveFile? metadataFile;
      for (final file in archive) {
        if (file.name == 'metadata.json' || file.name == 'info.json') {
          metadataFile = file;
          break;
        }
      }
      
      if (metadataFile != null) {
        final String content = String.fromCharCodes(metadataFile.content);
        return json.decode(content);
      }
      
      // Если метаданные не найдены, создаем базовую структуру
      return _createDefaultMetadata(filePath);
    } catch (e) {
      print('Ошибка чтения файла комикса $filePath: $e');
      return _createDefaultMetadata(filePath);
    }
  }

  /// Получение списка страниц из файла комикса
  Future<List<String>> getComicsPages(String filePath) async {
    try {
      // Читаем файл как байты из assets
      final ByteData data = await rootBundle.load(filePath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Распаковываем ZIP архив
      final Archive archive = ZipDecoder().decodeBytes(bytes);
      
      // Ищем изображения в архиве
      final List<String> pages = [];
      for (final file in archive) {
        if (file.isFile && _isImageFile(file.name)) {
          pages.add(file.name);
        }
      }
      
      // Сортируем страницы по имени
      pages.sort();
      
      return pages;
    } catch (e) {
      print('Ошибка получения страниц комикса: $e');
      return [];
    }
  }

  /// Получение метаданных комикса
  Future<Map<String, dynamic>?> getComicsMetadata(String filePath) async {
    try {
      final comicsData = await readComicsFile(filePath);
      if (comicsData == null) return null;

      return {
        'title': comicsData['title'] ?? 'Без названия',
        'author': comicsData['author'] ?? 'Неизвестный автор',
        'description': comicsData['description'] ?? '',
        'totalPages': (comicsData['pages'] as List?)?.length ?? 0,
        'duration': comicsData['duration'] ?? 0,
        'audioFile': comicsData['audioFile'],
      };
    } catch (e) {
      print('Ошибка получения метаданных комикса: $e');
      return null;
    }
  }

  /// Проверка существования файла комикса
  Future<bool> comicsFileExists(String filePath) async {
    try {
      await rootBundle.loadString(filePath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Получение пути к локальному файлу
  String getLocalFilePath(String fileName) {
    return 'files/$fileName';
  }

  /// Проверка, является ли файл изображением
  bool _isImageFile(String fileName) {
    final String extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  /// Создание метаданных по умолчанию
  Map<String, dynamic> _createDefaultMetadata(String filePath) {
    return {
      'title': 'Глава 1 - Книга 1',
      'author': 'Художники: Игорь Баранько, Алексей Чебыкин',
      'description': 'Первая глава Махабхараты - начало великой истории',
      'duration': 300,
      'audioFile': null,
      'pages': [],
      'metadata': {
        'version': 1,
        'created': DateTime.now().toIso8601String(),
        'language': 'ru',
        'format': 'comics'
      }
    };
  }

  /// Получение изображения страницы из архива
  Future<Uint8List?> getPageImage(String filePath, String pageName) async {
    try {
      // Читаем файл как байты из assets
      final ByteData data = await rootBundle.load(filePath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Распаковываем ZIP архив
      final Archive archive = ZipDecoder().decodeBytes(bytes);
      
      // Ищем нужную страницу
      for (final file in archive) {
        if (file.name == pageName && file.isFile) {
          return Uint8List.fromList(file.content);
        }
      }
      
      return null;
    } catch (e) {
      print('Ошибка получения изображения страницы: $e');
      return null;
    }
  }

  /// Создание тестового файла комикса для демонстрации
  Future<void> createTestComicsFile() async {
    // Этот метод можно использовать для создания тестового файла
    // если файл Ch1_Book01.comics не существует
    final testComicsData = {
      'title': 'Глава 1 - Книга 1',
      'author': 'Художники: Игорь Баранько, Алексей Чебыкин',
      'description': 'Первая глава Махабхараты - начало великой истории',
      'duration': 300, // 5 минут
      'audioFile': 'assets/sounds/ch1_audio.mp3',
      'pages': [
        'assets/images/ch1_page1.jpg',
        'assets/images/ch1_page2.jpg',
        'assets/images/ch1_page3.jpg',
        'assets/images/ch1_page4.jpg',
        'assets/images/ch1_page5.jpg',
      ],
    };

    // В реальном приложении здесь был бы код для создания файла
    // Для демонстрации просто выводим данные
    print('Тестовые данные комикса: ${json.encode(testComicsData)}');
  }
}
