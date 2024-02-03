import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:chatbot_project/consts.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _openAI = OpenAI.instance.build(
    token: OPENAP_API_KEY, 
    baseOption: HttpSetup(
      receiveTimeout: const Duration(
        seconds: 5
      ),
    ),
    enableLog: true,  
  );

  final ChatUser _currentUser = ChatUser(
    id: '1',
    firstName: 'Munseop',
    lastName: 'Youn'
  );

  final ChatUser _gptChatUser = ChatUser(
    id: '2',
    firstName: 'Chat',
    lastName: 'GPT'
  );

  List<ChatMessage> _messages = <ChatMessage>[];
  List<ChatUser> _typingUser = <ChatUser>[];
  bool _isWaitingForResponse = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 166, 125, 1),
        title: const Text(
          'GPT Chat',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: DashChat(
        currentUser: _currentUser,
        messageOptions: const MessageOptions(
          currentUserContainerColor: Colors.black,
          containerColor: Color.fromRGBO(0, 166, 126, 1),
          textColor: Colors.white,
        ),
        onSend: (ChatMessage m){
          getChatResponse(m);
        },
        messages: _messages,
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async{
    if (_isWaitingForResponse) {
      // If we are already waiting for a response, we ignore this message
      return;
    }
    _isWaitingForResponse = true;

    setState(() {
      _messages.insert(0, m);
      _typingUser.add(_gptChatUser);
    });

    // We wait for a short delay before sending the request
    await Future.delayed(Duration(seconds: 2));

    List<Map<String, dynamic>> _messagesHistory = _messages.reversed.map((m) {
      if (m.user == _currentUser) {
        return {"role": "user", "content": m.text};
      } else{
        return {"role": "assistant", "content": m.text};
      }
    }).toList();
    final request = ChatCompleteText(
      model: GptTurbo0301ChatModel(), 
      messages: _messagesHistory, 
      maxToken: 200
    );
    final response = await _openAI.onChatCompletion(request: request);
    for (var element in response!.choices) {
      if (element.message !=null) {
        setState(() {
          _messages.insert(0, ChatMessage(user: _gptChatUser, createdAt: DateTime.now(), text: element.message!.content));
        });
      }
    }
    setState(() {
      _typingUser.remove(_gptChatUser);
    });

    _isWaitingForResponse = false;
  }
}
