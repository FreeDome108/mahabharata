import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/app_router.dart';

/// Экран настроек приложения
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goBack(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Внешний вид
            _buildSection(
              title: 'Внешний вид',
              icon: Icons.palette,
              children: [
                _buildThemeSwitch(),
                _buildLanguageSelector(),
              ],
            ),

            const SizedBox(height: 24),

            // Аудио
            _buildSection(
              title: 'Аудио',
              icon: Icons.volume_up,
              children: [
                _buildVolumeSlider(),
                _buildSpatialAudioSwitch(),
                _buildAnantaSoundSettings(),
              ],
            ),

            const SizedBox(height: 24),

            // Купольное отображение
            _buildSection(
              title: 'Купольное отображение',
              icon: Icons.threed_rotation,
              children: [
                _buildDomeSettings(),
              ],
            ),

            const SizedBox(height: 24),

            // Облачные функции
            _buildSection(
              title: 'Облачные функции',
              icon: Icons.cloud,
              children: [
                _buildCloudToggle(),
                _buildCloudStatus(),
                _buildCloudSync(),
                _buildCloudLogin(),
              ],
            ),

            const SizedBox(height: 24),

            // Интерактивность
            _buildSection(
              title: 'Интерактивность',
              icon: Icons.touch_app,
              children: [
                _buildHapticFeedbackSwitch(),
                _buildTouchSensitivitySlider(),
              ],
            ),

            const SizedBox(height: 24),

            // О приложении
            _buildSection(
              title: 'О приложении',
              icon: Icons.info,
              children: [
                _buildAppInfo(),
                _buildVersionInfo(),
                _buildClearCacheButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.secondaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок секции
              Row(
                children: [
                  Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Содержимое секции
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSwitch() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return ListTile(
          title: const Text('Темная тема'),
          subtitle: const Text('Использовать темную цветовую схему'),
          leading: const Icon(Icons.dark_mode),
          trailing: Switch(
            value: settingsProvider.darkMode,
            onChanged: (value) => settingsProvider.setDarkMode(value),
            activeColor: AppTheme.primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return ListTile(
          title: const Text('Язык'),
          subtitle: Text(_getLanguageName(settingsProvider.language)),
          leading: const Icon(Icons.language),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showLanguageDialog(settingsProvider),
        );
      },
    );
  }

  Widget _buildVolumeSlider() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Громкость'),
              subtitle:
                  Text('${(settingsProvider.audioVolume * 100).round()}%'),
              leading: const Icon(Icons.volume_up),
            ),
            Slider(
              value: settingsProvider.audioVolume,
              onChanged: (value) => settingsProvider.setAudioVolume(value),
              activeColor: AppTheme.primaryColor,
              inactiveColor: Colors.grey[300],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpatialAudioSwitch() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return ListTile(
          title: const Text('Пространственное аудио'),
          subtitle: const Text('3D позиционирование звука в куполе'),
          leading: const Icon(Icons.surround_sound),
          trailing: Switch(
            value: settingsProvider.enableSpatialAudio,
            onChanged: (value) => settingsProvider.setEnableSpatialAudio(value),
            activeColor: AppTheme.primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildAnantaSoundSettings() {
    return ListTile(
      title: const Text('AnantaSound'),
      subtitle: const Text('Квантовая акустическая система'),
      leading: const Icon(Icons.psychology),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => context.goToAnantaSoundSettings(),
    );
  }

  Widget _buildDomeSettings() {
    return ListTile(
      title: const Text('Настройки купола'),
      subtitle: const Text('Радиус, проекция, оптимизация'),
      leading: const Icon(Icons.threed_rotation),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _showDomeSettingsDialog(),
    );
  }

  Widget _buildHapticFeedbackSwitch() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return ListTile(
          title: const Text('Тактильная обратная связь'),
          subtitle: const Text('Вибрация при взаимодействии'),
          leading: const Icon(Icons.vibration),
          trailing: Switch(
            value: settingsProvider.enableHapticFeedback,
            onChanged: (value) =>
                settingsProvider.setEnableHapticFeedback(value),
            activeColor: AppTheme.primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildTouchSensitivitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text('Чувствительность касаний'),
          subtitle:
              Text('Настройка чувствительности для купольного управления'),
          leading: Icon(Icons.touch_app),
        ),
        Slider(
          value: 1.0, // TODO: Добавить в настройки
          onChanged: (value) {
            // TODO: Обновить чувствительность
          },
          activeColor: AppTheme.primaryColor,
          inactiveColor: Colors.grey[300],
          min: 0.5,
          max: 2.0,
        ),
      ],
    );
  }

  Widget _buildAppInfo() {
    return ListTile(
      title: const Text('Mahabharata Client'),
      subtitle: const Text('Версия 1.0.0'),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.temple_hindu,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return ListTile(
      title: const Text('Информация о версии'),
      subtitle: const Text('Сборка 1'),
      leading: const Icon(Icons.info_outline),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _showVersionInfo(),
    );
  }

  Widget _buildClearCacheButton() {
    return ListTile(
      title: const Text('Очистить кэш'),
      subtitle: const Text('Удалить временные файлы'),
      leading: const Icon(Icons.clear_all),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _showClearCacheDialog(),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      case 'hi':
        return 'हिन्दी';
      case 'th':
        return 'ไทย';
      default:
        return 'English';
    }
  }

  void _showLanguageDialog(SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Выберите язык',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('en', 'English', settingsProvider),
            _buildLanguageOption('ru', 'Русский', settingsProvider),
            _buildLanguageOption('hi', 'हिन्दी', settingsProvider),
            _buildLanguageOption('th', 'ไทย', settingsProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
      String code, String name, SettingsProvider settingsProvider) {
    return ListTile(
      title: Text(
        name,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: settingsProvider.language == code
          ? const Icon(Icons.check, color: AppTheme.primaryColor)
          : null,
      onTap: () {
        settingsProvider.setLanguage(code);
        Navigator.of(context).pop();
      },
    );
  }

  void _showDomeSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Настройки купола',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Радиус купола',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '10.0 м',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ListTile(
              title: Text(
                'Тип проекции',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Сферическая',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ListTile(
              title: Text(
                'Коррекция fisheye',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Включена',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Информация о версии',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mahabharata Client',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Версия: 1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'Сборка: 1',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'Flutter: 3.10.0',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 NativeMindNONC',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'Все права защищены',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Очистить кэш',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Это действие удалит все временные файлы и данные кэша. Продолжить?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Очистить кэш
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Кэш очищен'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text(
              'Очистить',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudToggle() {
    return Consumer<CloudProvider>(
      builder: (context, cloudProvider, child) {
        return ListTile(
          title: const Text('Облачные функции'),
          subtitle: Text(cloudProvider.isCloudEnabled
              ? 'Синхронизация с облаком включена'
              : 'Работа в автономном режиме'),
          leading: Icon(
            cloudProvider.isCloudEnabled ? Icons.cloud : Icons.cloud_off,
            color: cloudProvider.isCloudEnabled ? Colors.green : Colors.grey,
          ),
          trailing: Switch(
            value: cloudProvider.isCloudEnabled,
            onChanged: (value) => _toggleCloudFeatures(value, cloudProvider),
            activeColor: AppTheme.primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildCloudStatus() {
    return Consumer<CloudProvider>(
      builder: (context, cloudProvider, child) {
        if (!cloudProvider.isCloudEnabled) {
          return const SizedBox.shrink();
        }

        return ListTile(
          title: const Text('Статус подключения'),
          subtitle: Text(_getConnectionStatus(cloudProvider)),
          leading: Icon(
            cloudProvider.isConnected ? Icons.wifi : Icons.wifi_off,
            color: cloudProvider.isConnected ? Colors.green : Colors.red,
          ),
          trailing: cloudProvider.isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  cloudProvider.isConnected ? Icons.check_circle : Icons.error,
                  color: cloudProvider.isConnected ? Colors.green : Colors.red,
                ),
        );
      },
    );
  }

  Widget _buildCloudSync() {
    return Consumer<CloudProvider>(
      builder: (context, cloudProvider, child) {
        if (!cloudProvider.isCloudEnabled) {
          return const SizedBox.shrink();
        }

        return ListTile(
          title: const Text('Синхронизация'),
          subtitle: Text(_getLastSyncInfo(cloudProvider)),
          leading: const Icon(Icons.sync),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: cloudProvider.isSyncing
              ? null
              : () => _performSync(cloudProvider),
        );
      },
    );
  }

  Widget _buildCloudLogin() {
    return Consumer<CloudProvider>(
      builder: (context, cloudProvider, child) {
        if (!cloudProvider.isCloudEnabled) {
          return const SizedBox.shrink();
        }

        return ListTile(
          title: Text(cloudProvider.isAuthenticated ? 'Аккаунт' : 'Войти'),
          subtitle: Text(cloudProvider.isAuthenticated
              ? cloudProvider.userEmail ?? 'Пользователь'
              : 'Войдите для синхронизации данных'),
          leading: Icon(
            cloudProvider.isAuthenticated ? Icons.account_circle : Icons.login,
            color: cloudProvider.isAuthenticated ? Colors.green : Colors.grey,
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => cloudProvider.isAuthenticated
              ? _showAccountDialog(cloudProvider)
              : _showLoginDialog(cloudProvider),
        );
      },
    );
  }

  String _getConnectionStatus(CloudProvider cloudProvider) {
    if (cloudProvider.isSyncing) {
      return 'Синхронизация...';
    }
    if (cloudProvider.error != null) {
      return 'Ошибка: ${cloudProvider.error}';
    }
    if (cloudProvider.isConnected) {
      return 'Подключено к облаку';
    }
    return 'Нет подключения';
  }

  String _getLastSyncInfo(CloudProvider cloudProvider) {
    if (cloudProvider.lastSync == null) {
      return 'Синхронизация не выполнялась';
    }

    final now = DateTime.now();
    final diff = now.difference(cloudProvider.lastSync!);

    if (diff.inMinutes < 1) {
      return 'Синхронизировано только что';
    } else if (diff.inMinutes < 60) {
      return 'Синхронизировано ${diff.inMinutes} мин. назад';
    } else if (diff.inHours < 24) {
      return 'Синхронизировано ${diff.inHours} ч. назад';
    } else {
      return 'Синхронизировано ${diff.inDays} дн. назад';
    }
  }

  void _toggleCloudFeatures(bool enabled, CloudProvider cloudProvider) async {
    if (enabled) {
      _showCloudSetupDialog(cloudProvider);
    } else {
      await cloudProvider.disableCloudFeatures();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Облачные функции отключены'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showCloudSetupDialog(CloudProvider cloudProvider) {
    final baseUrlController = TextEditingController();
    final consumerKeyController = TextEditingController();
    final consumerSecretController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Настройка облачных функций',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Введите параметры подключения к Magento:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: baseUrlController,
              decoration: const InputDecoration(
                labelText: 'URL сервера',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'https://your-magento-server.com',
                hintStyle: TextStyle(color: Colors.white38),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: consumerKeyController,
              decoration: const InputDecoration(
                labelText: 'Consumer Key',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: consumerSecretController,
              decoration: const InputDecoration(
                labelText: 'Consumer Secret',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (baseUrlController.text.isNotEmpty &&
                  consumerKeyController.text.isNotEmpty &&
                  consumerSecretController.text.isNotEmpty) {
                Navigator.of(context).pop();

                final success = await cloudProvider.enableCloudFeatures(
                  baseUrl: baseUrlController.text,
                  consumerKey: consumerKeyController.text,
                  consumerSecret: consumerSecretController.text,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Облачные функции включены'
                          : 'Ошибка подключения к облаку'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Подключить',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _performSync(CloudProvider cloudProvider) async {
    final success = await cloudProvider.syncData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'Синхронизация завершена' : 'Ошибка синхронизации'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showLoginDialog(CloudProvider cloudProvider) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Вход в аккаунт',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Войдите в свой аккаунт для синхронизации данных:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty &&
                  passwordController.text.isNotEmpty) {
                Navigator.of(context).pop();

                final success = await cloudProvider.authenticateUser(
                  email: emailController.text,
                  password: passwordController.text,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          success ? 'Вход выполнен успешно' : 'Ошибка входа'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Войти',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountDialog(CloudProvider cloudProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Аккаунт',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email: ${cloudProvider.userEmail}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Последняя синхронизация: ${_getLastSyncInfo(cloudProvider)}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await cloudProvider.logout();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Выход выполнен'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text(
              'Выйти',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
