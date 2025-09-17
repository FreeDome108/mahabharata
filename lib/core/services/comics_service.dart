import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Сервис для работы с файлами комиксов
class ComicsService {
  static final ComicsService _instance = ComicsService._internal();
  factory ComicsService() => _instance;
  ComicsService._internal();

  /// Чтение файла комикса из assets
  Future<Map<String, dynamic>?> readComicsFile(String filePath) async {
    try {
      // Читаем файл из assets
      final String content = await rootBundle.loadString(filePath);
      
      // Парсим JSON
      final Map<String, dynamic> data = json.decode(content);
      
      return data;
    } catch (e) {
      print('Ошибка чтения файла комикса $filePath: $e');
      return null;
    }
  }

  /// Получение списка страниц из файла комикса
  Future<List<String>> getComicsPages(String filePath) async {
    try {
      final comicsData = await readComicsFile(filePath);
      if (comicsData == null) return [];

      final List<dynamic> pages = comicsData['pages'] ?? [];
      return pages.cast<String>();
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
