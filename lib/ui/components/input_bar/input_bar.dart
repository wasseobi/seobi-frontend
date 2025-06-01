import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../common/custom_button.dart';
import 'view_models/input_bar_view_model.dart';

class InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;

  const InputBar({
    super.key,
    required this.controller,
    this.focusNode,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  // TextField에 대한 GlobalKey 추가
  final GlobalKey<EditableTextState> _textFieldKey =
      GlobalKey<EditableTextState>();

  late final FocusNode _focusNode;
  late final InputBarViewModel _viewModel;
  
  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _viewModel = InputBarViewModel(
      textController: widget.controller,
      focusNode: _focusNode,
    );
  }

  @override
  void dispose() {
    // 외부에서 제공된 focusNode가 아닐 경우에만 dispose
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _viewModel.dispose();
    super.dispose();
  }
  // 텍스트 필드 빌드 메서드
  Widget _buildTextField(BuildContext context, bool isEmpty, bool isRecording) {
    final viewModel = Provider.of<InputBarViewModel>(context);
    return TextField(
      key: _textFieldKey, // GlobalKey 할당
      controller: widget.controller,
      focusNode: _focusNode,
      maxLines: 3, // 최대 3줄까지 표시 가능
      minLines: 1, // 최소 1줄
      keyboardType: TextInputType.multiline, // 여러 줄 입력 가능한 키보드
      textInputAction: TextInputAction.newline, // 엔터 키를 줄바꿈으로 처리
      style: const TextStyle(fontSize: 16, color: AppColors.gray100),
      decoration: InputDecoration(
        hintText: isRecording ? '듣고 있습니다. 말씀하세요...' : '메시지를 입력하세요',
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        // 텍스트가 있을 때만 지우기 버튼 표시
        suffixIcon:
            !isEmpty
                ? IconButton(
                  onPressed: () {
                    viewModel.clearText();
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
  Widget _buildActionButton(BuildContext context, bool isEmpty) {
    final viewModel = Provider.of<InputBarViewModel>(context);
    return CustomButton(
      type: CustomButtonType.circular,
      icon: isEmpty ? Icons.mic : Icons.send,
      backgroundColor: AppColors.main100,
      iconColor: Colors.white,
      onPressed: viewModel.handleButtonPress,
    );
  }

  // 컨테이너 스타일 관련 메서드들
  EdgeInsetsGeometry _getContainerPadding(bool isKeyboardVisible) {
    return isKeyboardVisible
        ? EdgeInsets
            .zero // 키보드가 보이면 좌우하단 패딩 없음
        : const EdgeInsets.only(left: 12, right: 12); // 기본 패딩
  }
  BorderRadius _getContainerRadius(bool isKeyboardVisible) {
    return isKeyboardVisible
        ? const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ) // 키보드가 보이면 위쪽만 둥글게
        : BorderRadius.circular(16); // 모든 코너 둥글게
  }
    @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<InputBarViewModel>(
        builder: (context, viewModel, _) {
          return KeyboardVisibilityBuilder(
            builder: (context, isKeyboardVisible) {
              debugPrint('키보드 상태: $isKeyboardVisible');
              return Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: _getContainerPadding(isKeyboardVisible),
                  child: Container(
                    width: double.infinity, // 화면 너비 전체를 차지
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: _getContainerRadius(isKeyboardVisible),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),

                        // 텍스트 필드
                        Expanded(
                          child: _buildTextField(
                            context,
                            viewModel.isEmpty,
                            viewModel.isRecording,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 동적 버튼 (음성 모드 또는 전송)
                        _buildActionButton(context, viewModel.isEmpty),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
