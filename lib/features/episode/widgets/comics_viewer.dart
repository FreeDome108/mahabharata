import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/comics_service.dart';
import '../../../core/theme/app_theme.dart';

/// Виджет для просмотра комиксов
class ComicsViewer extends StatefulWidget {
  final String comicsFilePath;
  final String episodeTitle;

  const ComicsViewer({
    super.key,
    required this.comicsFilePath,
    required this.episodeTitle,
  });

  @override
  State<ComicsViewer> createState() => _ComicsViewerState();
}

class _ComicsViewerState extends State<ComicsViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  List<String> _pages = [];
  Map<String, dynamic>? _metadata;
  int _currentPage = 0;
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
    
    _loadComics();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadComics() async {
    try {
      final comicsService = Provider.of<ComicsService>(context, listen: false);
      
      // Загружаем метаданные
      _metadata = await comicsService.getComicsMetadata(widget.comicsFilePath);
      
      // Загружаем страницы
      _pages = await comicsService.getComicsPages(widget.comicsFilePath);
      
      if (_pages.isEmpty) {
        // Если страницы не найдены, создаем демо-страницы
        _pages = _createDemoPages();
      }
      
      setState(() {
        _isLoading = false;
      });
      
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки комикса: $e';
        _isLoading = false;
      });
    }
  }

  List<String> _createDemoPages() {
    // Создаем демо-страницы для первой главы
    return [
      'assets/images/ch1_page1.jpg',
      'assets/images/ch1_page2.jpg',
      'assets/images/ch1_page3.jpg',
      'assets/images/ch1_page4.jpg',
      'assets/images/ch1_page5.jpg',
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    return _buildComicsViewer();
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
              'Загрузка комикса...',
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

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Ошибка загрузки',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadComics,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComicsViewer() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Основной контент
            _buildPageView(),
            
            // Элементы управления
            if (_showControls) _buildControls(),
            
            // Индикатор страниц
            if (_showControls) _buildPageIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        return _buildPage(_pages[index]);
      },
    );
  }

  Widget _buildPage(String pageName) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
            maxHeight: MediaQuery.of(context).size.height,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<Uint8List?>(
              future: _getPageImage(pageName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  );
                }
                
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderPage();
                    },
                  );
                }
                
                return _buildPlaceholderPage();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Страница ${_currentPage + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.episodeTitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
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
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              
              const Spacer(),
              
              // Название эпизода
              Expanded(
                child: Text(
                  widget.episodeTitle,
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
              
              // Кнопка настроек
              IconButton(
                onPressed: _showSettings,
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Прогресс бар
              Row(
                children: [
                  Text(
                    '${_currentPage + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    ' / ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_pages.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${((_currentPage + 1) / _pages.length * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Слайдер прогресса
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _currentPage.toDouble(),
                  min: 0.0,
                  max: (_pages.length - 1).toDouble(),
                  divisions: _pages.length - 1,
                  onChanged: (value) {
                    _pageController.animateToPage(
                      value.round(),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Кнопки навигации
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Предыдущая страница
                  IconButton(
                    onPressed: _currentPage > 0 ? _previousPage : null,
                    icon: const Icon(
                      Icons.skip_previous,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  
                  // Кнопка воспроизведения аудио
                  IconButton(
                    onPressed: _playAudio,
                    icon: const Icon(
                      Icons.play_circle_outline,
                      color: AppTheme.primaryColor,
                      size: 48,
                    ),
                  ),
                  
                  // Следующая страница
                  IconButton(
                    onPressed: _currentPage < _pages.length - 1 ? _nextPage : null,
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 32,
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

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _playAudio() {
    // TODO: Реализовать воспроизведение аудио
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Воспроизведение аудио будет реализовано позже'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Настройки просмотра',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Автоматическая прокрутка'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  // TODO: Реализовать автоматическую прокрутку
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Автовоспроизведение аудио'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  // TODO: Реализовать автовоспроизведение
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fullscreen),
              title: const Text('Полноэкранный режим'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  // TODO: Реализовать полноэкранный режим
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
