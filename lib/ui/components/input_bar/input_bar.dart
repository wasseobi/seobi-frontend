import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import 'package:seobi_app/ui/components/common/custom_button.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
import 'package:seobi_app/ui/constants/dimensions/app_dimensions.dart';
import 'input_bar_view_model.dart';

class InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Function(double height)? onHeightChanged;

  const InputBar({
    super.key,
    required this.controller,
    super.key,
    required this.controller,
    this.focusNode,
    this.onHeightChanged,
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
  double? _previousBottomInset; // IME/키보드 높이 변경 감지용

  double? _previousBottomInset; // IME/키보드 높이 변경 감지용

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _viewModel = InputBarViewModel(
      textController: widget.controller,
      focusNode: _focusNode,
    );

    // 텍스트 변경 리스너 추가
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // 텍스트가 변경될 때마다 높이를 다시 측정
    if (mounted) {
      setState(() {
        // setState를 호출하여 빌드 메서드가 다시 실행되도록 함
        // 이렇게 하면 _measureAndNotifyHeight가 다시 호출됨
      });
    }
  }

  @override
  void dispose() {
    // 텍스트 변경 리스너 제거
    widget.controller.removeListener(_onTextChanged);

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
    return IntrinsicHeight(
      child: TextField(
        key: _textFieldKey, // GlobalKey 할당
        controller: widget.controller,
        focusNode: _focusNode,
        onTap: viewModel.handleTextFieldTap, // 텍스트 필드 터치 시 모드 전환
        maxLines: 3, // 최대 3줄까지 표시 가능
        minLines: 1, // 최소 1줄
        keyboardType: TextInputType.multiline, // 여러 줄 입력 가능한 키보드
        textInputAction: TextInputAction.newline, // 엔터 키를 줄바꿈으로 처리
        style: const TextStyle(fontSize: 16, color: AppColors.gray100),
        decoration: InputDecoration(
          hintText: viewModel.hintText,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12), // 세로 패딩 증가
          // 텍스트가 있을 때만 지우기 버튼 표시
          suffixIcon:
              !isEmpty
                  ? IconButton(
                    onPressed: viewModel.clearText,
                    icon: const Icon(Icons.close),
                  )
                  : null,
        ),
      ),
    );
  }

  // 전송/음성 버튼 빌드 메서드
  Widget _buildActionButton(BuildContext context, bool isEmpty) {
    final viewModel = Provider.of<InputBarViewModel>(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton.filled(
          icon: Icon(viewModel.actionButtonIcon),
          color: Colors.white,
          onPressed: viewModel.handleButtonPress,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(
              viewModel.actionButtonColor,
            ),
          ),
        ),

        if (viewModel.isSendingAfterTts)
          SizedBox(
            width: AppDimensions.buttonHeightMedium,
            height: AppDimensions.buttonHeightMedium,
            child: GestureDetector(
              onTap: viewModel.handleButtonPress,
              child: CircularProgressIndicator(
                value: viewModel.getTimerProgress(),
              ),
            ),
          ),
      ],
    );
  }

  // 컨테이너 스타일 관련 메서드들
  EdgeInsetsGeometry _getContainerMargin(bool isKeyboardVisible) {
    return isKeyboardVisible
        ? EdgeInsets
            .zero // 키보드가 보이면 좌우하단 패딩 없음
        : const EdgeInsets.only(
          left: AppDimensions.paddingSmall,
          right: AppDimensions.paddingSmall,
          bottom: AppDimensions.paddingSmall,
        ); // 기본 패딩
  }

  BorderRadius _getContainerRadius(bool isKeyboardVisible) {
    final radius = AppDimensions.borderRadiusLarge; // 반경 값

    final radius = AppDimensions.borderRadiusLarge; // 반경 값

    return isKeyboardVisible
        ? BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ) // 키보드가 보이면 위쪽만 둥글게
        : BorderRadius.circular(radius); // 모든 코너 둥글게
  }

  // 높이 측정을 위한 GlobalKey
  final GlobalKey _containerKey = GlobalKey();

  // 높이 측정 및 콜백 호출 메서드
  void _measureAndNotifyHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          _containerKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? renderBox =
          _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && widget.onHeightChanged != null) {
        final size = renderBox.size;
        widget.onHeightChanged!(size.height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final previousBottomInset = _previousBottomInset ?? 0;

    if (bottomInset != previousBottomInset) {
      debugPrint(
        'InputBar - IME/키보드 높이 변경: $previousBottomInset -> $bottomInset',
      );
      debugPrint(
        'InputBar - IME/키보드 높이 변경: $previousBottomInset -> $bottomInset',
      );
      _previousBottomInset = bottomInset;
    }

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<InputBarViewModel>(
        builder: (context, viewModel, _) {
          return KeyboardVisibilityBuilder(
            builder: (context, isKeyboardVisible) {
              // 레이아웃이 변경될 때마다 높이 측정
              _measureAndNotifyHeight();
              return Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: _getContainerMargin(isKeyboardVisible),
                  child: Material(
                    key: _containerKey,
                    shape: RoundedRectangleBorder(
                      borderRadius: _getContainerRadius(isKeyboardVisible),
                      side: BorderSide(color: AppColors.gray40, width: 1),
                    ),
                    color: AppColors.white100,
                    child: Padding(
                      padding: _getContainerPadding(isKeyboardVisible),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: AppDimensions.paddingMedium,
                          ), // 텍스트 필드
                          Expanded(
                            child: _buildTextField(
                              context,
                              viewModel.isEmpty,
                              viewModel.isRecording,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          // 동적 버튼 (모드와 상태에 따라 변경)
                          _buildActionButton(context, viewModel.isEmpty),
                        ],
                      ),
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
