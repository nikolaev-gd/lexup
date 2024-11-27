import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lexup/config/api_keys.dart';

class ApiService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'chatgpt-4o-latest';

  Future<bool> checkApiConnection() async {
    print("Checking API connection");
    print("API Key: ${openAiApiKey.substring(0, 5)}...");
    if (openAiApiKey.isEmpty) {
      print("API key is empty");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(),
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': 'Hello, this is a test message.'}
          ]
        })
      );

      print("API response status code: ${response.statusCode}");
      print("API response body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("Error checking API connection: $e");
      return false;
    }
  }

  Future<String> simplifyText(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(),
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that simplifies text.'
            },
            {
              'role': 'user',
              'content': 'Simplify the following text, making it easier to understand while preserving the main ideas: $text'
            }
          ]
        })
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        print("Error response: ${response.body}");
        throw Exception('Failed to simplify text');
      }
    } catch (e) {
      print("Error in simplifyText: $e");
      throw Exception('Failed to simplify text');
    }
  }

  Future<Map<String, String>> getWordInfo(String word, String sentence) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(),
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a helpful assistant that provides information about words in context.
              Provide the following information:
              1. Extracted phrase (collocation or minimal context)
              2. Original sentence
              3. Brief definition (up to 5 words)
              4. Three common collocations
              5. A new simple sentence using the extracted phrase'''
            },
            {
              'role': 'user',
              'content': 'Provide information for the word "$word" in the sentence: "$sentence"'
            }
          ]
        })
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final lines = content.split('\n');
        
        Map<String, String> cardInfo = {};
        for (var line in lines) {
          if (line.startsWith('1.')) cardInfo['extracted_phrase'] = line.substring(3);
          if (line.startsWith('2.')) cardInfo['original_sentence'] = line.substring(3);
          if (line.startsWith('3.')) cardInfo['brief_definition'] = line.substring(3);
          if (line.startsWith('4.')) cardInfo['common_collocations'] = line.substring(3);
          if (line.startsWith('5.')) cardInfo['example_sentence'] = line.substring(3);
        }
        return cardInfo;
      } else {
        throw Exception('Failed to get word information');
      }
    } catch (e) {
      print("Error in getWordInfo: $e");
      throw Exception('Failed to get word information');
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $openAiApiKey'
    };
  }
}
