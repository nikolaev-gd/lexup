# Интеграция Firebase в проект Lexup

## План интеграции Firebase

1. Настройка Firebase:
   - [x] Создание проекта Firebase
   - [x] Настройка Firebase Authentication
   - [ ] Настройка Firestore или Realtime Database
   - [x] Интеграция Firebase SDK в Flutter проект

2. Создание серверной части:
   - [ ] Настройка Firebase Cloud Functions
   - [ ] Создание базовых облачных функций

3. Интеграция в Flutter приложении:
   - [x] Реализация аутентификации пользователей с Firebase
   - [ ] Создание сервисов для работы с Firebase

4. Реализация основных функций:
   - [ ] Добавление нового слова/фразы
   - [ ] Поиск слов/фраз
   - [ ] Генерация базовых рекомендаций

5. Оптимизация и тестирование:
   - [ ] Настройка кэширования
   - [ ] Проведение нагрузочного тестирования
   - [ ] Оптимизация запросов

6. Безопасность:
   - [ ] Настройка правил безопасности в Firebase

## Текущий прогресс

1. [x] Создание проекта Firebase и настройка Firebase CLI
2. [x] Интеграция Firebase с Flutter проектом
3. [x] Настройка Firebase Authentication для регистрации и входа пользователей
4. [x] Добавление входа через Google

## Подробное описание выполненных шагов

### 1. Обновление pubspec.yaml

Добавлены следующие зависимости:

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  firebase_ui_auth: ^1.10.0
  firebase_ui_oauth_google: ^1.2.14
```

### 2. Обновление main.dart

1. Добавлены импорты для работы с Firebase и Google Sign-In:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as firebase_ui;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'firebase_options.dart';
```

2. Инициализация Firebase в функции main():

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

3. Реализация AuthGate для управления состоянием аутентификации:

```dart
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return firebase_ui.SignInScreen(
            providers: [
              firebase_ui.EmailAuthProvider(),
              GoogleProvider(clientId: "1091391650743-bo683vtbjud52umtcbofbahm70sjnqo1.apps.googleusercontent.com"),
            ],
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/lexup_logo.png'),
                ),
              );
            },
          );
        }

        return HomePage();
      },
    );
  }
}
```

### 3. Настройка Google Sign-In в Firebase Console

1. В Firebase Console выбран проект Lexup.
2. В разделе Authentication включен провайдер Google.
3. Получен Web client ID: 1091391650743-bo683vtbjud52umtcbofbahm70sjnqo1.apps.googleusercontent.com

### 4. Установка зависимостей

Выполнена команда `flutter pub get` для установки новых зависимостей.

## Возникшие проблемы и их решения

### Проблема с версиями пакетов

При выполнении `flutter pub get` было замечено, что некоторые пакеты имеют более новые версии:

```
42 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
```

**Решение:** На данный момент это предупреждение не влияет на функциональность приложения. В будущем рекомендуется регулярно обновлять зависимости до последних совместимых версий для обеспечения безопасности и использования новых функций.

### Потенциальная проблема с Web client ID

Если возникнут проблемы с входом через Google, убедитесь, что используется правильный Web client ID и что он соответствует настройкам в Firebase Console.

## Следующие шаги

1. Тестирование функциональности входа через email и Google.
2. Реализация выхода из аккаунта.
3. Создание пользовательского интерфейса для отображения информации о вошедшем пользователе.
4. Настройка Firestore или Realtime Database для хранения пользовательских данных.
5. Реализация основных функций приложения (добавление слов, поиск, рекомендации).

## Полезные ссылки

- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Google Sign-In для Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase UI для Flutter](https://github.com/firebase/FirebaseUI-Flutter)
