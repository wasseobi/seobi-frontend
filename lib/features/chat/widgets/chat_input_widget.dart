import 'package:flutter/material.dart';
import '../../../services/stt/stt_service.dart';

class ChatInputWidget extends StatefulWidget {
  final Function(String) onMessageSend;
  final VoidCallback onSwitchMode;
  final String? initialText;

  const ChatInputWidget({
    super.key,
    required this.onMessageSend,
    required this.onSwitchMode,
    this.initialText,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  late final TextEditingController _messageController;
  late final FocusNode _focusNode;
  bool _isListening = false;
  final STTService _sttService = STTService();

  String _displayText = ''; // 1) 텍스트 필드에 표시되는 값
  String _confirmedText = ''; // 2) 확정된 값
  String _pendingText = ''; // 3) STT로 인식 중인 미확정 값

  @override
  void initState() {
    super.initState();
    _displayText = widget.initialText ?? '';
    _confirmedText = _displayText;
    _messageController = TextEditingController(text: _displayText);
    _focusNode = FocusNode();
    _initializeSpeech();

    // 텍스트 수정 시 표시값과 확정값 업데이트
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
      debugPrint('STT is not available on this device');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    if (_sttService.isListening) {
      _sttService.stopListening();
    }
    super.dispose();
  }

  void _updateDisplayText() {
    String newDisplayText =
        _confirmedText.isEmpty
            ? _pendingText
            : '$_confirmedText ${_pendingText}'.trim();

    setState(() {
      _displayText = newDisplayText;
      _messageController.value = TextEditingValue(
        text: newDisplayText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: newDisplayText.length),
        ),
      );
    });

    debugPrint('텍스트 상태 ================================');
    debugPrint('현재 출력중: "$_displayText"');
    debugPrint('확정된 값: "$_confirmedText"');
    debugPrint('인식 중: "$_pendingText"');
    debugPrint('==========================================');
  }

  void _handleSend() {
    final message = _displayText.trim();
    if (message.isNotEmpty) {
      widget.onMessageSend(message);
      _messageController.clear();
      _displayText = '';
      _confirmedText = '';
      _pendingText = '';
      _focusNode.unfocus();
    }
  }

  void _handleVoiceListen() async {
    if (_sttService.isListening) {
      // 청취 강제 종료
      await _sttService.stopListening();
      setState(() {
        _isListening = false;
        // 청취가 종료되면 현재까지의 인식 결과를 확정
        _confirmedText = _displayText;
        _pendingText = '';
        _updateDisplayText();
      });
    } else {
      // 청취 시작
      setState(() {
        _isListening = true;
        _pendingText = '';
        _updateDisplayText();
      });

      await _sttService.startListening(
        onResult: (text, isFinal) {
          if (mounted) {
            setState(() {
              debugPrint('STT result: $text, isFinal: $isFinal');
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
  Widget build(BuildContext context) {
    return Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
                      hintText: _isListening ? '말씀해주세요...' : '메시지를 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                          color: _isListening
                              ? Colors.red
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                      IconButton(
                        onPressed: _handleSend,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
