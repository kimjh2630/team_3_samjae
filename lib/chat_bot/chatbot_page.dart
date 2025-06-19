import 'package:flutter/material.dart';
import 'package:project/widgets/language_dialog.dart';
import 'package:project/widgets/nav_main_page.dart';
import 'chatbot_message.dart';
import 'chatbot_bubble.dart';
import 'chatbot_input.dart';
import 'chatbot_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final List<ChatbotMessage> _messages = [
    ChatbotMessage(text: 'chatbot.greeting'.tr(), sender: ChatSender.bot),
  ];
  final ChatbotService _service = ChatbotService();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  void _scrollToBottom({bool instant = false}) {
    if (_scrollController.hasClients) {
      if (instant) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
      Future.delayed(
        const Duration(milliseconds: 100),
        () => _scrollToBottom(instant: instant),
      );
    }
  }

  void _sendMessage(String text) async {
    setState(() {
      _messages.add(ChatbotMessage(text: text, sender: ChatSender.user));
      _isLoading = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final langCode = context.locale.languageCode;
    final reply = await _service.sendMessage(text, langCode);

    // 챗봇 답변에서 명령어 감지
    final command = _service.parseCommand(reply);
    final replyAction = command == 'reservation' ? 'hospital' : command;

    setState(() {
      _messages.add(
        ChatbotMessage(
          text: reply,
          sender: ChatSender.bot,
          action: command != null ? replyAction : null,
        ),
      );
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // 입력창에 포커스 유지
    _inputFocusNode.requestFocus();
  }

  void _navigateByCommand(String command) {
    if (command == 'hospital') {
      Navigator.pushNamed(context, '/hospital_search');
    } else if (command == 'pharmacy') {
      Navigator.pushNamed(context, '/pharmacy_nearby');
    } else if (command == 'emergency') {
      Navigator.pushNamed(context, '/emergency_map');
    } else if (command == 'reservation') {
      Navigator.pushNamed(context, '/reservation');
    }
  }

  void _showLanguageDialog() {
    showDialog(context: context, builder: (context) => const LanguageDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => nav_MainPage(initialIndex: 0)),
                  (route) => false,
            );
          },
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'chatbot.title'.tr(),
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: _showLanguageDialog,
            tooltip: 'language_selection'.tr(),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // 인사말 메시지
                    return ChatbotBubble(message: _messages[0]);
                  }
                  if (index == 1) {
                    // 네비게이션 버튼
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.local_hospital),
                                  label: Text('chatbot.find_hospital'.tr(),
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Color(0xFF4BB8EA),
                                  ),
                                  onPressed: () => _onQuickAction('hospital'),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.local_pharmacy),
                                  label: Text('chatbot.find_pharmacy'.tr(),
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Color(0xFF4BB8EA),
                                  ),
                                  onPressed: () => _onQuickAction('pharmacy'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.emergency),
                                  label: Text('chatbot.find_emergency'.tr(),
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Color(0xFF4BB8EA),
                                  ),
                                  onPressed: () => _onQuickAction('emergency'),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text('chatbot.make_reservation'.tr(),
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Color(0xFF4BB8EA),
                                  ),
                                  onPressed:
                                      () => _onQuickAction('reservation'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  // 나머지 메시지
                  return ChatbotBubble(
                    message: _messages[index - 1],
                    onAction: (action) => _navigateByCommand(action),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ChatbotInput(
                onSend: _sendMessage,
                focusNode: _inputFocusNode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQuickAction(String action) {
    String message = '';
    String route = '';
    switch (action) {
      case 'hospital':
        message = 'chatbot.action_hospital'.tr();
        route = '/hospital_search';
        break;
      case 'pharmacy':
        message = 'chatbot.action_pharmacy'.tr();
        route = '/pharmacy_nearby';
        break;
      case 'emergency':
        message = 'chatbot.action_emergency'.tr();
        route = '/emergency_map';
        break;
      case 'reservation':
        message = 'chatbot.action_reservation'.tr();
        route = '/hospital_search';
        break;
    }
    setState(() {
      _messages.add(ChatbotMessage(text: message, sender: ChatSender.bot));
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushNamed(context, route);
    });
  }
}
