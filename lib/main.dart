import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_magento/flutter_magento.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/services/hive_service.dart';
import 'core/services/audio_service.dart';
import 'core/services/dome_service.dart';
import 'core/services/magento_native_service.dart';
import 'core/services/anantasound_service.dart';
import 'core/providers/app_providers.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Hive для локального хранения
  await Hive.initFlutter();
  await HiveService.initialize();

  // Инициализация аудио сервиса
  await AudioService.initialize();

  // Инициализация купольного сервиса
  await DomeService.initialize();

  // Инициализация AnantaSound
  await AnantaSoundService.initialize();

  // Инициализация нативного Magento сервиса
  await MagentoNativeService.instance.initialize(
    supportedLanguages: ['en', 'ru', 'hi', 'sa'],
  );

  // Настройка ориентации экрана
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Настройка системного UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ...AppProviders.providers,
          // Добавляем провайдеры flutter_magento
          if (MagentoNativeService.instance.magentoProvider != null)
            ChangeNotifierProvider<MagentoProvider>.value(
              value: MagentoNativeService.instance.magentoProvider!,
            ),
          if (MagentoNativeService.instance.authProvider != null)
            ChangeNotifierProvider<AuthProvider>.value(
              value: MagentoNativeService.instance.authProvider!,
            ),
        ],
        child: const MbharataApp(),
      ),
    ),
  );
}

class MbharataApp extends ConsumerWidget {
  const MbharataApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter.router;
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Mahabharata Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler:
                TextScaler.linear(1.0), // Отключение масштабирования текста
          ),
          child: child!,
        );
      },
    );
  }
}

/// Провайдер для роутера приложения
// Removed Riverpod provider - using direct router access

/// Провайдер для темы приложения
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});
