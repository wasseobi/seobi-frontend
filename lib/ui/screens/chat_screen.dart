import 'package:flutter/material.dart';
import '../components/message_list.dart';
import '../components/custom_button.dart';
import '../components/fab.dart';
import '../../services/conversation/conversation_service.dart';
import '../../services/tts/tts_service.dart';
import '../../services/stt/stt_service.dart';
import '../../repositories/backend/models/message.dart';
import '../../repositories/backend/models/session.dart';
import '../../services/auth/auth_service.dart';

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
  final AuthService _authService = AuthService();

  Session? _currentSession;
  List<Map<String, Object>> _messages = [];
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isListening = false;
  bool _isExpanded = false;
  String? _userId;

  String _displayText = '';
  String _confirmedText = '';
  String _pendingText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
    _initializeSpeech();
    _ttsService.setConfiguration(language: 'ko-KR');
    _userId = _authService.userId;

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
    if (_userId == null) {
      _showError('사용자 인증이 필요합니다.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. 세션 생성 (/s/open)
      final session = await _conversationService.createSession(isAIChat: true);

      // 2. 세션 메시지 조회 (/s/{session_id}/m)
      final messages = await _conversationService.getSessionMessages(
        session.id,
        isAIChat: true,
      );

      setState(() {
        _currentSession = session;
        _messages = _convertToUIMessages(messages);
      });
    } catch (e) {
      _showError('채팅 초기화 중 오류가 발생했습니다: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, Object>> _convertToUIMessages(List<Message> messages) {
    return messages
        .map(
          (msg) => <String, Object>{
            'id': msg.id,
            'session_id': msg.sessionId,
            'user_id': msg.userId,
            'text': msg.content,
            'isUser': msg.role == Message.ROLE_USER,
            'timestamp': msg.timestamp.toString(),
            'type': 'text',
            'role': msg.role,
          },
        )
        .toList();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleMessageSend() async {
    final content = _displayText.trim();

    if (_currentSession == null) {
      _showError('세션이 초기화되지 않았습니다.');
      return;
    }

    if (content.isEmpty) {
      _showError('메시지를 입력해주세요.');
      return;
    }

    if (_userId == null) {
      _showError('사용자 인증이 필요합니다.');
      return;
    }

    setState(() {
      _messageController.clear();
      _displayText = '';
      _confirmedText = '';
      _pendingText = '';
    });
    _focusNode.unfocus();

    try {
      // 사용자 메시지 준비
      final userMessage = <String, Object>{
        'id': DateTime.now().toString(),
        'session_id': _currentSession!.id,
        'user_id': _userId!,
        'text': content,
        'isUser': true,
        'timestamp': DateTime.now().toString(),
        'type': 'text',
        'role': Message.ROLE_USER,
      };

      // AI 응답 메시지 초기화
      final aiMessage = <String, Object>{
        'id': DateTime.now().toString(),
        'session_id': _currentSession!.id,
        'user_id': _userId!,
        'text': '',
        'isUser': false,
        'timestamp': '',
        'type': 'text',
        'role': Message.ROLE_ASSISTANT,
      };

      setState(() {
        _messages = [..._messages, userMessage, aiMessage];
      });

      // POST /s/{session_id}/send로 메시지 전송 및 스트리밍 응답 처리
      await _conversationService.sendMessageStream(
        sessionId: _currentSession!.id,
        content: content,
        onProgress: (partialResponse) {
          if (mounted && _messages.isNotEmpty) {
            setState(() {
              _messages[_messages.length - 1] = {
                ..._messages[_messages.length - 1],
                'text': partialResponse,
              };
            });
          }
        },
      );

      // GET /s/{session_id}/m로 최신 메시지 목록 조회
      final messages = await _conversationService.getSessionMessages(
        _currentSession!.id,
        isAIChat: true,
      );

      if (mounted) {
        setState(() {
          _messages = _convertToUIMessages(messages);
          // Add timestamp to the last AI message after it's fully printed
          if (_messages.isNotEmpty && !(_messages.last['isUser'] as bool)) {
            _messages[_messages.length - 1] = {
              ..._messages[_messages.length - 1],
              'timestamp': DateTime.now().toString(),
            };
          }
        });

        // TTS 재생
        if (_messages.isNotEmpty && !(_messages[0]['isUser'] as bool)) {
          _ttsService.addToQueue(_messages[0]['text'] as String);
        }
      }
    } catch (e) {
      debugPrint('[ChatScreen] 메시지 전송 오류: $e');
      _showError('메시지 전송 중 오류가 발생했습니다');
      if (mounted && _messages.isNotEmpty) {
        setState(() {
          _messages.removeAt(0);
        });
      }
    }
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

  @override
  void dispose() {
    // 세션 종료 처리 (/s/{session_id}/close)
    if (_currentSession != null) {
      _conversationService.endSession(_currentSession!.id);
    }
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

    return Scaffold(
      body: Stack(
        children: [
          ChatMessageList(messages: _messages),
          ChatFloatingBar(
            isExpanded: _isExpanded,
            onToggle: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            onCollapse: () {
              setState(() {
                _isExpanded = false;
              });
            },
            onSend: _handleMessageSend,
            controller: _messageController,
            focusNode: _focusNode,
          ),
        ],
      ),
    );
  }
}
