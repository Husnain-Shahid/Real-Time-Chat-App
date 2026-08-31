import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../mocks/firebase_mocks.dart';

void main() {
  group('Firebase & Firestore Response Mocking Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockMessagesCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockMessagesCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(() => mockFirestore.collection('messages')).thenReturn(mockMessagesCollection);
    });

    test('mocks Firestore document retrieval response', () async {
      final mockData = {
        'id': 'msg_abc',
        'text': 'Mocked Firebase Message',
        'senderId': 'user_1',
        'time': '12:00 PM',
        'isRead': true,
      };

      when(() => mockMessagesCollection.doc('msg_abc')).thenReturn(mockDocRef);
      when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(true);
      when(() => mockDocSnapshot.id).thenReturn('msg_abc');
      when(() => mockDocSnapshot.data()).thenReturn(mockData);

      // Perform read
      final doc = await mockFirestore.collection('messages').doc('msg_abc').get();

      expect(doc.exists, isTrue);
      expect(doc.id, 'msg_abc');
      expect(doc.data()?['text'], 'Mocked Firebase Message');
      expect(doc.data()?['isRead'], isTrue);
    });

    test('mocks Firestore query snapshots and streaming updates', () async {
      final mockMessage1 = {
        'id': 'msg_1',
        'text': 'First message',
        'senderId': 'user_1',
      };
      final mockMessage2 = {
        'id': 'msg_2',
        'text': 'Second message',
        'senderId': 'user_2',
      };

      final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(() => mockDoc1.id).thenReturn('msg_1');
      when(() => mockDoc1.data()).thenReturn(mockMessage1);
      when(() => mockDoc2.id).thenReturn('msg_2');
      when(() => mockDoc2.data()).thenReturn(mockMessage2);

      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(() => mockMessagesCollection.snapshots())
          .thenAnswer((_) => Stream.value(mockQuerySnapshot));

      // Listen to snapshots stream
      final snapshotStream = mockFirestore.collection('messages').snapshots();
      final emittedSnapshot = await snapshotStream.first;

      expect(emittedSnapshot.docs.length, 2);
      expect(emittedSnapshot.docs[0].data()['text'], 'First message');
      expect(emittedSnapshot.docs[1].data()['text'], 'Second message');
    });

    test('mocks Firestore message creation / add operation', () async {
      final newMessage = {
        'text': 'New chat message',
        'senderId': 'user_current',
        'timestamp': '2026-08-31T12:00:00Z',
      };

      when(() => mockDocRef.id).thenReturn('new_msg_id');
      when(() => mockMessagesCollection.add(newMessage))
          .thenAnswer((_) async => mockDocRef);

      final resultDocRef = await mockFirestore.collection('messages').add(newMessage);

      expect(resultDocRef.id, 'new_msg_id');
      verify(() => mockMessagesCollection.add(newMessage)).called(1);
    });
  });
}
