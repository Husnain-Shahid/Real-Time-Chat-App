import 'package:chat_application/models/message_model.dart';
import 'package:chat_application/widget/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test Chat Screen Harness representing the message send UI flow.
class TestChatScreenHarness extends StatefulWidget {
  final Future<void> Function(String text)? onSendMessage;

  const TestChatScreenHarness({super.key, this.onSendMessage});

  @override
  State<TestChatScreenHarness> createState() => _TestChatScreenHarnessState();
}

class _TestChatScreenHarnessState extends State<TestChatScreenHarness> {
  final TextEditingController _textController = TextEditingController();
  final List<MessageModel> _messages = [
    MessageModel(
      id: 'msg_initial',
      senderId: 'receiver_1',
      receiverId: 'me',
      text: 'Hey! Are you ready for testing?',
      time: '12:00 PM',
      isMe: false,
    ),
  ];

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final newMessage = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      receiverId: 'receiver_1',
      text: text,
      time: '12:01 PM',
      isMe: true,
    );

    setState(() {
      _messages.add(newMessage);
      _textController.clear();
    });

    if (widget.onSendMessage != null) {
      await widget.onSendMessage!(text);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Contact'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              key: const Key('chat_message_list'),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(
                  key: ValueKey(message.id),
                  message: message,
                  isMe: message.isMe,
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('chat_input_field'),
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('chat_send_button'),
                  icon: const Icon(Icons.send, color: Color(0xFF0078FF)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Send Message Flow Integration Test', () {
    testWidgets('user types message, sends it, verifies UI update and input clearing', (tester) async {
      String? sentMessageText;

      await tester.pumpWidget(MaterialApp(
        home: TestChatScreenHarness(
          onSendMessage: (text) async {
            sentMessageText = text;
          },
        ),
      ));

      // 1. Initial State: Initial incoming message is displayed
      expect(find.text('Hey! Are you ready for testing?'), findsOneWidget);
      expect(find.text('Hello integration test message!'), findsNothing);

      final inputFinder = find.byKey(const Key('chat_input_field'));
      final sendButtonFinder = find.byKey(const Key('chat_send_button'));

      expect(inputFinder, findsOneWidget);
      expect(sendButtonFinder, findsOneWidget);

      // 2. User enters text into the message input field
      await tester.enterText(inputFinder, 'Hello integration test message!');
      await tester.pump();

      expect(find.text('Hello integration test message!'), findsOneWidget);

      // 3. User taps the Send button
      await tester.tap(sendButtonFinder);
      await tester.pumpAndSettle();

      // 4. Assert: Input field is now cleared
      final TextField inputWidget = tester.widget(inputFinder);
      expect(inputWidget.controller?.text, isEmpty);

      // 5. Assert: Message was passed to callback/backend
      expect(sentMessageText, equals('Hello integration test message!'));

      // 6. Assert: Sent message bubble appears in conversation list
      expect(find.text('Hello integration test message!'), findsOneWidget);
      expect(find.byKey(const Key('chat_bubble_status_sent')), findsOneWidget);

      // 7. Verify both initial and new message are in the list
      expect(find.byType(ChatBubble), findsNWidgets(2));
    });
  });
}
