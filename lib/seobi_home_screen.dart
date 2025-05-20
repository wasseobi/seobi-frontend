import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SeobiHomeScreen extends StatefulWidget {
  const SeobiHomeScreen({super.key});

  @override
  State<SeobiHomeScreen> createState() => _SeobiHomeScreenState();
}

class _SeobiHomeScreenState extends State<SeobiHomeScreen>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            _controller.stop();
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
          _controller.stop();
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _controller.forward();
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _controller.stop();
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 페이지 인디케이터
            Positioned(
              top: size.height * 0.04,
              left: (size.width - 48) / 2, // 3 * 12 + 2 * 6 = 48
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7D7D7D),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD9D9D9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD9D9D9),
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
              child: Center(
                child: Text(
                  '탭 하고, Seobi에게 오늘 일정을 말해보세요!',
                  style: const TextStyle(
                    color: Color(0xFF4F4F4F),
                    fontSize: 20,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.10,
                  ),
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
                                  ? Colors.blue.withOpacity(0.3)
                                  : const Color(0xFFD9D9D9),
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
              top: size.height * 0.33 + size.width * 0.72 + 20, // 원 아래 20px
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  _text.isEmpty ? '여기에 인식된 텍스트가 표시됩니다.' : _text,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
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
                  color: Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
            ),
            // 하단 입력창
            Positioned(
              bottom: size.height * 0.06, // 조금 더 아래로
              left: 15,
              right: 15,
              child: Container(
                height: 53,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '텍스트로 Seobi에게 물어보기',
                    hintStyle: TextStyle(
                      color: Color(0xFF4F4F4F),
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.09,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF4F4F4F),
                    fontSize: 18,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.09,
                  ),
                  cursorColor: Color(0xFF4F4F4F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
