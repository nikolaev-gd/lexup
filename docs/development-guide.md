# Руководство по разработке LexUp

Это руководство содержит информацию, необходимую для разработки проекта LexUp. Оно включает инструкции по настройке окружения, описание структуры проекта, рабочих процессов и стандартов кода.

## Настройка окружения разработки

### Необходимые инструменты

1. Flutter SDK:
   - Установите последнюю стабильную версию Flutter
   - Выполните `flutter doctor` для проверки установки
   - Убедитесь, что все зависимости установлены

2. IDE:
   - Visual Studio Code или Android Studio
   - Установите плагины для Flutter и Dart
   - Настройте форматирование кода

3. Firebase:
   - Установите Firebase CLI: `npm install -g firebase-tools`
   - Войдите в аккаунт: `firebase login`
   - Получите конфигурационные файлы из Firebase Console
   - Добавьте файлы в проект согласно инструкциям Firebase

4. OpenAI API:
   - Получите API ключ в OpenAI Dashboard
   - Создайте файл `lib/config/api_keys.dart` на основе `api_keys.example.dart`
   - Добавьте API ключ в конфигурацию

### Конфигурация проекта

1. Клонирование репозитория:
   ```bash
   git clone <repository-url>
   cd lexup
   ```

2. Установка зависимостей:
   ```bash
   flutter pub get
   ```

3. Настройка Firebase:
   - Добавьте `google-services.json` для Android
   - Добавьте `GoogleService-Info.plist` для iOS
   - Обновите `firebase_options.dart` при необходимости

4. Проверка настройки:
   ```bash
   flutter run
   ```

## Структура проекта

### Организация директорий

```
lib/
├── config/         # Конфигурационные файлы
├── models/         # Модели данных
├── screens/        # Экраны приложения
├── services/       # Сервисы (API, Firebase)
├── utils/          # Утилиты и хелперы
└── widgets/        # Переиспользуемые виджеты
```

### Ключевые файлы

- `lib/main.dart`: Точка входа в приложение
- `lib/firebase_options.dart`: Конфигурация Firebase
- `lib/config/api_keys.dart`: API ключи (не включать в git)
- `lib/models/card_model.dart`: Модель карточки для изучения

### Соглашения по именованию

1. Файлы:
   - Нижний регистр с подчеркиваниями: `user_profile_screen.dart`
   - Суффикс `_screen` для экранов
   - Суффикс `_model` для моделей
   - Суффикс `_service` для сервисов

2. Классы:
   - PascalCase: `UserProfileScreen`
   - Суффикс `Screen` для экранов
   - Суффикс `Model` для моделей
   - Суффикс `Service` для сервисов

3. Переменные и методы:
   - camelCase: `getUserProfile()`
   - Понятные и описательные имена
   - Избегать сокращений

## Рабочий процесс

### Создание новых компонентов

1. Экраны:
   ```dart
   class NewScreen extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('New Screen')),
         body: // Содержимое экрана
       );
     }
   }
   ```

2. Виджеты:
   ```dart
   class CustomWidget extends StatelessWidget {
     final String title;
     
     const CustomWidget({
       Key? key,
       required this.title,
     }) : super(key: key);

     @override
     Widget build(BuildContext context) {
       return // Реализация виджета
     }
   }
   ```

### Работа с Firebase

1. Firestore:
   ```dart
   // Получение данных
   final snapshot = await FirebaseFirestore.instance
       .collection('users')
       .doc(userId)
       .get();

   // Сохранение данных
   await FirebaseFirestore.instance
       .collection('users')
       .doc(userId)
       .set(data);
   ```

2. Authentication:
   ```dart
   // Проверка состояния аутентификации
   FirebaseAuth.instance.authStateChanges().listen((User? user) {
     if (user != null) {
       // Пользователь вошел
     } else {
       // Пользователь вышел
     }
   });
   ```

### Работа с OpenAI API

1. Использование ApiService:
   ```dart
   final apiService = ApiService();
   
   // Упрощение текста
   final simplifiedText = await apiService.simplifyText(originalText);
   
   // Получение информации о слове
   final wordInfo = await apiService.getWordInfo(word, context);
   ```

2. Обработка ошибок:
   ```dart
   try {
     final result = await apiService.someMethod();
   } catch (e) {
     print('API error: $e');
     // Обработка ошибки
   }
   ```

### Отладка и профилирование

1. Логирование:
   ```dart
   print('Debug: $someValue');  // Только для разработки
   debugPrint('Info: $someInfo');  // Flutter-специфичное логирование
   ```

2. Performance Profiling:
   - Используйте Flutter DevTools
   - Следите за перестроениями виджетов
   - Оптимизируйте запросы к API и базе данных

## Стандарты кода

### Форматирование

1. Следуйте официальному стилю Dart:
   ```bash
   dart format .
   ```

2. Отступы:
   - Используйте 2 пробела
   - Не используйте табуляцию

3. Длина строки:
   - Максимум 80 символов
   - Разбивайте длинные строки логически

### Комментарии

1. Документация классов и методов:
   ```dart
   /// Представляет карточку для изучения слова.
   ///
   /// Содержит информацию о слове, его определении и примерах использования.
   class CardModel {
     /// Создает новую карточку.
     ///
     /// [word] - изучаемое слово
     /// [definition] - определение слова
     CardModel({required this.word, required this.definition});
   }
   ```

2. Комментарии в коде:
   - Только для сложной логики
   - Объясняйте "почему", а не "что"
   - Держите комментарии актуальными

### Лучшие практики

1. State Management:
   - Используйте StatefulWidget только когда необходимо
   - Выносите логику в отдельные классы
   - Избегайте глобального состояния

2. Производительность:
   - Используйте const конструкторы
   - Кэшируйте значения где возможно
   - Оптимизируйте списки с помощью ListView.builder

3. Обработка ошибок:
   - Всегда обрабатывайте исключения
   - Предоставляйте понятные сообщения об ошибках
   - Логируйте ошибки для отладки

## Тестирование

1. Unit Tests:
   ```dart
   void main() {
     test('CardModel creation', () {
       final card = CardModel(word: 'test', definition: 'a test word');
       expect(card.word, equals('test'));
     });
   }
   ```

2. Widget Tests:
   ```dart
   void main() {
     testWidgets('MyWidget test', (WidgetTester tester) async {
       await tester.pumpWidget(MyWidget());
       expect(find.text('Hello'), findsOneWidget);
     });
   }
   ```

## Связанные документы

- [project-map.md](project-map.md) - Общая карта проекта
- [current-state.md](current-state.md) - Текущее состояние проекта
- [components-map.md](components-map.md) - Карта компонентов
- [entities.md](entities.md) - Описание сущностей