import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/speech_service.dart';
import '../../services/api_service.dart';
import '../../services/message_service.dart';
import '../../models/speech_recognition_model.dart';
import '../../models/user.dart';
import '../../models/session.dart';
import '../common/send_message_button.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen>
    with SingleTickerProviderStateMixin {
  late SpeechService _speechService;
  late ApiService _apiService;
  late MessageService _messageService;
  bool _isListening = false;
  String _text = '';
  bool _isSending = false;
  bool _isInitializing = true;
  String _statusMessage = '서비스 초기화 중...';

  User? _currentUser;
  Session? _currentSession;

  final TextEditingController _textController = TextEditingController();
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // API 서비스 초기화
    _apiService = ApiService(baseUrl: 'http://127.0.0.1:5000');
    _messageService = MessageService(apiService: _apiService);

    // 사용자 및 세션 설정
    _initializeUserAndSession();

    // 음성 인식 서비스 초기화
    _speechService = SpeechService();
    _speechService.onResultCallback = _handleSpeechResult;
    _speechService.onListeningStatusChanged = _handleListeningStatusChanged;
    _speechService.initialize();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 1.0,
      upperBound: 1.15,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });
  }

  // 사용자 및 세션 초기화
  Future<void> _initializeUserAndSession() async {
    setState(() {
      _isInitializing = true;
      _statusMessage = '사용자 생성 중...';
    });

    try {
      // 1. 사용자 생성
      _currentUser = await _apiService.createUser(
        username: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'user_${DateTime.now().millisecondsSinceEpoch}@example.com',
      );

      setState(() {
        _statusMessage = '세션 생성 중...';
      });

      // 2. 세션 생성
      _currentSession = await _apiService.createSession(
        userId: _currentUser!.id,
        title: '음성 인식 세션',
        description: '음성으로 생성된 메시지 세션',
      );

      // 3. ID 저장
      await _messageService.saveUserId(_currentUser!.id);
      await _messageService.saveSessionId(_currentSession!.id);

      setState(() {
        _isInitializing = false;
        _statusMessage = '초기화 완료!';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('사용자와 세션이 생성되었습니다!')));
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _statusMessage = '초기화 실패: $e';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('초기화 실패: $e')));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleSpeechResult(SpeechRecognitionData data) {
    setState(() {
      _text = data.recognizedText;
      _textController.text = _text;
    });
  }

  void _handleListeningStatusChanged(bool isListening) {
    setState(() {
      _isListening = isListening;
      if (!isListening) {
        _controller.stop();
      }
    });
  }

  void _listen() async {
    if (_isInitializing) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('아직 초기화 중입니다. 잠시 기다려주세요.')));
      return;
    }

    if (!_isListening) {
      setState(() {
        _isListening = true;
        _controller.forward();
      });
      _speechService.startListening();
    } else {
      setState(() => _isListening = false);
      _controller.stop();
      _speechService.stopListening();
    }
  }

  Future<void> _sendMessage() async {
    if (_isInitializing) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('아직 초기화 중입니다. 잠시 기다려주세요.')));
      return;
    }

    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final message = await _messageService.createMessage(_textController.text);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('메시지가 전송되었습니다: ${message.id}')));
      _textController.clear();
      setState(() {
        _text = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('메시지 전송 실패: $e')));
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // 초기화 중 표시
            if (_isInitializing)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(_statusMessage, style: AppTheme.regularText),
                  ],
                ),
              ),

            // 기존 UI 요소들
            if (!_isInitializing) ...[
              // 페이지 인디케이터
              Positioned(
                top: size.height * 0.04,
                left: (size.width - 48) / 2,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppTheme.secondaryGray,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppTheme.indicatorGray,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppTheme.indicatorGray,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              // 안내 텍스트
              Positioned(
                top: size.height * 0.18,
                left: 0,
                right: 0,
                child: const Center(
                  child: Text(
                    '탭 하고, Seobi에게 오늘 일정을 말해보세요!',
                    style: AppTheme.headerText,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // 가운데 원 (음성 인식 애니메이션)
              Positioned(
                top: size.height * 0.33,
                left: (size.width - size.width * 0.72) / 2,
                child: GestureDetector(
                  onTap: _listen,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? _controller.value : 1.0,
                        child: Container(
                          width: size.width * 0.72,
                          height: size.width * 0.72,
                          decoration: BoxDecoration(
                            color:
                                _isListening
                                    ? AppTheme.accentBlue.withOpacity(0.3)
                                    : AppTheme.indicatorGray,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            size: 60,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // 가운데 원 아래에 인식 결과 표시
              Positioned(
                top: size.height * 0.33 + size.width * 0.72 + 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    _text.isEmpty ? '여기에 인식된 텍스트가 표시됩니다.' : _text,
                    style: AppTheme.regularText,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // 하단 입력창 배경
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: size.width,
                  height: size.height * 0.16,
                  decoration: const BoxDecoration(
                    color: AppTheme.indicatorGray,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              // 하단 입력창
              Positioned(
                bottom: size.height * 0.06,
                left: 15,
                right: 75,
                child: Container(
                  height: 53,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '텍스트로 Seobi에게 물어보기',
                      hintStyle: AppTheme.regularText,
                      border: InputBorder.none,
                    ),
                    style: AppTheme.regularText,
                    cursorColor: AppTheme.primaryGray,
                  ),
                ),
              ),
              // 전송 버튼
              Positioned(
                bottom: size.height * 0.06,
                right: 15,
                child: SendMessageButton(
                  onPressed: _sendMessage,
                  isLoading: _isSending,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
