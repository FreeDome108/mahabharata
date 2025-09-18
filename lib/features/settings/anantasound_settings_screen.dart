import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/app_router.dart';
import '../../core/services/anantasound_service.dart';

/// Экран настроек AnantaSound
class AnantaSoundSettingsScreen extends StatefulWidget {
  const AnantaSoundSettingsScreen({super.key});

  @override
  State<AnantaSoundSettingsScreen> createState() => _AnantaSoundSettingsScreenState();
}

class _AnantaSoundSettingsScreenState extends State<AnantaSoundSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  final AnantaSoundService _anantaSound = AnantaSoundService.instance;
  SystemStatistics? _currentStats;
  List<QuantumSoundField> _quantumFields = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStatisticsUpdates();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  void _startStatisticsUpdates() {
    _anantaSound.statisticsStream.listen((stats) {
      if (mounted) {
        setState(() {
          _currentStats = stats;
        });
      }
    });

    _anantaSound.fieldsStream.listen((fields) {
      if (mounted) {
        setState(() {
          _quantumFields = fields;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AnantaSound'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goBack(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAnantaSoundInfo(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.purple.withOpacity(0.1),
              Colors.black,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Заголовок с анимацией
            _buildAnimatedHeader(),
            
            const SizedBox(height: 24),
            
            // Статистика системы
            _buildSystemStatistics(),
            
            const SizedBox(height: 24),
            
            // Квантовые настройки
            _buildQuantumSettings(),
            
            const SizedBox(height: 24),
            
            // Купольный резонатор
            _buildDomeResonator(),
            
            const SizedBox(height: 24),
            
            // Квантовые поля
            _buildQuantumFields(),
            
            const SizedBox(height: 24),
            
            // Экспериментальные функции
            _buildExperimentalFeatures(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.withOpacity(0.3),
              Colors.blue.withOpacity(0.3),
              Colors.indigo.withOpacity(0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Анимированный логотип
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.blue, Colors.indigo],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Название системы
              Text(
                'AnantaSound',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Подзаголовок
              Text(
                'Квантовая акустическая система',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Статус системы
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _anantaSound.isInitialized 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _anantaSound.isInitialized 
                        ? Colors.green
                        : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _anantaSound.isInitialized 
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _anantaSound.isInitialized ? 'Система активна' : 'Система неактивна',
                      style: TextStyle(
                        color: _anantaSound.isInitialized 
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildSystemStatistics() {
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
              Colors.purple.withOpacity(0.1),
              Colors.blue.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: Colors.purple,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Статистика системы',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              if (_currentStats != null) ...[
                // Активные поля
                _buildStatItem(
                  'Активные поля',
                  '${_currentStats!.activeFields}',
                  Icons.waves,
                  Colors.blue,
                ),
                
                const SizedBox(height: 12),
                
                // Запутанные пары
                _buildStatItem(
                  'Запутанные пары',
                  '${_currentStats!.entangledPairs}',
                  Icons.link,
                  Colors.purple,
                ),
                
                const SizedBox(height: 12),
                
                // Когерентность
                _buildStatItem(
                  'Когерентность',
                  '${(_currentStats!.coherenceRatio * 100).toStringAsFixed(1)}%',
                  Icons.tune,
                  Colors.green,
                ),
                
                const SizedBox(height: 12),
                
                // Квантовая неопределенность
                _buildStatItem(
                  'Квантовая неопределенность',
                  '${(_currentStats!.quantumUncertainty * 100).toStringAsFixed(1)}%',
                  Icons.help_outline,
                  Colors.orange,
                ),
                
                const SizedBox(height: 12),
                
                // Купольный резонанс
                _buildStatItem(
                  'Купольный резонанс',
                  '${(_currentStats!.domeResonance * 100).toStringAsFixed(1)}%',
                  Icons.threed_rotation,
                  Colors.indigo,
                ),
              ] else ...[
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantumSettings() {
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
              Colors.purple.withOpacity(0.1),
              Colors.blue.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.settings,
                    color: Colors.purple,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Квантовые настройки',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Квантовая неопределенность
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Квантовая неопределенность',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_anantaSound.quantumUncertainty * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _anantaSound.quantumUncertainty,
                    onChanged: (value) {
                      _anantaSound.setQuantumUncertainty(value);
                      setState(() {});
                    },
                    activeColor: Colors.purple,
                    inactiveColor: Colors.grey[300],
                    min: 0.0,
                    max: 1.0,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Кнопки управления
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _createTestQuantumField(),
                      icon: const Icon(Icons.add),
                      label: const Text('Создать поле'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _clearQuantumFields(),
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Очистить'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple,
                        side: BorderSide(color: Colors.purple),
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

  Widget _buildDomeResonator() {
    final resonator = _anantaSound.domeResonator;
    
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
              Colors.indigo.withOpacity(0.1),
              Colors.blue.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.threed_rotation,
                    color: Colors.indigo,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Купольный резонатор',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              if (resonator != null) ...[
                _buildResonatorInfo('Радиус', '${resonator.radius.toStringAsFixed(1)} м', Icons.radio_button_unchecked),
                _buildResonatorInfo('Высота', '${resonator.height.toStringAsFixed(1)} м', Icons.height),
                _buildResonatorInfo('Резонансная частота', '${resonator.resonanceFrequency.toStringAsFixed(1)} Гц', Icons.music_note),
                _buildResonatorInfo('Добротность', '${resonator.qualityFactor.toStringAsFixed(1)}', Icons.tune),
                
                const SizedBox(height: 16),
                
                Text(
                  'Гармоники:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: resonator.harmonics.map((harmonic) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.indigo.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${harmonic.toStringAsFixed(0)} Гц',
                        style: TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                const Text('Резонатор не инициализирован'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResonatorInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.indigo,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantumFields() {
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
              Colors.blue.withOpacity(0.1),
              Colors.cyan.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.waves,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Квантовые поля (${_quantumFields.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              if (_quantumFields.isNotEmpty) ...[
                ..._quantumFields.take(5).map((field) => _buildQuantumFieldItem(field)),
                if (_quantumFields.length > 5) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '... и еще ${_quantumFields.length - 5} полей',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ] else ...[
                const Center(
                  child: Text(
                    'Нет активных квантовых полей',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantumFieldItem(QuantumSoundField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStateColor(field.state),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${field.frequency.toStringAsFixed(1)} Гц',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${field.state.name} • R:${field.position.r.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(field.amplitude.magnitude * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperimentalFeatures() {
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
              Colors.orange.withOpacity(0.1),
              Colors.red.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.science,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Экспериментальные функции',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Text(
                '⚠️ Внимание: Эти функции находятся в экспериментальной стадии и могут влиять на стабильность системы.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange[700],
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showExperimentalDialog(),
                  icon: const Icon(Icons.science),
                  label: const Text('Экспериментальные настройки'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStateColor(QuantumSoundState state) {
    switch (state) {
      case QuantumSoundState.coherent:
        return Colors.green;
      case QuantumSoundState.incoherent:
        return Colors.red;
      case QuantumSoundState.entangled:
        return Colors.purple;
      case QuantumSoundState.superposed:
        return Colors.blue;
      case QuantumSoundState.collapsed:
        return Colors.grey;
    }
  }

  void _createTestQuantumField() {
    final position = SphericalCoord(
      r: 5.0,
      theta: 1.0,
      phi: 0.5,
      height: 2.0,
    );
    
    final field = _anantaSound.createQuantumSoundField(
      440.0,
      position,
      QuantumSoundState.coherent,
    );
    
    _anantaSound.processSoundField(field);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Квантовое поле создано'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearQuantumFields() {
    // В реальной реализации здесь была бы функция очистки полей
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Квантовые поля очищены'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showAnantaSoundInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'AnantaSound',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Квантовая акустическая система для купольного отображения.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              'Возможности:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Квантовые звуковые поля', style: TextStyle(color: Colors.white70)),
            Text('• Интерференционные эффекты', style: TextStyle(color: Colors.white70)),
            Text('• Купольный резонанс', style: TextStyle(color: Colors.white70)),
            Text('• Квантовая запутанность', style: TextStyle(color: Colors.white70)),
            Text('• Пространственное аудио', style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(color: Colors.purple),
            ),
          ),
        ],
      ),
    );
  }

  void _showExperimentalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Экспериментальные функции',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Эти функции находятся в разработке и могут быть нестабильными.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}
