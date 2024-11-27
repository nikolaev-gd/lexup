import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> loadSimplifiedText(String documentId) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User is null");
      return null;
    }

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('content')
          .doc(documentId)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data()?['simplified_text'] as String?;
      } else {
        print("Document does not exist");
        return null;
      }
    } catch (e) {
      print("Error loading simplified text: $e");
      return null;
    }
  }

  Future<void> saveSimplifiedText(String documentId, String simplifiedText) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User is null");
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('content')
          .doc(documentId)
          .update({'simplified_text': simplifiedText});
      print("Simplified text saved to Firestore");
    } catch (e) {
      print("Error saving simplified text: $e");
      throw e;
    }
  }

  Future<void> saveCard(String documentId, String word, Map<String, String> cardInfo) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User is null");
      throw Exception('You must be logged in to save cards.');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('content')
          .doc(documentId)
          .collection('cards')
          .add({
        'word': word,
        ...cardInfo,
        'created_at': FieldValue.serverTimestamp(),
      });

      print("Card saved successfully");
    } catch (e) {
      print("Error saving card: $e");
      throw e;
    }
  }

  Future<void> deleteCard(String documentId, String cardId) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User is null");
      throw Exception('You must be logged in to delete cards.');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('content')
          .doc(documentId)
          .collection('cards')
          .doc(cardId)
          .delete();

      print("Card deleted successfully");
    } catch (e) {
      print("Error deleting card: $e");
      throw e;
    }
  }

  Stream<QuerySnapshot> getSavedCardsStream(String documentId) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('content')
        .doc(documentId)
        .collection('cards')
        .orderBy('created_at', descending: false)
        .snapshots();
  }
}
