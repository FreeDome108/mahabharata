import 'package:flutter/material.dart';
import 'package:flutter_freedome_player/flutter_freedome_player.dart';

/// Обновленный виджет для просмотра комиксов через FreeDome Player
class ComicsViewerNew extends StatefulWidget {
  final String comicsFilePath;
  final String episodeTitle;

  const ComicsViewerNew({
    super.key,
    required this.comicsFilePath,
    required this.episodeTitle,
  });

  @override
  State<ComicsViewerNew> createState() => _ComicsViewerNewState();
}

class _ComicsViewerNewState extends State<ComicsViewerNew> {
  late FreeDomePlayerController _controller;
  final FreeDomePlayer _player = FreeDomePlayer();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    // Создаем контент для комикса
    final content = FreeDomePlayer.createMediaContent(
      filePath: widget.comicsFilePath,
      name: widget.episodeTitle,
      format: MediaFormat.comics,
      description: 'Mahabharata Episode Comics',
      author: 'Igor Baranko & Alexey Chebykin',
      playbackMode: PlaybackMode.screen,
    );

    // Создаем конфигурацию для комиксов
    final config = PlayerConfig.defaultComics.copyWith(
      backgroundColor: 0xFF000000,
      renderQuality: 1.0,
    );

    // Создаем контроллер
    _controller = _player.createController(config);
    _controller.loadMediaContent(content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // FreeDome Player для комиксов
          FreeDomePlayerWidget(
            content: _controller.currentContent,
            config: _controller.config,
            showControls: true,
            autoPlay: false,
            onContentLoaded: () {
              debugPrint(
                  '🟢 [COMICS_VIEWER_NEW] Comics loaded: ${widget.episodeTitle}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Комикс "${widget.episodeTitle}" загружен успешно!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            onError: (error) {
              debugPrint('🔴 [COMICS_VIEWER_NEW] Error: $error');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ошибка загрузки комикса: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            onPlaybackStarted: () {
              debugPrint('🟢 [COMICS_VIEWER_NEW] Playback started');
            },
            onPlaybackStopped: () {
              debugPrint('🔴 [COMICS_VIEWER_NEW] Playback stopped');
            },
          ),

          // Кнопка "Назад"
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Назад к эпизодам',
              ),
            ),
          ),

          // Информация об эпизоде
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Comics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Дополнительные элементы управления
          Positioned(
            top: 100,
            right: 16,
            child: Column(
              children: [
                // Кнопка информации
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: _showEpisodeInfo,
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    tooltip: 'Информация об эпизоде',
                  ),
                ),

                const SizedBox(height: 8),

                // Кнопка настроек
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: _showSettings,
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'Настройки просмотра',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEpisodeInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.menu_book, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.episodeTitle,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Формат', 'Comics (.comics)'),
            _buildInfoRow('Авторы', 'Игорь Баранько, Алексей Чебыкин'),
            _buildInfoRow('Серия', 'Махабхарата'),
            _buildInfoRow('Плеер', 'FreeDome Player'),
            if (_controller.currentContent?.metadata != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Дополнительная информация:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (_controller.currentContent!.metadata!['totalPages'] != null)
                _buildInfoRow(
                  'Страниц',
                  '${_controller.currentContent!.metadata!['totalPages']}',
                ),
              if (_controller.currentContent!.metadata!['duration'] != null)
                _buildInfoRow(
                  'Длительность',
                  '${_controller.currentContent!.metadata!['duration']} сек',
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Настройки просмотра',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Качество рендеринга
            ListTile(
              leading: const Icon(Icons.high_quality, color: Colors.blue),
              title: const Text('Качество рендеринга',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Текущее: ${(_controller.config.renderQuality * 100).round()}%',
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () => _showQualitySelector(),
            ),

            // Фон
            ListTile(
              leading: const Icon(Icons.color_lens, color: Colors.purple),
              title: const Text('Цвет фона',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Изменить цвет фона',
                  style: TextStyle(color: Colors.white70)),
              onTap: () => _showBackgroundSelector(),
            ),

            // Информация о плеере
            ListTile(
              leading: const Icon(Icons.info, color: Colors.green),
              title: const Text('О FreeDome Player',
                  style: TextStyle(color: Colors.white)),
              onTap: () => _showPlayerInfo(),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showQualitySelector() {
    Navigator.pop(context); // Закрываем настройки

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Качество рендеринга',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQualityOption('Низкое (50%)', 0.5),
            _buildQualityOption('Среднее (75%)', 0.75),
            _buildQualityOption('Высокое (100%)', 1.0),
            _buildQualityOption('Максимальное (150%)', 1.5),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityOption(String label, double quality) {
    final isSelected = _controller.config.renderQuality == quality;

    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? Colors.blue : Colors.white70,
      ),
      onTap: () {
        final newConfig = _controller.config.copyWith(renderQuality: quality);
        _controller.updateConfig(newConfig);
        Navigator.of(context).pop();
      },
    );
  }

  void _showBackgroundSelector() {
    Navigator.pop(context); // Закрываем настройки

    final colors = [
      {'name': 'Черный', 'color': 0xFF000000},
      {'name': 'Темно-серый', 'color': 0xFF2A2A2A},
      {'name': 'Темно-синий', 'color': 0xFF1A1A2E},
      {'name': 'Темно-фиолетовый', 'color': 0xFF2D1B69},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Цвет фона', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: colors.map((colorData) {
            final isSelected =
                _controller.config.backgroundColor == colorData['color'];

            return ListTile(
              title: Text(
                colorData['name'] as String,
                style: const TextStyle(color: Colors.white),
              ),
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(colorData['color'] as int),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.white30,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              onTap: () {
                final newConfig = _controller.config.copyWith(
                  backgroundColor: colorData['color'] as int,
                );
                _controller.updateConfig(newConfig);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showPlayerInfo() {
    Navigator.pop(context); // Закрываем настройки

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.play_circle_filled, color: Colors.blue),
            SizedBox(width: 8),
            Text('FreeDome Player', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FreeDome Player - это универсальный плеер для воспроизведения различных медиа форматов, включая комиксы, 3D модели и купольные проекции.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 12),
            Text(
              'Поддерживаемые форматы:',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text('• Comics (.comics)', style: TextStyle(color: Colors.white70)),
            Text('• Boranko (.boranko)',
                style: TextStyle(color: Colors.white70)),
            Text('• COLLADA (.dae)', style: TextStyle(color: Colors.white70)),
            Text('• OBJ (.obj)', style: TextStyle(color: Colors.white70)),
            Text('• glTF (.gltf, .glb)',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
