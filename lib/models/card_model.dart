import 'package:flutter/foundation.dart';

class CardModel {
  final String word;
  final String extractedPhrase;
  final String originalSentence;
  final String briefDefinition;
  final String commonCollocations;
  final String exampleSentence;

  CardModel({
    required this.word,
    required this.extractedPhrase,
    required this.originalSentence,
    required this.briefDefinition,
    required this.commonCollocations,
    required this.exampleSentence,
  });

  factory CardModel.fromMap(Map<String, dynamic> map) {
    final cardModel = CardModel(
      word: (map['word'] as String?) ?? '',
      extractedPhrase: (map['extracted_phrase'] as String?) ?? '',
      originalSentence: (map['original_sentence'] as String?) ?? '',
      briefDefinition: (map['brief_definition'] as String?) ?? '',
      commonCollocations: (map['common_collocations'] as String?) ?? '',
      exampleSentence: (map['example_sentence'] as String?) ?? '',
    );

    if (kDebugMode) {
      print('Creating CardModel:');
      print('word: ${cardModel.word}');
      print('extractedPhrase: ${cardModel.extractedPhrase}');
      print('originalSentence: ${cardModel.originalSentence}');
      print('briefDefinition: ${cardModel.briefDefinition}');
      print('commonCollocations: ${cardModel.commonCollocations}');
      print('exampleSentence: ${cardModel.exampleSentence}');
    }

    return cardModel;
  }

  Map<String, String> toMap() {
    return {
      'word': word,
      'extracted_phrase': extractedPhrase,
      'original_sentence': originalSentence,
      'brief_definition': briefDefinition,
      'common_collocations': commonCollocations,
      'example_sentence': exampleSentence,
    };
  }

  @override
  String toString() {
    return 'CardModel(word: $word, extractedPhrase: $extractedPhrase)';
  }
}
