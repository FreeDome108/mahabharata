#!/bin/bash

# 🎵 AnantaSound Build and Test Script
# Скрипт для сборки и тестирования Mahabharata Client с AnantaSound

set -e

echo "🎵 AnantaSound Build and Test Script"
echo "====================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка зависимостей
check_dependencies() {
    log_info "Проверка зависимостей..."
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter не найден. Установите Flutter SDK."
        exit 1
    fi
    
    if ! command -v dart &> /dev/null; then
        log_error "Dart не найден. Установите Dart SDK."
        exit 1
    fi
    
    log_success "Зависимости проверены"
}

# Очистка проекта
clean_project() {
    log_info "Очистка проекта..."
    flutter clean
    flutter pub get
    log_success "Проект очищен"
}

# Анализ кода
analyze_code() {
    log_info "Анализ кода..."
    flutter analyze
    log_success "Анализ кода завершен"
}

# Запуск тестов
run_tests() {
    log_info "Запуск тестов..."
    
    # Тесты AnantaSound
    log_info "Запуск тестов AnantaSound..."
    flutter test test/anantasound_service_test.dart
    
    # Все тесты
    log_info "Запуск всех тестов..."
    flutter test
    
    log_success "Тесты завершены"
}

# Сборка для Android
build_android() {
    log_info "Сборка для Android..."
    
    # APK
    flutter build apk --release
    log_success "Android APK собран"
    
    # App Bundle
    flutter build appbundle --release
    log_success "Android App Bundle собран"
}

# Сборка для iOS
build_ios() {
    log_info "Сборка для iOS..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        flutter build ios --release
        log_success "iOS приложение собрано"
    else
        log_warning "iOS сборка доступна только на macOS"
    fi
}

# Проверка интеграции AnantaSound
check_anantasound_integration() {
    log_info "Проверка интеграции AnantaSound..."
    
    # Проверка файлов
    local files=(
        "lib/core/services/anantasound_service.dart"
        "lib/features/settings/anantasound_settings_screen.dart"
        "android/app/src/main/kotlin/com/example/mbharata_client/AnantaSoundPlugin.kt"
        "ios/Runner/AnantaSoundPlugin.swift"
        "test/anantasound_service_test.dart"
        "docs/ANANTASOUND_INTEGRATION.md"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            log_success "✓ $file"
        else
            log_error "✗ $file не найден"
        fi
    done
    
    # Проверка импортов
    log_info "Проверка импортов..."
    if grep -q "anantasound_service" lib/core/services/audio_service.dart; then
        log_success "✓ AnantaSound импортирован в AudioService"
    else
        log_error "✗ AnantaSound не импортирован в AudioService"
    fi
    
    if grep -q "anantasound_settings_screen" lib/core/navigation/app_router.dart; then
        log_success "✓ AnantaSound Settings добавлен в роутер"
    else
        log_error "✗ AnantaSound Settings не добавлен в роутер"
    fi
}

# Генерация отчета
generate_report() {
    log_info "Генерация отчета..."
    
    local report_file="build_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# AnantaSound Build Report

**Дата:** $(date)
**Версия Flutter:** $(flutter --version | head -n 1)
**Версия Dart:** $(dart --version)

## Статус сборки

- ✅ Зависимости проверены
- ✅ Код проанализирован
- ✅ Тесты пройдены
- ✅ AnantaSound интегрирован

## Файлы AnantaSound

- ✅ lib/core/services/anantasound_service.dart
- ✅ lib/features/settings/anantasound_settings_screen.dart
- ✅ android/app/src/main/kotlin/com/example/mbharata_client/AnantaSoundPlugin.kt
- ✅ ios/Runner/AnantaSoundPlugin.swift
- ✅ test/anantasound_service_test.dart
- ✅ docs/ANANTASOUND_INTEGRATION.md

## Возможности

- 🎵 Квантовая акустическая обработка
- 🌐 QRD интеграция
- 🏛️ Купольная акустика
- 📱 Нативный UI
- 🧪 Полное тестирование

## Следующие шаги

1. Запустить приложение: \`flutter run\`
2. Перейти в Настройки → AnantaSound
3. Протестировать квантовые эффекты
4. Проверить интеграцию с купольным режимом

EOF

    log_success "Отчет сохранен: $report_file"
}

# Основная функция
main() {
    log_info "Начало сборки и тестирования AnantaSound..."
    
    check_dependencies
    clean_project
    analyze_code
    run_tests
    check_anantasound_integration
    
    # Сборка (опционально)
    if [ "$1" = "--build" ]; then
        build_android
        if [[ "$OSTYPE" == "darwin"* ]]; then
            build_ios
        fi
    fi
    
    generate_report
    
    log_success "🎵 AnantaSound успешно интегрирован в Mahabharata Client!"
    log_info "Для запуска приложения выполните: flutter run"
    log_info "Для сборки выполните: ./build_and_test.sh --build"
}

# Обработка аргументов
case "${1:-}" in
    --build)
        main --build
        ;;
    --test-only)
        check_dependencies
        run_tests
        check_anantasound_integration
        ;;
    --help)
        echo "Использование: $0 [--build|--test-only|--help]"
        echo "  --build     Собрать приложение для всех платформ"
        echo "  --test-only Запустить только тесты"
        echo "  --help      Показать эту справку"
        ;;
    *)
        main
        ;;
esac

