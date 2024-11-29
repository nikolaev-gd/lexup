# Работа с LLM в проекте LexUp

Этот документ описывает принципы и практики работы с LLM (Large Language Models) в проекте LexUp. Он служит руководством для эффективного взаимодействия с LLM в процессе разработки.

## Основные принципы работы с LLM

### Процесс входа в контекст

1. Изучение документации:
   - Начните с [project-map.md](project-map.md) для общего понимания проекта
   - Изучите [current-state.md](current-state.md) для понимания текущего состояния
   - Ознакомьтесь с [api-documentation.md](api-documentation.md) для понимания работы с OpenAI API
   - Используйте навигацию из project-map.md для углубления в конкретные аспекты

2. Подтверждение понимания:
   - Кратко перескажите задачу своими словами
   - Укажите, какие документы вы изучили
   - Объясните, как вы планируете решить задачу

### Принцип минимальных изменений

1. Перед внесением изменений:
   - Определите минимальный набор необходимых изменений
   - Проверьте, можно ли решить задачу без изменения архитектуры
   - Оцените влияние изменений на существующий код

2. При внесении изменений:
   - Вносите изменения пошагово
   - Получайте подтверждение после каждого значимого изменения
   - Документируйте внесенные изменения

### Процесс подтверждения изменений

1. Предложение изменений:
   - Четко опишите предлагаемые изменения
   - Объясните причины каждого изменения
   - Укажите потенциальные риски

2. Получение подтверждения:
   - Дождитесь явного подтверждения
   - Учтите обратную связь
   - При необходимости скорректируйте план

## Промпты и шаблоны

### Структура эффективного промпта

```markdown
<task>
[Четкое описание задачи]
</task>

<context>
- Текущее состояние: [описание]
- Ограничения: [список]
- Требования: [список]
</context>

<expected_result>
[Описание ожидаемого результата]
</expected_result>
```

### Примеры хороших промптов

1. Для задач с UI:
```markdown
<task>
Добавить кнопку удаления в компонент ContentCard
</task>

<context>
- Компонент находится в lib/widgets/content_card.dart
- Должен запрашивать подтверждение перед удалением
- Необходимо обновить Firestore после удаления
</context>

<expected_result>
Функциональная кнопка удаления с подтверждением
</expected_result>
```

2. Для работы с данными:
```markdown
<task>
Оптимизировать запросы к Firestore в HomeContent
</task>

<context>
- Текущая реализация в lib/screens/home_screen.dart
- Наблюдается задержка при загрузке данных
- Нужно реализовать пагинацию
</context>

<expected_result>
Улучшенная производительность загрузки данных
</expected_result>
```

### Анти-паттерны в промптах

❌ Плохо:
```markdown
Добавь какую-нибудь новую функцию в приложение
```

✅ Хорошо:
```markdown
<task>
Добавить функцию поиска по сохраненным карточкам
</task>

<context>
[Подробное описание контекста]
</context>
```

❌ Плохо:
```markdown
Исправь все ошибки в коде
```

✅ Хорошо:
```markdown
<task>
Исправить ошибку при удалении карточки
</task>

<context>
[Конкретное описание ошибки и условий её возникновения]
</context>
```

## Процесс работы

### Постановка задач

1. Подготовка контекста:
   - Изучите существующую документацию
   - Определите конкретную проблему или потребность
   - Соберите необходимую информацию

2. Формулировка задачи:
   - Используйте структурированный формат
   - Предоставьте конкретный контекст
   - Укажите ожидаемый результат

3. Итеративный процесс:
   - Начните с малого
   - Постепенно уточняйте детали
   - Проверяйте промежуточные результаты

### Проверка результатов

1. Что проверять:
   - Соответствие требованиям
   - Качество кода
   - Влияние на существующий функционал
   - Обновление документации

2. Как проверять:
   - Тестируйте каждое изменение
   - Проверяйте граничные случаи
   - Убедитесь в актуальности документации

### Исправление ошибок

1. При обнаружении ошибки:
   - Четко опишите проблему
   - Предоставьте контекст возникновения
   - Укажите ожидаемое поведение

2. При получении исправления:
   - Проверьте полноту решения
   - Протестируйте связанный функционал
   - Обновите документацию при необходимости

## Рекомендации и лучшие практики

### Общие рекомендации

1. Документация:
   - Поддерживайте документацию в актуальном состоянии
   - Обновляйте связанные документы
   - Следите за консистентностью

2. Коммуникация:
   - Используйте четкие формулировки
   - Предоставляйте полный контекст
   - Задавайте уточняющие вопросы

3. Процесс разработки:
   - Следуйте принципу минимальных изменений
   - Работайте итеративно
   - Регулярно проверяйте результаты

### Работа с ошибками LLM

1. Типичные проблемы:
   - Неполное понимание контекста
   - Генерация некорректного кода
   - Пропуск важных деталей

2. Решения:
   - Уточняйте контекст
   - Проверяйте предложенные решения
   - Разбивайте сложные задачи на простые

### Оптимизация взаимодействия

1. Эффективные промпты:
   - Структурируйте информацию
   - Предоставляйте конкретные примеры
   - Указывайте ограничения

2. Процесс работы:
   - Начинайте с простых задач
   - Постепенно усложняйте
   - Учитывайте предыдущий опыт

## Связанные документы

- [project-map.md](project-map.md) - Карта проекта
- [current-state.md](current-state.md) - Текущее состояние
- [components-map.md](components-map.md) - Карта компонентов
- [entities.md](entities.md) - Описание сущностей
- [api-documentation.md](api-documentation.md) - Документация по работе с OpenAI API