import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/seasons/seasons_screen.dart';
import '../../features/episode/episode_screen.dart';
import '../../features/dome/dome_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/anantasound_settings_screen.dart';
import '../../features/profile/profile_screen.dart';

/// Роутер приложения Mbharata Client
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Home Screen
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      
      // Seasons Screen
      GoRoute(
        path: '/seasons',
        name: 'seasons',
        builder: (context, state) => const SeasonsScreen(),
      ),
      
      // Episode Screen
      GoRoute(
        path: '/episode/:episodeId',
        name: 'episode',
        builder: (context, state) {
          final episodeId = state.pathParameters['episodeId']!;
          return EpisodeScreen(episodeId: episodeId);
        },
      ),
      
      // Dome Screen
      GoRoute(
        path: '/dome',
        name: 'dome',
        builder: (context, state) => const DomeScreen(),
      ),
      
      // Settings Screen
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // AnantaSound Settings Screen
      GoRoute(
        path: '/settings/anantasound',
        name: 'anantasound-settings',
        builder: (context, state) => const AnantaSoundSettingsScreen(),
      ),
      
      // Profile Screen
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Страница не найдена',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Путь: ${state.location}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Расширения для навигации
extension AppRouterExtensions on BuildContext {
  /// Переход на главную страницу
  void goToHome() => go('/home');
  
  /// Переход к списку сезонов
  void goToSeasons() => go('/seasons');
  
  /// Переход к эпизоду
  void goToEpisode(String episodeId) => go('/episode/$episodeId');
  
  /// Переход к купольному отображению
  void goToDome() => go('/dome');
  
  /// Переход к настройкам
  void goToSettings() => go('/settings');
  
  /// Переход к настройкам AnantaSound
  void goToAnantaSoundSettings() => go('/settings/anantasound');
  
  /// Переход к профилю
  void goToProfile() => go('/profile');
  
  /// Возврат назад
  void goBack() => pop();
  
  /// Возврат к корню
  void goToRoot() => go('/home');
}
