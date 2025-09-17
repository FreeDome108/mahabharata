#!/bin/bash

# 🏛️ Mahabharata Client - Скрипт запуска
# Flutter приложение для купольного отображения FreeDome

echo "🏛️ Mahabharata Client - Запуск приложения"
echo "=========================================="

# Проверка Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не установлен. Установите Flutter SDK 3.10.0+"
    exit 1
fi

# Проверка версии Flutter
FLUTTER_VERSION=$(flutter --version | head -n 1 | cut -d' ' -f2)
echo "📱 Flutter версия: $FLUTTER_VERSION"

# Проверка зависимостей
echo "📦 Проверка зависимостей..."
flutter doctor

# Установка зависимостей
echo "📦 Установка зависимостей..."
flutter pub get

# Генерация кода
echo "🔧 Генерация кода..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Проверка устройств
echo "📱 Доступные устройства:"
flutter devices

# Запуск приложения
echo "🚀 Запуск Mahabharata Client..."
echo ""

# Выбор режима запуска
echo "Выберите режим запуска:"
echo "1) Debug (разработка)"
echo "2) Release (продакшен)"
echo "3) Profile (профилирование)"
echo "4) Web (браузер)"
echo "5) Выход"

read -p "Введите номер (1-5): " choice

case $choice in
    1)
        echo "🔧 Запуск в режиме разработки..."
        flutter run --debug
        ;;
    2)
        echo "🚀 Запуск в режиме продакшена..."
        flutter run --release
        ;;
    3)
        echo "📊 Запуск в режиме профилирования..."
        flutter run --profile
        ;;
    4)
        echo "🌐 Запуск в браузере..."
        flutter run -d chrome
        ;;
    5)
        echo "👋 До свидания!"
        exit 0
        ;;
    *)
        echo "❌ Неверный выбор. Запуск в режиме разработки..."
        flutter run --debug
        ;;
esac

echo ""
echo "✅ Mahabharata Client завершен"
echo "🏛️ Спасибо за использование приложения!"
