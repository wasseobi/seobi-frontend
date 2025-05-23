import 'package:flutter/material.dart';
import '../navigation/app_drawer.dart';
import '../auth/sign_in_screen.dart';
import '../../services/auth/auth_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialized = false;
  final _authService = AuthService();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '여기에 인식된 텍스트가 표시됩니다.';
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    if (!mounted) return;

    if (!_authService.isLoggedIn && mounted) {
      // 로그인되어 있지 않으면 로그인 화면으로 이동
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    } else {
      setState(() {
        _initialized = true;
      });
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      print('STT available: $available');
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            print(
              'onResult: ${val.recognizedWords}, confidence: ${val.confidence}, finalResult: ${val.finalResult}',
            );
            setState(() {
              _recognizedText =
                  val.recognizedWords.isEmpty
                      ? '여기에 인식된 텍스트가 표시됩니다.'
                      : val.recognizedWords;
            });
            // finalResult가 true이면 음성 인식이 자동으로 끝난 것
            if (val.finalResult) {
              print('Final result received, stopping...');
              setState(() {
                _isListening = false;
              });
            }
          },
          partialResults: true,
          localeId: 'ko-KR',
          cancelOnError: true,
        );
      } else {
        print('STT not available');
        setState(() {
          _recognizedText = 'STT를 사용할 수 없습니다. 권한을 확인해주세요.';
        });
      }
    } else {
      print('Stopping STT manually');
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _sendMessage() {
    String message = _textController.text.trim();
    if (message.isNotEmpty) {
      // TODO: 백엔드에 메시지 전송하는 로직 추가
      print('텍스트 메시지 전송: $message');
      _textController.clear();
    }
  }

  void _sendVoiceMessage() {
    if (_recognizedText != '여기에 인식된 텍스트가 표시됩니다.' &&
        _recognizedText.isNotEmpty) {
      // TODO: 백엔드에 음성 메시지 전송하는 로직 추가
      print('음성 메시지 전송: $_recognizedText');
      setState(() {
        _recognizedText = '여기에 인식된 텍스트가 표시됩니다.';
      });
    }
  }

  void _simulateSTT() {
    setState(() {
      _recognizedText = '사용자 STT 테스트 : 안녕! 오늘 일정 알려줘';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Seobi App')),
      body: Column(
        children: [
          // 메인 컨텐츠 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 상단 안내 텍스트
                  const Text(
                    '탭 하고, Seobi에게 오늘 일정을 말해보세요!',
                    style: TextStyle(
                      color: Color(0xFF4F4F4F),
                      fontSize: 20,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // 마이크 버튼
                  GestureDetector(
                    onTap: _listen,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color:
                            _isListening
                                ? Colors.blueAccent
                                : const Color(0xFFD9D9D9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic,
                        size: 80,
                        color: _isListening ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // STT 시뮬레이션 버튼 (테스트용)
                  ElevatedButton(
                    onPressed: _simulateSTT,
                    child: const Text('STT 시뮬레이션 (테스트용)'),
                  ),
                  const SizedBox(height: 10),

                  // 인식된 텍스트 표시 영역
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _recognizedText,
                          style: const TextStyle(
                            color: Color(0xFF4F4F4F),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_recognizedText != '여기에 인식된 텍스트가 표시됩니다.' &&
                            _recognizedText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ElevatedButton(
                              onPressed: _sendVoiceMessage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('음성 메시지 전송'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 텍스트 입력 영역
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFD9D9D9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: '텍스트로 Seobi에게 물어보기',
                        hintStyle: TextStyle(
                          color: Color(0xFF4F4F4F),
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
