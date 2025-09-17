import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/app_config.dart';

/// Экран загрузки приложения
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Анимация логотипа
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Анимация текста
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Анимация появления снизу
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));

    // Запуск анимаций
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
  }

  void _initializeApp() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    // Инициализация приложения
    await appState.initialize();
    
    // Задержка для показа анимации
    await Future.delayed(AppConfig.splashDuration);
    
    // Переход на главную страницу
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Логотип приложения
                      AnimatedBuilder(
                        animation: _logoAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
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
                              child: const Icon(
                                Icons.temple_hindu,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Название приложения
                      AnimatedBuilder(
                        animation: _textAnimation,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _textAnimation,
                              child: Column(
                                children: [
                                  Text(
                                    'Mahabharata',
                                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Client',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: AppTheme.secondaryColor,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Подзаголовок
                      AnimatedBuilder(
                        animation: _textAnimation,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _textAnimation,
                            child: Text(
                              'Интерактивное купольное отображение',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Индикатор загрузки
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // Прогресс бар
                    Consumer<AppStateProvider>(
                      builder: (context, appState, child) {
                        return LinearProgressIndicator(
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.secondaryColor,
                          ),
                          minHeight: 3,
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Статус загрузки
                    Consumer<AppStateProvider>(
                      builder: (context, appState, child) {
                        if (appState.isLoading) {
                          return Text(
                            'Инициализация...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          );
                        } else if (appState.error != null) {
                          return Text(
                            'Ошибка: ${appState.error}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.errorColor,
                            ),
                          );
                        } else {
                          return Text(
                            'Готово',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.successColor,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
