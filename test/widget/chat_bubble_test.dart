import 'package:chat_application/models/message_model.dart';
import 'package:chat_application/widget/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatBubble Widget Tests', () {
    MessageModel createTestMessage({
      String id = 'msg_1',
      String senderId = 'user_1',
      String receiverId = 'user_2',
      String text = 'Hello Chattrix!',
      String time = '10:45 AM',
      bool isMe = true,
      bool isRead = false,
      bool isSystem = false,
      String? replyTo,
      String? replyAuthor,
    }) {
      return MessageModel(
        id: id,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        time: time,
        timestamp: DateTime.now(),
        isMe: isMe,
        isRead: isRead,
        isSystem: isSystem,
        replyTo: replyTo,
        replyAuthor: replyAuthor,
      );
    }

    Widget createTestApp(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    testWidgets('renders outgoing message correctly with right alignment and sent checkmark', (tester) async {
      final message = createTestMessage(
        text: 'Hello from sender!',
        time: '11:00 AM',
        isMe: true,
        isRead: false,
      );

      await tester.pumpWidget(createTestApp(
        ChatBubble(
          message: message,
          isMe: true,
        ),
      ));

      // Verify text and time are visible
      expect(find.text('Hello from sender!'), findsOneWidget);
      expect(find.text('11:00 AM'), findsOneWidget);

      // Verify sent status icon
      expect(find.byKey(const Key('chat_bubble_status_sent')), findsOneWidget);
      expect(find.byKey(const Key('chat_bubble_status_seen')), findsNothing);

      // Verify container alignment
      final alignFinder = find.byType(Align);
      expect(alignFinder, findsOneWidget);
      final Align alignWidget = tester.widget(alignFinder);
      expect(alignWidget.alignment, Alignment.centerRight);
    });

    testWidgets('renders incoming message correctly with left alignment and no status checkmarks', (tester) async {
      final message = createTestMessage(
        text: 'Hello from recipient!',
        time: '11:02 AM',
        isMe: false,
      );

      await tester.pumpWidget(createTestApp(
        ChatBubble(
          message: message,
          isMe: false,
        ),
      ));

      // Verify text and time are visible
      expect(find.text('Hello from recipient!'), findsOneWidget);
      expect(find.text('11:02 AM'), findsOneWidget);

      // Verify status icons are not displayed for incoming message
      expect(find.byKey(const Key('chat_bubble_status_sent')), findsNothing);
      expect(find.byKey(const Key('chat_bubble_status_seen')), findsNothing);

      // Verify container alignment
      final Align alignWidget = tester.widget(find.byType(Align));
      expect(alignWidget.alignment, Alignment.centerLeft);
    });

    testWidgets('renders blue double checkmark when isRead is true', (tester) async {
      final message = createTestMessage(
        text: 'Read message',
        time: '11:06 AM',
        isMe: true,
        isRead: true,
      );

      await tester.pumpWidget(createTestApp(
        ChatBubble(
          message: message,
          isMe: true,
        ),
      ));

      expect(find.byKey(const Key('chat_bubble_status_seen')), findsOneWidget);
    });

    testWidgets('renders replied message quote when replyTo is present', (tester) async {
      final message = createTestMessage(
        text: 'I agree with you!',
        time: '11:10 AM',
        isMe: true,
        replyTo: 'Shall we meet at 3 PM?',
        replyAuthor: 'Alice',
      );

      await tester.pumpWidget(createTestApp(
        ChatBubble(
          message: message,
          isMe: true,
        ),
      ));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Shall we meet at 3 PM?'), findsOneWidget);
      expect(find.text('I agree with you!'), findsOneWidget);
    });

    testWidgets('renders system announcement bubble properly', (tester) async {
      final message = createTestMessage(
        text: 'Alice created group "Flutter Devs"',
        isSystem: true,
      );

      await tester.pumpWidget(createTestApp(
        ChatBubble(
          message: message,
        ),
      ));

      expect(find.text('Alice created group "Flutter Devs"'), findsOneWidget);
      expect(find.byKey(const Key('chat_bubble_status_sent')), findsNothing);
    });

    testWidgets('triggers onTap and onLongPress callbacks', (tester) async {
      bool tapped = false;
      bool longPressed = false;

      final message = createTestMessage(
        text: 'Tap test message',
        isMe: true,
      );

      await tester.pumpWidget(createTestApp(
        ChatBubble(
          message: message,
          isMe: true,
          onTap: () => tapped = true,
          onLongPress: () => longPressed = true,
        ),
      ));

      // Tap
      await tester.tap(find.text('Tap test message'));
      await tester.pump();
      expect(tapped, isTrue);

      // Long press
      await tester.longPress(find.text('Tap test message'));
      await tester.pump();
      expect(longPressed, isTrue);
    });

    testWidgets('highlights bubble when isSelected is true', (tester) async {
      final message = createTestMessage(text: 'Selected bubble');

      await tester.pumpWidget(createTestApp(
        ChatBubble(
          message: message,
          isSelected: true,
        ),
      ));

      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget(containerFinder);
      expect(container.color, isNotNull);
      expect(container.color, isNot(Colors.transparent));
    });
  });
}
