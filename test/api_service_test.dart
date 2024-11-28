import 'package:flutter_test/flutter_test.dart';
import 'package:lexup/services/api_service.dart';

void main() {
  group('ApiService', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    test('getWordInfo returns correct format', () async {
      final word = 'example';
      final sentence = 'This is an example sentence to test the API.';

      final result = await apiService.getWordInfo(word, sentence);

      expect(result, isA<Map<String, String>>());
      expect(result.keys, containsAll(['extracted_phrase', 'original_sentence', 'brief_definition', 'common_collocations', 'example_sentence']));
      expect(result['original_sentence'], equals(sentence));
    });

    test('getWordInfo handles different words and sentences', () async {
      final testCases = [
        {'word': 'deep', 'sentence': 'The ocean is very deep in some places.'},
        {'word': 'run', 'sentence': 'I like to run in the park every morning.'},
        {'word': 'bright', 'sentence': 'The sun is extremely bright today.'},
      ];

      for (var testCase in testCases) {
        final result = await apiService.getWordInfo(testCase['word']!, testCase['sentence']!);

        expect(result, isA<Map<String, String>>());
        expect(result.keys, containsAll(['extracted_phrase', 'original_sentence', 'brief_definition', 'common_collocations', 'example_sentence']));
        expect(result['original_sentence'], equals(testCase['sentence']));
        expect(result['extracted_phrase'], contains(testCase['word']));
      }
    });
  });
}
