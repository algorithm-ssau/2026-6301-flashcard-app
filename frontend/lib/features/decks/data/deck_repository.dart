import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/network/api_exception.dart';
import 'models/deck_model.dart';

class DeckRepository {
  DeckRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw ApiException(message: 'Not authenticated');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _decksCol =>
      _firestore.collection('users/$_uid/decks');

  DeckModel _mapDeck(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<CardModel>? cards,
  }) {
    final data = doc.data() ?? <String, dynamic>{};
    return DeckModel(
      id: doc.id,
      userId: _uid,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      isPublic: data['is_public'] as bool? ?? false,
      cardCount: (data['card_count'] as int?) ?? cards?.length ?? 0,
      createdAt: data['created_at']?.toString(),
      updatedAt: data['updated_at']?.toString(),
      cards: cards,
    );
  }

  CardModel _mapCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String deckId,
  ) {
    final data = doc.data();
    return CardModel(
      id: doc.id,
      deckId: deckId,
      question: data['question'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      questionImage: data['question_image'] as String?,
      answerImage: data['answer_image'] as String?,
      createdAt: data['created_at']?.toString(),
      updatedAt: data['updated_at']?.toString(),
    );
  }

  Never _handleFirestoreError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      throw ApiException(
        message:
            'Нет доступа к данным колод в Firestore. Проверьте Firestore Rules для пути users/{uid}/decks и вход под тем же пользователем Firebase.',
        serverError: e.message,
      );
    }
    throw ApiException(
      message: 'Ошибка Firestore: ${e.code}',
      serverError: e.message,
    );
  }

  Future<List<DeckModel>> getDecks({int limit = 20, int offset = 0}) async {
    try {
      final snapshot = await _decksCol
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map(_mapDeck).toList();
    } on FirebaseException catch (e) {
      _handleFirestoreError(e);
    }
  }

  Stream<List<DeckModel>> watchDecks({int limit = 100}) {
    return _decksCol
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_mapDeck).toList());
  }

  Future<DeckModel> getDeck(String id) async {
    try {
      final doc = await _decksCol.doc(id).get();
      if (!doc.exists) {
        throw ApiException(message: 'Deck not found');
      }
      final cards = await getCards(id);
      return _mapDeck(doc, cards: cards);
    } on FirebaseException catch (e) {
      _handleFirestoreError(e);
    }
  }

  Stream<DeckModel> watchDeck(String deckId) {
    final deckRef = _decksCol.doc(deckId);
    return deckRef.snapshots().asyncExpand((deckSnap) {
      if (!deckSnap.exists) {
        return Stream<DeckModel>.error(ApiException(message: 'Deck not found'));
      }
      return deckRef
          .collection('cards')
          .orderBy('created_at')
          .snapshots()
          .map((cardsSnapshot) {
        final cards =
            cardsSnapshot.docs.map((doc) => _mapCard(doc, deckId)).toList();
        return _mapDeck(deckSnap, cards: cards);
      });
    });
  }

  Future<DeckModel> createDeck({
    required String title,
    String? description,
    bool isPublic = false,
  }) async {
    final now = DateTime.now().toIso8601String();
    final ref = await _decksCol.add({
      'title': title,
      'description': description,
      'is_public': isPublic,
      'card_count': 0,
      'created_at': now,
      'updated_at': now,
    });
    return getDeck(ref.id);
  }

  Future<DeckModel> updateDeck(
    String id, {
    String? title,
    String? description,
    bool? isPublic,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (isPublic != null) data['is_public'] = isPublic;
    data['updated_at'] = DateTime.now().toIso8601String();
    await _decksCol.doc(id).update(data);
    return getDeck(id);
  }

  Future<void> deleteDeck(String id) async {
    final cardsCol = _decksCol.doc(id).collection('cards');
    final cards = await cardsCol.get();
    for (final doc in cards.docs) {
      await doc.reference.delete();
    }
    await _decksCol.doc(id).delete();
  }

  Future<List<CardModel>> getCards(String deckId,
      {int limit = 100, int offset = 0}) async {
    final snapshot = await _decksCol
        .doc(deckId)
        .collection('cards')
        .orderBy('created_at')
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => _mapCard(doc, deckId)).toList();
  }

  Future<CardModel> createCard(
    String deckId, {
    required String question,
    required String answer,
    String? questionImage,
    String? answerImage,
  }) async {
    final now = DateTime.now().toIso8601String();
    final cardsCol = _decksCol.doc(deckId).collection('cards');
    final ref = await cardsCol.add({
      'question': question,
      'answer': answer,
      'question_image': questionImage,
      'answer_image': answerImage,
      'created_at': now,
      'updated_at': now,
      'repetition': 0,
      'interval': 0,
      'easiness': 2.5,
      'due_date': now,
    });
    await _decksCol.doc(deckId).update({
      'card_count': FieldValue.increment(1),
    });
    final doc = await ref.get();
    final data = doc.data()!;
    return CardModel(
      id: doc.id,
      deckId: deckId,
      question: data['question'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      questionImage: data['question_image'] as String?,
      answerImage: data['answer_image'] as String?,
      createdAt: data['created_at']?.toString(),
      updatedAt: data['updated_at']?.toString(),
    );
  }

  Future<CardModel> updateCard(
    String deckId,
    String cardId, {
    String? question,
    String? answer,
    String? questionImage,
    String? answerImage,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (question != null) data['question'] = question;
    if (answer != null) data['answer'] = answer;
    if (questionImage != null) data['question_image'] = questionImage;
    if (answerImage != null) data['answer_image'] = answerImage;
    final ref = _decksCol.doc(deckId).collection('cards').doc(cardId);
    await ref.update(data);
    final doc = await ref.get();
    if (!doc.exists) {
      throw ApiException(message: 'Card not found');
    }
    final cardData = doc.data()!;
    return CardModel(
      id: doc.id,
      deckId: deckId,
      question: cardData['question'] as String? ?? '',
      answer: cardData['answer'] as String? ?? '',
      questionImage: cardData['question_image'] as String?,
      answerImage: cardData['answer_image'] as String?,
      createdAt: cardData['created_at']?.toString(),
      updatedAt: cardData['updated_at']?.toString(),
    );
  }

  Future<void> deleteCard(String deckId, String cardId) async {
    final deckRef = _decksCol.doc(deckId);
    final cardRef = deckRef.collection('cards').doc(cardId);
    await _firestore.runTransaction((tx) async {
      final deckSnap = await tx.get(deckRef);
      final cardSnap = await tx.get(cardRef);
      if (!cardSnap.exists) return;
      tx.delete(cardRef);
      final current = (deckSnap.data()?['card_count'] as int?) ?? 0;
      tx.update(deckRef, {'card_count': current > 0 ? current - 1 : 0});
    });
  }
}
