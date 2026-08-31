import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chat_application/models/message_model.dart';
import 'package:chat_application/widget/chat_bubble.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Send message flow integration test', (tester) async {
    final List<MessageModel> messages = [];
    final textController = TextEditingController();

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) => ChatBubble(
                      message: messages[index],
                      isMe: messages[index].isMe,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('message_input'),
                          controller: textController,
                        ),
                      ),
                      IconButton(
                        key: const Key('send_btn'),
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (textController.text.isNotEmpty) {
                            setState(() {
                              messages.add(MessageModel(
                                id: 'm1',
                                text: textController.text,
                                time: '12:00 PM',
                                isMe: true,
                              ));
                              textController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ));

    await tester.enterText(find.byKey(const Key('message_input')), 'Testing integration send');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('send_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Testing integration send'), findsOneWidget);
    expect(find.byType(ChatBubble), findsOneWidget);
  });
}
