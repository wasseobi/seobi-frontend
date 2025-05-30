import 'package:flutter/material.dart';
import '../components/message_list.dart';
import '../../services/conversation/conversation_service.dart';
import '../../repositories/backend/models/message.dart';
import '../../repositories/backend/models/session.dart';
import '../../services/auth/auth_service.dart';
import '../../services/tts/tts_service.dart';

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

  // TTS 버퍼 관련 변수
  String _ttsBuffer = '';
  static const int _minBufferSize = 30; // 버퍼 크기를 30자로 증가
  static final RegExp _sentenceEndPattern = RegExp(r'[.!?]+\s*');

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
        final index = _messages.indexWhere((m) => m.id == 'streaming');
        if (index != -1) {
          final previousContent = _messages[index].content;
          _messages[index] = message;

          // 스트리밍 중인 메시지의 새로운 내용이 있다면 TTS 버퍼에 추가
          if (message.content.length > previousContent.length) {
            final newContent = message.content.substring(
              previousContent.length,
            );
            _ttsBuffer += newContent;

            // 버퍼가 충분히 쌓였거나 문장이 완성되면 TTS 실행
            if (_ttsBuffer.length >= _minBufferSize ||
                _sentenceEndPattern.hasMatch(_ttsBuffer)) {
              // 문장 단위로 분리하여 처리
              final sentences = _ttsBuffer.split(_sentenceEndPattern);
              if (sentences.length > 1) {
                // 완성된 문장들 처리
                final completeText =
                    sentences
                        .sublist(0, sentences.length - 1)
                        .join('. ')
                        .trim() +
                    '.';
                if (completeText.isNotEmpty) {
                  _ttsService.handleNewMessage(completeText);
                }
                // 마지막 미완성 문장은 버퍼에 유지
                _ttsBuffer = sentences.last;
              }
            }
          }
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
          final previousContent = _messages[index].content;
          _messages[index] = message;

          // 최종 메시지의 남은 부분 처리
          if (message.role == Message.ROLE_ASSISTANT &&
              message.content.length > previousContent.length) {
            // 버퍼에 남은 내용이 있으면 함께 처리
            final remainingContent =
                (_ttsBuffer + message.content.substring(previousContent.length))
                    .trim();
            if (remainingContent.isNotEmpty) {
              _ttsService.handleNewMessage(remainingContent);
              _ttsBuffer = '';
            }
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

  void _updateMessage(String text, {bool shouldScroll = true}) {
    if (mounted && _messages.isNotEmpty) {
      setState(() {
        _messages[_messages.length - 1] = _messages[_messages.length - 1]
            .copyWith(content: text);
      });

      if (shouldScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    }
  }

  Future<void> _handleMessageSubmit(String content) async {
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

    setState(() => _isStreaming = true);

    String bufferedText = '';

    try {
      // 사용자 메시지 준비
      final userMessage = Message(
        id: DateTime.now().toIso8601String(),
        sessionId: _currentSession!.id,
        userId: _userId!,
        content: content,
        role: Message.ROLE_USER,
        timestamp: DateTime.now(),
      );

      // AI 응답 메시지 초기화
      final aiMessage = Message(
        id: 'streaming',
        sessionId: _currentSession!.id,
        userId: _userId!,
        content: '',
        role: Message.ROLE_ASSISTANT,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages = [..._messages, userMessage, aiMessage];
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // POST /s/{session_id}/send로 메시지 전송 및 스트리밍 응답 처리
      final response = await _conversationService.sendMessageStream(
        sessionId: _currentSession!.id,
        content: content,
        onProgress: (partialResponse) async {
          if (mounted && _messages.isNotEmpty) {
            if (partialResponse.length > bufferedText.length) {
              bufferedText = partialResponse;
            }
            _updateMessage(partialResponse);
          }
        },
      );

      if (mounted) {
        setState(() {
          _messages[_messages.length - 1] = _messages[_messages.length - 1]
              .copyWith(content: response.content);
          _isStreaming = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      // 부모 위젯의 콜백 호출
      widget.onMessageSubmit?.call(content);
    } catch (e) {
      debugPrint('[ChatScreen] 메시지 전송 오류: $e');
      _showError('메시지 전송 중 오류가 발생했습니다');
      if (mounted && _messages.isNotEmpty) {
        setState(() {
          _messages.removeAt(_messages.length - 1);
          _isStreaming = false;
        });
      }
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
                      Color(0xFF4F4F4F),
                    ),
                  ),
                )
                : MessageList(
                  messages: _messages,
                  scrollController: _scrollController,
                  onTtsPlay: (message) async {
                    // 수동 재생 시에는 전체 내용을 한 번에 재생
                    await _ttsService.stop();
                    await _ttsService.addToQueue(message.content);
                  },
                ),
      ),
    );
  }
}
