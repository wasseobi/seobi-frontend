import 'package:flutter/material.dart';
import '../../services/stt/stt_service.dart';

class STTScreen extends StatefulWidget {
  final void Function(String message)? onMessageSend;

  const STTScreen({super.key, this.onMessageSend});

  @override
  State<STTScreen> createState() => _STTScreenState();
}

class _STTScreenState extends State<STTScreen> {
  final _sttService = STTService();
  final TextEditingController _textController = TextEditingController();

  bool _isListening = false;
  String _recognizedText = '여기에 인식된 텍스트가 표시됩니다.';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _sttService.initialize();
      if (available) {
        setState(() => _isListening = true);
        await _sttService.startListening(
          onResult: (text, isFinal) {
            setState(() {
              _recognizedText = text.isEmpty ? '여기에 인식된 텍스트가 표시됩니다.' : text;
            });
            if (isFinal) {
              setState(() => _isListening = false);
            }
          },
        );
      } else {
        setState(() {
          _recognizedText = 'STT를 사용할 수 없습니다. 권한을 확인해주세요.';
        });
      }
    } else {
      setState(() => _isListening = false);
      await _sttService.stopListening();
    }
  }

  void _sendMessage() {
    String message = _textController.text.trim();
    if (message.isNotEmpty) {
      widget.onMessageSend?.call(message);
      _textController.clear();
    }
  }

  void _sendVoiceMessage() {
    if (_recognizedText != '여기에 인식된 텍스트가 표시됩니다.' &&
        _recognizedText.isNotEmpty) {
      widget.onMessageSend?.call(_recognizedText);
      setState(() {
        _recognizedText = '여기에 인식된 텍스트가 표시됩니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  child: const Icon(Icons.send, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
