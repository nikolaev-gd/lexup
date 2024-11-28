import 'package:lexup/services/api_service.dart';

void main() async {
  final apiService = ApiService();
  final sentence = "Today's robot energy systems are usually designed for one main purpose. To make robots run longer, engineers must either use higher energy density batteries, like lithium-ion ones (a common choice), or add bigger batteries. A new approach involves combining the energy-storing battery with the robot's structure, so the battery becomes part of the robot's body. This increases energy capacity while reducing unnecessary weight and drag. Nature uses a similar strategy, where parts serve multiple roles. For example, jellyfish have a material called *mesoglea,* which acts like an elastic skeleton, helps reshape their bodies, and stores energy to power their muscles for movement and feeding.";
  final word = "density";

  try {
    final result = await apiService.getWordInfo(word, sentence);
    print('\nResults:');
    print('Extracted Phrase: ${result['extracted_phrase']}');
    print('Original Sentence: ${result['original_sentence']}');
    print('Brief Definition: ${result['brief_definition']}');
    print('Common Collocations: ${result['common_collocations']}');
    print('Example Sentence: ${result['example_sentence']}');
  } catch (e) {
    print('Error: $e');
  }
}
