import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/app_router.dart';

/// Экран воспроизведения эпизода
class EpisodeScreen extends StatefulWidget {
  final String episodeId;

  const EpisodeScreen({
    super.key,
    required this.episodeId,
  });

  @override
  State<EpisodeScreen> createState() => _EpisodeScreenState();
}

class _EpisodeScreenState extends State<EpisodeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showControls = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadEpisode();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

  void _loadEpisode() {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    // Загружаем эпизоды для поиска нужного
    contentProvider.loadSeasons();
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

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildEpisodePlayer(Map<String, dynamic> episode) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Основной контент
          _buildMainContent(episode),
          
          // Элементы управления
          if (_showControls) _buildControls(episode),
          
          // Информация об эпизоде
          if (_showControls) _buildEpisodeInfo(episode),
        ],
      ),
    );
  }

  Widget _buildMainContent(Map<String, dynamic> episode) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black87,
            Colors.black,
          ],
        ),
      ),
      child: Column(
        children: [
          // Обложка эпизода
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: episode['image'] ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Область для аудио плеера
          Expanded(
            flex: 2,
            child: _buildAudioPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Название эпизода
              Text(
                'Аудио воспроизведение',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Кнопка воспроизведения
              GestureDetector(
                onTap: () => _togglePlayback(playerProvider),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Прогресс бар
              _buildProgressBar(playerProvider),
              
              const SizedBox(height: 24),
              
              // Элементы управления
              _buildPlayerControls(playerProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(PlayerProvider playerProvider) {
    return Column(
      children: [
        // Время
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(playerProvider.position),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            Text(
              _formatDuration(playerProvider.duration),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Прогресс слайдер
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: Colors.white24,
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: playerProvider.duration != null
                ? playerProvider.position.inMilliseconds /
                    playerProvider.duration!.inMilliseconds
                : 0.0,
            onChanged: (value) {
              if (playerProvider.duration != null) {
                final position = Duration(
                  milliseconds: (value * playerProvider.duration!.inMilliseconds).round(),
                );
                playerProvider.seekTo(position);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerControls(PlayerProvider playerProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Кнопка предыдущего
        IconButton(
          onPressed: () {
            // TODO: Предыдущий эпизод
          },
          icon: const Icon(
            Icons.skip_previous,
            color: Colors.white70,
            size: 32,
          ),
        ),
        
        // Кнопка перемотки назад
        IconButton(
          onPressed: () {
            final currentPosition = playerProvider.position;
            final newPosition = currentPosition - const Duration(seconds: 10);
            playerProvider.seekTo(newPosition);
          },
          icon: const Icon(
            Icons.replay_10,
            color: Colors.white70,
            size: 28,
          ),
        ),
        
        // Кнопка воспроизведения/паузы
        GestureDetector(
          onTap: () => _togglePlayback(playerProvider),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        
        // Кнопка перемотки вперед
        IconButton(
          onPressed: () {
            final currentPosition = playerProvider.position;
            final newPosition = currentPosition + const Duration(seconds: 10);
            playerProvider.seekTo(newPosition);
          },
          icon: const Icon(
            Icons.forward_10,
            color: Colors.white70,
            size: 28,
          ),
        ),
        
        // Кнопка следующего
        IconButton(
          onPressed: () {
            // TODO: Следующий эпизод
          },
          icon: const Icon(
            Icons.skip_next,
            color: Colors.white70,
            size: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(Map<String, dynamic> episode) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Кнопка назад
              IconButton(
                onPressed: () => context.goBack(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              
              const Spacer(),
              
              // Название эпизода
              Expanded(
                child: Text(
                  episode['name'] ?? 'Без названия',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const Spacer(),
              
              // Кнопка купола
              IconButton(
                onPressed: () => context.goToDome(),
                icon: const Icon(
                  Icons.dome,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeInfo(Map<String, dynamic> episode) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Информация об эпизоде
              Text(
                episode['name'] ?? 'Без названия',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Эпизод ${episode['order'] ?? 1}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Кнопки действий
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.goToDome(),
                      icon: const Icon(Icons.dome),
                      label: const Text('Купол'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Добавить в избранное
                      },
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Избранное'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic>? _findEpisode(ContentProvider contentProvider) {
    for (final season in contentProvider.seasons) {
      final episodes = season['episodes'] as List<dynamic>? ?? [];
      for (final episode in episodes) {
        if (episode['id']?.toString() == widget.episodeId) {
          return episode;
        }
      }
    }
    return null;
  }

  void _togglePlayback(PlayerProvider playerProvider) {
    if (playerProvider.isPlaying) {
      playerProvider.pause();
    } else {
      // TODO: Воспроизвести аудио эпизода
      playerProvider.resume();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
