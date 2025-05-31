import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../constants/app_colors.dart';
import 'custom_button.dart';
import '../../services/tts/tts_service.dart';
import '../../services/stt/stt_service.dart';

class InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSend;

  const InputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.focusNode,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TtsService _ttsService = TtsService();
  final STTService _sttService = STTService();
  bool _isRecording = false;
  bool _isSendingAfterTts = false;
  bool _isKeyboardVisible = false;

  // 키보드 가시성 컨트롤러
  late final KeyboardVisibilityController _keyboardVisibilityController;
  late final StreamSubscription<bool> _keyboardSubscription;

  @override
  void initState() {
    super.initState();
    _sttService.initialize();
    widget.controller.addListener(_onTextChanged);

    // 키보드 가시성 관련 초기화
    _keyboardVisibilityController = KeyboardVisibilityController();
    _isKeyboardVisible = _keyboardVisibilityController.isVisible;
    _keyboardSubscription = _keyboardVisibilityController.onChange.listen((
      visible,
    ) {
      setState(() {
        _isKeyboardVisible = visible;
      });
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _ttsService.dispose();
    if (_isRecording) {
      _sttService.stopListening();
    }
    _keyboardSubscription.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    // 상태가 변경될 때 UI 업데이트
    setState(() {});
  }

  void _handleButtonPress() {
    if (widget.controller.text.isEmpty) {
      _startVoiceInput();
    } else {
      widget.onSend();
    }
  }

  Future<void> _startVoiceInput() async {
    setState(() {
      _isRecording = true;
    });

    await _sttService.startListening(
      onResult: (text, isFinal) {
        widget.controller.text = text;

        if (isFinal) {
          setState(() {
            _isRecording = false;
            _isSendingAfterTts = true;
          });

          // TTS로 음성 피드백
          _ttsService.addToQueue('음성 인식이 완료되었습니다. "${text}" 전송합니다.');

          // TTS가 끝나면 자동으로 메시지 전송
          Future.delayed(const Duration(seconds: 2), () {
            if (_isSendingAfterTts && mounted) {
              widget.onSend();
              setState(() {
                _isSendingAfterTts = false;
              });
            }
          });
        }
      },
      onSpeechComplete: () {
        setState(() {
          _isRecording = false;
        });
      },
    );
  }

  // 텍스트 필드 빌드 메서드
  Widget _buildTextField(bool isEmpty) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      maxLines: 3, // 최대 3줄까지 표시 가능
      minLines: 1, // 최소 1줄
      keyboardType: TextInputType.multiline, // 여러 줄 입력 가능한 키보드
      textInputAction: TextInputAction.newline, // 엔터 키를 줄바꿈으로 처리
      style: const TextStyle(fontSize: 16, color: AppColors.gray100),
      decoration: InputDecoration(
        hintText: _isRecording ? '듣고 있습니다. 말씀하세요...' : '메시지를 입력하세요',
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        // 텍스트가 있을 때만 지우기 버튼 표시
        suffixIcon:
            !isEmpty
                ? IconButton(
                  onPressed: () {
                    widget.controller.clear();
                    // textController를 비운 후 상태 업데이트
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.gray60,
                  ),
                )
                : null,
      ),
    );
  }

  // 전송/음성 버튼 빌드 메서드
  Widget _buildActionButton(bool isEmpty) {
    return CustomButton(
      type: CustomButtonType.circular,
      icon: isEmpty ? Icons.mic : Icons.send,
      backgroundColor: AppColors.main100,
      iconColor: Colors.white,
      onPressed: _handleButtonPress,
    );
  }

  // 키보드가 보일 때 레이아웃 (세로 배치)
  Widget _buildVerticalLayout(bool isEmpty) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          // 텍스트 필드 (1행 전체)
          child: _buildTextField(isEmpty),
        ),

        const SizedBox(height: 8), // 행 간 간격

        // 전송 버튼 (2행, 우측 정렬)
        Align(
          alignment: Alignment.centerRight,
          child: _buildActionButton(isEmpty),
        ),
      ],
    );
  }

  // 키보드가 안 보일 때 레이아웃 (가로 배치)
  Widget _buildHorizontalLayout(bool isEmpty) {
    return Row(
      children: [
        const SizedBox(width: 12),

        // 텍스트 필드
        Expanded(child: _buildTextField(isEmpty)),
        const SizedBox(width: 8),
        
        // 동적 버튼 (음성 모드 또는 전송)
        _buildActionButton(isEmpty),
      ],
    );
  }

  // 컨테이너 스타일 관련 메서드들
  EdgeInsetsGeometry _getContainerPadding() {
    return _isKeyboardVisible
        ? const EdgeInsets.only(top: 12) // 키보드가 보이면 좌우하단 패딩 없음
        : const EdgeInsets.only(left: 12, right: 12, top: 12); // 기본 패딩
  }

  BorderRadius _getContainerRadius() {
    return _isKeyboardVisible
        ? const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ) // 키보드가 보이면 위쪽만 둥글게
        : BorderRadius.circular(16); // 모든 코너 둥글게
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = widget.controller.text.isEmpty;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: _getContainerPadding(),
        child: Container(
          width: double.infinity, // 화면 너비 전체를 차지
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: _getContainerRadius(),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child:
              _isKeyboardVisible
                  ? _buildVerticalLayout(isEmpty) // 키보드가 보일 때: 세로 레이아웃
                  : _buildHorizontalLayout(isEmpty), // 키보드가 안 보일 때: 가로 레이아웃
        ),
      ),
    );
  }
}
