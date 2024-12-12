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
      final messages = [
        {
          'role': 'system',
          'content': '''You are tasked with extracting a collocation (extractedPhrase) involving the word `$word` from the sentence `$sentence`. Follow these steps carefully:

1. Identify the minimal collocation (extractedPhrase):  
   Look at the sentence `$sentence` and find the simplest verb-noun or noun-adjective combination that includes `$word`. This phrase should represent how the word is commonly used in context. Exclude any unnecessary descriptive words, focusing only on the most essential part.

2. Restate the full original sentence:  
   Include the original sentence `$sentence` exactly as it was provided, without any additional text.

3. Provide a brief definition (briefDefinition):  
   Give a concise definition (no more than 5 words) of `$word` using basic, simple, common, everyday vocabulary. Ensure the definition explains the word's meaning clearly in this specific context. The definition should be immediately clear to a general audience.

4. List three common collocations (commonCollocations):  
   Provide three additional common collocations that typically include `$word`. These collocations should be separated by commas.

5. Create a new sentence (newSentence) using the extracted collocation (extractedPhrase):  
   Write a new, simple sentence that uses the EXACT extracted collocation (extractedPhrase) in a meaningful context. This sentence should help reinforce the typical usage of the collocation.

Output Format (Strictly adhere to this):

1. The collocation or phrase you extracted from the sentence (must be at least two words).
2. The full original sentence.
3. A brief definition (up to 5 words) of the word `$word`.
4. Three common collocations, separated by commas.
5. A new simple sentence using the exact extracted collocation.

Example Input:

- Sentence: "John had to take a deep breath before giving his speech."
- Word: "breath"

Example Output:

take a deep breath
John had to take a deep breath before giving his speech.
inhale and exhale slowly
catch your breath, hold your breath, deep breath
Remember to take a deep breath when you're nervous.

Additional Notes:

- Focus on extracting a collocation that is both grammatically correct and commonly used in everyday language.
- Make sure to strictly follow the output format without adding any extra lines or text outside of the specified format.
- Ensure the definition is simple and concise, using common, easy-to-understand language.
- For the additional collocations, make sure they are practical and commonly used with `$word`.
- The example sentence MUST use the exact extracted collocation, not just the target word.
- Do not include any labels or prefixes (like "Full original sentence:", "Brief definition:", etc.) in your output.'''
        },
        {
          'role': 'user',
          'content': 'Provide information for the word "$word" in the sentence: "$sentence"'
        }
      ];

      print('Sending request to ChatGPT with the following content:');
      print(json.encode(messages));

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(),
        body: jsonEncode({
          'model': _model,
          'messages': messages,
        })
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final lines = content.split('\n');
        
        Map<String, String> result = {};
        final keys = ['extracted_phrase', 'original_sentence', 'brief_definition', 'common_collocations', 'example_sentence'];
        
        for (int i = 0; i < lines.length && i < keys.length; i++) {
          String cleanedLine = _cleanLine(lines[i]);
          if (cleanedLine.isNotEmpty) {
            result[keys[i]] = cleanedLine;
          }
        }

        if (result.length == 5) {
          return result;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to get word information');
      }
    } catch (e) {
      print("Error in getWordInfo: $e");
      throw Exception('Failed to get word information');
    }
  }

  String _cleanLine(String line) {
    return line
      .replaceFirst(RegExp(r'^\d+\.\s*'), '')
      .replaceAll(RegExp(r'^(Full original sentence|Brief definition|Common collocations|New sentence):\s*'), '')
      .replaceAll(RegExp(r'["""]'), '')
      .trim();
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $openAiApiKey'
    };
  }
}
