import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/app_router.dart';
import '../../core/services/dome_service.dart';

/// Экран купольного отображения FreeDome
class DomeScreen extends StatefulWidget {
  const DomeScreen({super.key});

  @override
  State<DomeScreen> createState() => _DomeScreenState();
}

class _DomeScreenState extends State<DomeScreen>
    with TickerProviderStateMixin {
  late FlutterGlPlugin flutterGlPlugin;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isInitialized = false;
  bool _showControls = true;
  double _domeRadius = 10.0;
  double _cameraDistance = 15.0;
  
  // 3D объекты
  List<Map<String, dynamic>> _domeObjects = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDome();
  }

  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _scaleController.forward();
  }

  void _initializeDome() async {
    try {
      flutterGlPlugin = FlutterGlPlugin();
      await flutterGlPlugin.initialize();
      
      // Включаем купольный режим
      final domeProvider = Provider.of<DomeProvider>(context, listen: false);
      domeProvider.enableDomeMode();
      
      // Создаем 3D объекты для купола
      _createDomeObjects();
      
      setState(() {
        _isInitialized = true;
      });
      
      // Запускаем анимацию
      _rotationController.repeat();
      
    } catch (e) {
      debugPrint('Ошибка инициализации купола: $e');
    }
  }

  void _createDomeObjects() {
    _domeObjects = [
      // Центральный объект
      {
        'type': 'sphere',
        'position': vm.Vector3(0, 0, 0),
        'scale': vm.Vector3(2, 2, 2),
        'color': vm.Vector4(1, 0.5, 0, 1), // Оранжевый
        'texture': 'mahabharata_logo',
      },
      
      // Орбитальные объекты
      {
        'type': 'cube',
        'position': vm.Vector3(5, 0, 0),
        'scale': vm.Vector3(1, 1, 1),
        'color': vm.Vector4(0, 0.8, 1, 1), // Голубой
        'rotation': vm.Vector3(0, 0, 0),
      },
      {
        'type': 'pyramid',
        'position': vm.Vector3(-5, 0, 0),
        'scale': vm.Vector3(1.5, 1.5, 1.5),
        'color': vm.Vector4(1, 0, 0.5, 1), // Розовый
        'rotation': vm.Vector3(0, 0, 0),
      },
      {
        'type': 'cylinder',
        'position': vm.Vector3(0, 5, 0),
        'scale': vm.Vector3(1, 2, 1),
        'color': vm.Vector4(0.5, 1, 0, 1), // Зеленый
        'rotation': vm.Vector3(0, 0, 0),
      },
      {
        'type': 'torus',
        'position': vm.Vector3(0, -5, 0),
        'scale': vm.Vector3(2, 0.5, 2),
        'color': vm.Vector4(1, 1, 0, 1), // Желтый
        'rotation': vm.Vector3(0, 0, 0),
      },
    ];
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    flutterGlPlugin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 3D купольное отображение
          _buildDomeView(),
          
          // Элементы управления
          if (_showControls) _buildControls(),
          
          // Информационная панель
          if (_showControls) _buildInfoPanel(),
        ],
      ),
    );
  }

  Widget _buildDomeView() {
    if (!_isInitialized) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppTheme.domeGradient,
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
                'Инициализация купола...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onPanUpdate: (details) => _handlePanGesture(details),
      onScaleUpdate: (details) => _handleScaleGesture(details),
      onTap: () => _toggleControls(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Colors.black,
              Colors.black87,
              Colors.black,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _build3DScene(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _build3DScene() {
    return CustomPaint(
      painter: Dome3DPainter(
        domeObjects: _domeObjects,
        rotation: _rotationAnimation.value,
        domeRadius: _domeRadius,
        cameraDistance: _cameraDistance,
      ),
      size: Size.infinite,
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
              Colors.black.withOpacity(0.8),
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
              
              // Заголовок
              const Text(
                'FreeDome',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const Spacer(),
              
              // Кнопка настроек купола
              IconButton(
                onPressed: () => _showDomeSettings(),
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

  Widget _buildInfoPanel() {
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
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Статус купола
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Купол активен',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Информация о позиции
              Consumer<DomeProvider>(
                builder: (context, domeProvider, child) {
                  final position = domeProvider.cameraPosition;
                  return Text(
                    'Позиция: X:${position['x']?.toStringAsFixed(1)}, Y:${position['y']?.toStringAsFixed(1)}, Z:${position['z']?.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 8),
              
              // Информация о повороте
              Consumer<DomeProvider>(
                builder: (context, domeProvider, child) {
                  final rotation = domeProvider.cameraRotation;
                  return Text(
                    'Поворот: X:${rotation['x']?.toStringAsFixed(1)}, Y:${rotation['y']?.toStringAsFixed(1)}, Z:${rotation['z']?.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Кнопки управления
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _resetCamera(),
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text('Сброс'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleAnimation(),
                      icon: Icon(_rotationController.isAnimating ? Icons.pause : Icons.play_arrow),
                      label: Text(_rotationController.isAnimating ? 'Пауза' : 'Воспроизвести'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
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

  void _handlePanGesture(DragUpdateDetails details) {
    final domeProvider = Provider.of<DomeProvider>(context, listen: false);
    domeProvider.handleGesture(
      type: 'pan',
      deltaX: details.delta.dx,
      deltaY: details.delta.dy,
    );
  }

  void _handleScaleGesture(ScaleUpdateDetails details) {
    final domeProvider = Provider.of<DomeProvider>(context, listen: false);
    domeProvider.handleGesture(
      type: 'zoom',
      deltaX: 0,
      deltaY: 0,
      deltaZ: details.scale - 1.0,
    );
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _showDomeSettings() {
    showDialog(
      context: context,
      builder: (context) => _buildDomeSettingsDialog(),
    );
  }

  Widget _buildDomeSettingsDialog() {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Настройки купола',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Радиус купола
          ListTile(
            title: const Text(
              'Радиус купола',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '${_domeRadius.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _domeRadius = (_domeRadius - 1).clamp(5.0, 20.0);
                    });
                  },
                  icon: const Icon(Icons.remove, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _domeRadius = (_domeRadius + 1).clamp(5.0, 20.0);
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Расстояние камеры
          ListTile(
            title: const Text(
              'Расстояние камеры',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '${_cameraDistance.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _cameraDistance = (_cameraDistance - 1).clamp(10.0, 30.0);
                    });
                  },
                  icon: const Icon(Icons.remove, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _cameraDistance = (_cameraDistance + 1).clamp(10.0, 30.0);
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
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
    );
  }

  void _resetCamera() {
    final domeProvider = Provider.of<DomeProvider>(context, listen: false);
    domeProvider.updateCameraPosition({'x': 0.0, 'y': 0.0, 'z': 15.0});
    domeProvider.updateCameraRotation({'x': 0.0, 'y': 0.0, 'z': 0.0});
  }

  void _toggleAnimation() {
    if (_rotationController.isAnimating) {
      _rotationController.stop();
    } else {
      _rotationController.repeat();
    }
  }
}

/// Кастомный painter для 3D сцены купола
class Dome3DPainter extends CustomPainter {
  final List<Map<String, dynamic>> domeObjects;
  final double rotation;
  final double domeRadius;
  final double cameraDistance;

  Dome3DPainter({
    required this.domeObjects,
    required this.rotation,
    required this.domeRadius,
    required this.cameraDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Рисуем фон купола
    _drawDomeBackground(canvas, size);
    
    // Рисуем 3D объекты
    for (final obj in domeObjects) {
      _draw3DObject(canvas, center, obj);
    }
    
    // Рисуем сетку купола
    _drawDomeGrid(canvas, size);
  }

  void _drawDomeBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.black,
          Colors.black87,
          Colors.black,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  void _draw3DObject(Canvas canvas, Offset center, Map<String, dynamic> obj) {
    final position = obj['position'] as vm.Vector3;
    final scale = obj['scale'] as vm.Vector3;
    final color = obj['color'] as vm.Vector4;
    
    // Применяем поворот
    final rotatedPosition = _rotatePoint(position, rotation);
    
    // Проекция на 2D
    final projected = _projectTo2D(rotatedPosition, center);
    
    // Рисуем объект в зависимости от типа
    switch (obj['type']) {
      case 'sphere':
        _drawSphere(canvas, projected, scale, color);
        break;
      case 'cube':
        _drawCube(canvas, projected, scale, color);
        break;
      case 'pyramid':
        _drawPyramid(canvas, projected, scale, color);
        break;
      case 'cylinder':
        _drawCylinder(canvas, projected, scale, color);
        break;
      case 'torus':
        _drawTorus(canvas, projected, scale, color);
        break;
    }
  }

  void _drawSphere(Canvas canvas, Offset position, vm.Vector3 scale, vm.Vector4 color) {
    final paint = Paint()
      ..color = Color.fromARGB(
        (color.w * 255).round(),
        (color.x * 255).round(),
        (color.y * 255).round(),
        (color.z * 255).round(),
      )
      ..style = PaintingStyle.fill;
    
    final radius = scale.x * 20;
    canvas.drawCircle(position, radius, paint);
    
    // Добавляем блик
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(position.dx - radius * 0.3, position.dy - radius * 0.3),
      radius * 0.3,
      highlightPaint,
    );
  }

  void _drawCube(Canvas canvas, Offset position, vm.Vector3 scale, vm.Vector4 color) {
    final paint = Paint()
      ..color = Color.fromARGB(
        (color.w * 255).round(),
        (color.x * 255).round(),
        (color.y * 255).round(),
        (color.z * 255).round(),
      )
      ..style = PaintingStyle.fill;
    
    final size = scale.x * 30;
    final rect = Rect.fromCenter(
      center: position,
      width: size,
      height: size,
    );
    
    canvas.drawRect(rect, paint);
  }

  void _drawPyramid(Canvas canvas, Offset position, vm.Vector3 scale, vm.Vector4 color) {
    final paint = Paint()
      ..color = Color.fromARGB(
        (color.w * 255).round(),
        (color.x * 255).round(),
        (color.y * 255).round(),
        (color.z * 255).round(),
      )
      ..style = PaintingStyle.fill;
    
    final size = scale.x * 25;
    final path = Path()
      ..moveTo(position.dx, position.dy - size)
      ..lineTo(position.dx - size, position.dy + size)
      ..lineTo(position.dx + size, position.dy + size)
      ..close();
    
    canvas.drawPath(path, paint);
  }

  void _drawCylinder(Canvas canvas, Offset position, vm.Vector3 scale, vm.Vector4 color) {
    final paint = Paint()
      ..color = Color.fromARGB(
        (color.w * 255).round(),
        (color.x * 255).round(),
        (color.y * 255).round(),
        (color.z * 255).round(),
      )
      ..style = PaintingStyle.fill;
    
    final width = scale.x * 20;
    final height = scale.y * 40;
    final rect = Rect.fromCenter(
      center: position,
      width: width,
      height: height,
    );
    
    canvas.drawOval(rect, paint);
  }

  void _drawTorus(Canvas canvas, Offset position, vm.Vector3 scale, vm.Vector4 color) {
    final paint = Paint()
      ..color = Color.fromARGB(
        (color.w * 255).round(),
        (color.x * 255).round(),
        (color.y * 255).round(),
        (color.z * 255).round(),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    final radius = scale.x * 30;
    canvas.drawCircle(position, radius, paint);
  }

  void _drawDomeGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;
    
    // Рисуем концентрические окружности
    for (int i = 1; i <= 5; i++) {
      final radius = maxRadius * i / 5;
      canvas.drawCircle(center, radius, paint);
    }
    
    // Рисуем радиальные линии
    for (int i = 0; i < 12; i++) {
      final angle = i * pi / 6;
      final endX = center.dx + cos(angle) * maxRadius;
      final endY = center.dy + sin(angle) * maxRadius;
      canvas.drawLine(
        center,
        Offset(endX, endY),
        paint,
      );
    }
  }

  vm.Vector3 _rotatePoint(vm.Vector3 point, double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    
    return vm.Vector3(
      point.x * cosA - point.z * sinA,
      point.y,
      point.x * sinA + point.z * cosA,
    );
  }

  Offset _projectTo2D(vm.Vector3 point, Offset center) {
    // Простая ортогональная проекция
    final scale = 10.0;
    return Offset(
      center.dx + point.x * scale,
      center.dy + point.y * scale,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
