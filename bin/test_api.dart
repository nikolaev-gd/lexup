import 'package:lexup/services/api_service.dart';

void main() async {
  final apiService = ApiService();
  final word = 'robot';
  final sentence = "Here, we chose the jellyfish's shape as inspiration for increased energy storage in a simple and efficient swimming robot.";

  try {
    final result = await apiService.getWordInfo(word, sentence);
    print('Extracted phrase: ${result['extracted_phrase']}');
    print('Original sentence: ${result['original_sentence']}');
    print('Brief definition: ${result['brief_definition']}');
    print('Common collocations: ${result['common_collocations']}');
    print('Example sentence: ${result['example_sentence']}');
  } catch (e) {
    print('Error: $e');
  }
}
