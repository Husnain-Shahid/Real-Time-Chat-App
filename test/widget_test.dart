import 'package:chat_application/models/message_model.dart';
import 'package:chat_application/widget/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test: ChatBubble renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatBubble(
            message: MessageModel(
              id: 'test_1',
              text: 'Smoke test message',
              time: '12:00 PM',
              isMe: true,
            ),
            isMe: true,
          ),
        ),
      ),
    );

    expect(find.text('Smoke test message'), findsOneWidget);
  });
}
