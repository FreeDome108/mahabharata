import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_freedome_player/flutter_freedome_player.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/comics_viewer_new.dart';

/// Обновленный экран эпизода использующий FreeDome Player
class EpisodeScreenNew extends StatefulWidget {
  final String episodeId;

  const EpisodeScreenNew({
    super.key,
    required this.episodeId,
  });

  @override
  State<EpisodeScreenNew> createState() => _EpisodeScreenNewState();
}

class _EpisodeScreenNewState extends State<EpisodeScreenNew>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic>? _episode;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ContentProvider>(
        builder: (context, contentProvider, child) {
          final episode = _findEpisode(contentProvider);

          if (episode == null) {
            return _buildLoadingWidget();
          }

          return _buildEpisodePlayer(episode);
        },
      ),
    );
  }

  Map<String, dynamic>? _findEpisode(ContentProvider contentProvider) {
    // Поиск эпизода по ID в данных контент-провайдера
    try {
      final seasons = contentProvider.seasons;
      for (final season in seasons) {
        final episodes = season['episodes'] as List<dynamic>? ?? [];
        for (final episode in episodes) {
          if (episode['id'] == widget.episodeId) {
            return episode as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      debugPrint('Error finding episode: $e');
    }

    // Возвращаем тестовый эпизод если не найден
    return _getTestEpisode();
  }

  Map<String, dynamic> _getTestEpisode() {
    return {
      'id': widget.episodeId,
      'name': 'Глава 1 - Книга 1',
      'description': 'Первая глава великого эпоса Махабхарата',
      'isLocal': true,
      'file': 'files/Ch1_Book01.comics',
      'duration': 300,
      'author': 'Игорь Баранько, Алексей Чебыкин',
      'type': 'comics',
    };
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Загрузка эпизода...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodePlayer(Map<String, dynamic> episode) {
    // Проверяем, является ли эпизод локальным комиксом
    final bool isLocalComics = episode['isLocal'] == true;
    final String? comicsFile = episode['file'];
    final String? episodeType = episode['type'];

    if ((isLocalComics && comicsFile != null) || episodeType == 'comics') {
      // Показываем комикс через FreeDome Player
      return _buildComicsPlayer(
          episode, comicsFile ?? 'files/Ch1_Book01.comics');
    }

    // Показываем обычный плеер для аудио эпизодов
    return _buildAudioPlayer(episode);
  }

  Widget _buildComicsPlayer(Map<String, dynamic> episode, String comicsFile) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ComicsViewerNew(
        comicsFilePath: comicsFile,
        episodeTitle: episode['name'] ?? 'Без названия',
      ),
    );
  }

  Widget _buildAudioPlayer(Map<String, dynamic> episode) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            // Основной контент аудио плеера
            _buildAudioPlayerContent(episode),

            // Элементы управления
            if (_showControls) _buildAudioControls(episode),

            // Информация об эпизоде
            if (_showControls) _buildEpisodeInfo(episode),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayerContent(Map<String, dynamic> episode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Иконка аудио
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.8),
                  AppTheme.primaryColor.withOpacity(0.4),
                ],
              ),
            ),
            child: const Icon(
              Icons.headphones,
              size: 60,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 24),

          // Название эпизода
          Text(
            episode['name'] ?? 'Без названия',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Описание
          if (episode['description'] != null)
            Text(
              episode['description'],
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 32),

          // Уведомление о FreeDome Player
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Column(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 32),
                SizedBox(height: 8),
                Text(
                  'Аудио эпизоды скоро будут поддерживаться\nчерез FreeDome Player',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls(Map<String, dynamic> episode) {
    return Positioned(
      bottom: 40,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                // TODO: Предыдущий эпизод
              },
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              tooltip: 'Предыдущий эпизод',
            ),
            IconButton(
              onPressed: () {
                // TODO: Воспроизведение/пауза
              },
              icon: const Icon(Icons.play_circle_filled,
                  color: Colors.white, size: 48),
              tooltip: 'Воспроизвести',
            ),
            IconButton(
              onPressed: () {
                // TODO: Следующий эпизод
              },
              icon: const Icon(Icons.skip_next, color: Colors.white),
              tooltip: 'Следующий эпизод',
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              icon: const Icon(Icons.settings, color: Colors.white),
              tooltip: 'Настройки',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeInfo(Map<String, dynamic> episode) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Кнопка назад
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),

            const SizedBox(width: 16),

            // Информация об эпизоде
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode['name'] ?? 'Без названия',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (episode['author'] != null)
                    Text(
                      'Авторы: ${episode['author']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Тип контента
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(episode['type']).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getTypeIcon(episode['type']),
                    color: _getTypeColor(episode['type']),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getTypeLabel(episode['type']),
                    style: TextStyle(
                      color: _getTypeColor(episode['type']),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'comics':
        return Colors.orange;
      case 'audio':
        return Colors.blue;
      case 'video':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'comics':
        return Icons.menu_book;
      case 'audio':
        return Icons.headphones;
      case 'video':
        return Icons.video_library;
      default:
        return Icons.help_outline;
    }
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'comics':
        return 'COMICS';
      case 'audio':
        return 'AUDIO';
      case 'video':
        return 'VIDEO';
      default:
        return 'UNKNOWN';
    }
  }
}
