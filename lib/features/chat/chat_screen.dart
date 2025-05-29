import 'package:flutter/material.dart';
import '../../services/conversation/conversation_service.dart';
import '../../repositories/backend/models/message.dart';
import '../../repositories/backend/models/session.dart';
import '../../services/tts/tts_service.dart';
import '../../services/stt/stt_service.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ConversationService _conversationService = ConversationService();
  final ScrollController _scrollController = ScrollController();
  final TtsService _ttsService = TtsService();
  final STTService _sttService = STTService();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Session? _currentSession;
  List<Message> _messages = [];
  String _streamingMessage = '';
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isListening = false;

  String _displayText = '';
  String _confirmedText = '';
  String _pendingText = '';

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _initializeSpeech();
    _ttsService.setConfiguration(language: 'ko-KR');

    _messageController.addListener(() {
      final newText = _messageController.text;
      if (!_isListening && _displayText != newText) {
        setState(() {
          _displayText = newText;
          _confirmedText = newText;
        });
      }
    });
  }

  Future<void> _initializeSpeech() async {
    bool available = await _sttService.initialize();
    if (!available) {
      debugPrint('[ChatScreen] STT is not available on this device');
    }
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      final session = await _conversationService.createSession(isAIChat: true);
      final messages = await _conversationService.getSessionMessages(
        session.id,
        isAIChat: true,
      );

      setState(() {
        _currentSession = session;
        _messages = messages;
      });
    } catch (e) {
      _showError('채팅 초기화 중 오류가 발생했습니다: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _updateDisplayText() {
    String newDisplayText =
        _confirmedText.isEmpty
            ? _pendingText
            : '$_confirmedText $_pendingText'.trim();

    setState(() {
      _displayText = newDisplayText;
      _messageController.value = TextEditingValue(
        text: newDisplayText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: newDisplayText.length),
        ),
      );
    });
  }

  Future<void> _handleMessageSend() async {
    final content = _displayText.trim();
    if (_currentSession == null || content.isEmpty) return;

    // 입력 필드 초기화
    setState(() {
      _messageController.clear();
      _displayText = '';
      _confirmedText = '';
      _pendingText = '';
    });
    _focusNode.unfocus();

    try {
      // 사용자 메시지를 즉시 표시
      final userMessage = Message(
        id: DateTime.now().toIso8601String(),
        sessionId: _currentSession!.id,
        userId: 'user',
        content: content,
        role: Message.ROLE_USER,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages = [..._messages, userMessage];
      });
      _scrollToBottom();

      // AI 응답 스트리밍 시작
      final aiMessage = Message(
        id: 'streaming',
        sessionId: _currentSession!.id,
        userId: 'assistant',
        content: '',
        role: Message.ROLE_ASSISTANT,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages = [..._messages, aiMessage];
      });
      _scrollToBottom();

      // AI 응답 스트리밍 처리
      await _conversationService.sendMessageStream(
        sessionId: _currentSession!.id,
        content: content,
        onProgress: (partialResponse) {
          setState(() {
            final lastMessage = _messages.last;
            if (lastMessage.role == Message.ROLE_ASSISTANT) {
              _messages = [
                ..._messages.sublist(0, _messages.length - 1),
                lastMessage.copyWith(content: partialResponse),
              ];
            }
          });
          _scrollToBottom();
        },
      );

      // 스트리밍이 완료되면 메시지 목록 업데이트
      final messages = await _conversationService.getSessionMessages(
        _currentSession!.id,
        isAIChat: true,
      );

      setState(() {
        _messages = messages;
      });

      // TTS 재생
      if (_messages.isNotEmpty) {
        final lastMessage = _messages.last;
        if (lastMessage.role == Message.ROLE_ASSISTANT) {
          _ttsService.addToQueue(lastMessage.content);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[ChatScreen] 메시지 전송 오류: $e\n$stackTrace');
      _showError('메시지 전송 중 오류가 발생했습니다');

      // 오류 발생 시 마지막 메시지 제거
      setState(() {
        _messages = _messages.sublist(0, _messages.length - 1);
      });
    }

    _scrollToBottom();
  }

  Future<void> _handleVoiceListen() async {
    if (_sttService.isListening) {
      await _sttService.stopListening();
      setState(() {
        _isListening = false;
        _confirmedText = _displayText;
        _pendingText = '';
        _updateDisplayText();
      });
    } else {
      setState(() {
        _isListening = true;
        _pendingText = '';
        _updateDisplayText();
      });

      await _sttService.startListening(
        onResult: (text, isFinal) {
          if (mounted) {
            setState(() {
              _pendingText = text;
              _updateDisplayText();
            });
          }
        },
        onSpeechComplete: () {
          if (mounted) {
            setState(() {
              _isListening = false;
              _confirmedText = _displayText;
              _pendingText = '';
              _updateDisplayText();
            });
          }
        },
      );
    }
  }

  void _handleTtsToggle() async {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      await _ttsService.resume();
    } else {
      await _ttsService.pause();
    }
  }

  void _onTextFieldTap() {
    if (_isListening) {
      _sttService.stopListening();
      setState(() {
        _isListening = false;
        _confirmedText = _displayText;
        _pendingText = '';
        _updateDisplayText();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    _ttsService.dispose();
    if (_sttService.isListening) {
      _sttService.stopListening();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isLastMessage = index == _messages.length - 1;
              final isStreaming =
                  isLastMessage &&
                  message.role == Message.ROLE_ASSISTANT &&
                  message.id == 'streaming';

              return MessageBubble(
                message: message,
                isUser: message.role == Message.ROLE_USER,
                isStreaming: isStreaming,
              );
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        enableSuggestions: true,
                        enableIMEPersonalizedLearning: true,
                        onTap: _onTextFieldTap,
                        decoration: InputDecoration(
                          hintText:
                              _isListening ? '말씀해주세요...' : '메시지를 입력하세요...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            8,
                          ),
                        ),
                        maxLines: null,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: _handleVoiceListen,
                            icon: Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              color:
                                  _isListening
                                      ? Colors.red
                                      : Theme.of(context).primaryColor,
                            ),
                          ),
                          IconButton(
                            onPressed: _handleMessageSend,
                            icon: const Icon(Icons.send),
                          ),
                          IconButton(
                            onPressed: _handleTtsToggle,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
