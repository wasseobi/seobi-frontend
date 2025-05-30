import 'package:flutter/material.dart';
import '../components/message_list.dart';
import '../../services/conversation/conversation_service.dart';
import '../../repositories/backend/models/message.dart';
import '../../repositories/backend/models/session.dart';
import '../../services/auth/auth_service.dart';
import '../../services/tts/tts_service.dart';
import '../constants/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final Function(String)? onMessageSubmit;

  const ChatScreen({super.key, this.onMessageSubmit});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final ConversationService _conversationService = ConversationService();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  final TtsService _ttsService = TtsService();

  Session? _currentSession;
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isStreaming = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
    _userId = _authService.userId;
  }

  Future<void> _initializeTts() async {
    await _ttsService.setConfiguration(
      language: 'ko-KR',
      volume: 1.0, // 최대 볼륨
    );
  }

  void addMessage(Message message) {
    setState(() {
      // 스트리밍 중인 메시지 업데이트
      if (message.id == 'streaming') {
        _isStreaming = true;
        final index = _messages.indexWhere((m) => m.id == 'streaming');
        if (index != -1) {
          _messages[index] = message;
        } else {
          _messages.add(message);
        }
      } else {
        // 일반 메시지 추가 또는 업데이트
        final index = _messages.indexWhere(
          (m) =>
              m.id == message.id ||
              (m.id == 'streaming' && m.role == message.role),
        );
        if (index != -1) {
          _messages[index] = message;
          // 스트리밍 메시지가 실제 ID로 대체되면 스트리밍 완료
          if (_messages[index].id != 'streaming') {
            _isStreaming = false;
          }
        } else {
          _messages.add(message);
        }
      }

      // 스크롤을 최신 메시지로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void updateLastMessage(Message message) {
    if (_messages.isNotEmpty) {
      setState(() {
        _messages[_messages.length - 1] = message;
        // 메시지가 스트리밍 ID가 아니라면 스트리밍 완료로 간주
        if (message.id != 'streaming') {
          _isStreaming = false;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
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
        _messages = messages;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
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
    if (_currentSession != null) {
      _conversationService.endSession(_currentSession!.id);
    }
    _scrollController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.main100,
                    ),
                  ),
                )
                : MessageList(
                  messages: _messages,
                  scrollController: _scrollController,
                  onTtsPlay: (message) async {
                    try {
                      // 완료된 메시지의 전체 내용을 재생
                      debugPrint('[ChatScreen] 완료된 메시지 TTS 재생');
                      await _ttsService.stop(); // 기존 재생 중지
                      await _ttsService.addToQueue(message.content); // 전체 내용 재생
                    } catch (e) {
                      debugPrint('[ChatScreen] TTS 재생 오류: $e');
                    }
                  },
                ),
      ),
    );
  }
}
