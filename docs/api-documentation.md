# OpenAI API Documentation - LexUp

Этот документ описывает использование OpenAI API в проекте LexUp, включая конфигурацию, промпты и лучшие практики.

## Общая информация

### Конфигурация API
- **Базовый URL**: https://api.openai.com/v1/chat/completions
- **Используемая модель**: chatgpt-4o-latest
- **Endpoint**: Chat Completions API

### Аутентификация
```dart
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $openAiApiKey'
}
```

### Основные операции
1. Проверка соединения с API
2. Упрощение текста
3. Получение информации о словах

## Промпты

### Структура промптов

1. Системный промпт (role: 'system'):
   - Определяет роль и поведение модели
   - Устанавливает формат ответа
   - Задает ограничения и требования

2. Пользовательский промпт (role: 'user'):
   - Содержит конкретный запрос
   - Включает необходимые данные

### Примеры промптов

#### 1. Упрощение текста

```json
{
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful assistant that simplifies text."
    },
    {
      "role": "user",
      "content": "Simplify the following text, making it easier to understand while preserving the main ideas: [text]"
    }
  ]
}
```

✅ Успешный результат:
- Сохраняет основные идеи
- Использует более простые конструкции
- Поддерживает логическую структуру

❌ Неуспешный результат:
- Искажает смысл
- Чрезмерно упрощает
- Теряет важные детали

#### 2. Получение информации о слове

```json
{
  "messages": [
    {
      "role": "system",
      "content": "You are tasked with extracting a collocation... [detailed instructions]"
    },
    {
      "role": "user",
      "content": "Provide information for the word \"[word]\" in the sentence: \"[sentence]\""
    }
  ]
}
```

✅ Успешный формат ответа:
```
take a deep breath
John had to take a deep breath before giving his speech.
inhale and exhale slowly
catch your breath, hold your breath, deep breath
Remember to take a deep breath when you're nervous.
```

❌ Неуспешный формат:
- Нарушение структуры ответа
- Добавление лишних меток или пояснений
- Неполные или избыточные данные

## Оптимизация

### Кэширование ответов

1. Рекомендуемые стратегии:
   - Кэширование упрощенных текстов
   - Сохранение информации о часто используемых словах
   - Периодическое обновление кэша

2. Реализация:
```dart
// TODO: Добавить примеры реализации кэширования
```

### Обработка ошибок

1. Проверка соединения:
```dart
Future<bool> checkApiConnection() async {
  try {
    // Отправка тестового запроса
    final response = await http.post(...);
    return response.statusCode == 200;
  } catch (e) {
    print("Error checking API connection: $e");
    return false;
  }
}
```

2. Обработка ошибок API:
```dart
if (response.statusCode == 200) {
  // Обработка успешного ответа
} else {
  print("Error response: ${response.body}");
  throw Exception('Failed to process request');
}
```

### Стратегии минимизации затрат

1. Оптимизация запросов:
   - Минимизация количества запросов
   - Использование кэширования
   - Проверка необходимости запроса

2. Контроль использования:
   - Мониторинг количества запросов
   - Отслеживание затрат
   - Установка лимитов

### Улучшение качества ответов

1. Системные промпты:
   - Четкие инструкции
   - Конкретные требования к формату
   - Примеры ожидаемых результатов

2. Валидация ответов:
   - Проверка формата
   - Очистка от лишних данных
   - Обработка краевых случаев

## Примеры использования

### Упрощение текста

```dart
final apiService = ApiService();

try {
  final simplifiedText = await apiService.simplifyText(originalText);
  // Использование упрощенного текста
} catch (e) {
  // Обработка ошибки
}
```

### Получение информации о слове

```dart
try {
  final wordInfo = await apiService.getWordInfo(word, sentence);
  // wordInfo содержит:
  // - extracted_phrase
  // - original_sentence
  // - brief_definition
  // - common_collocations
  // - example_sentence
} catch (e) {
  // Обработка ошибки
}
```

## Рекомендации по использованию

1. Проверка API:
   - Всегда проверяйте соединение перед использованием
   - Обрабатывайте ошибки соединения
   - Предоставляйте понятную обратную связь пользователю

2. Форматирование запросов:
   - Следуйте установленной структуре промптов
   - Проверяйте входные данные
   - Валидируйте ответы API

3. Оптимизация:
   - Используйте кэширование где возможно
   - Минимизируйте количество запросов
   - Следите за качеством ответов

## Связанные документы

- [current-state.md](current-state.md) - Текущее состояние проекта
- [components-map.md](components-map.md) - Карта компонентов системы
- [development-guide.md](development-guide.md) - Руководство по разработке
