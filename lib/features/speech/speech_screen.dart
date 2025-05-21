import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/speech_service.dart';
import '../../models/speech_recognition_model.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen>
    with SingleTickerProviderStateMixin {
  late SpeechService _speechService;
  bool _isListening = false;
  String _text = '';
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSpeechResult(SpeechRecognitionData data) {
    setState(() {
      _text = data.recognizedText;
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
              top: size.height * 0.33 + size.width * 0.72 + 20, // 원 아래 20px
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
              right: 15,
              child: Container(
                height: 53,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const TextField(
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
          ],
        ),
      ),
    );
  }
}
