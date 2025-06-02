import 'package:flutter/material.dart';
import '../../utils/chat_provider.dart';
import '../messages/assistant/message_types.dart';

/// 메시지 리스트 표시를 위한 ViewModel
///
/// ChatProvider의 기능을 활용해 메시지 리스트 표시에 필요한
/// 데이터와 기능을 제공합니다. 이 클래스는 UI와 데이터 레이어 사이의
/// 중간 계층 역할을 수행합니다.
class MessageListViewModel extends ChangeNotifier {
  final ChatProvider _chatProvider;
  
  /// 스크롤이 맨 아래에 위치하는지 여부
  bool _isAnchored = true;
  
  /// 생성자
  MessageListViewModel({
    required ChatProvider chatProvider,
  }) : _chatProvider = chatProvider {
    debugPrint('[MessageListViewModel] 초기화 완료');
    
    // ChatProvider의 상태 변화를 감지하여 리스너들에게 알림
    _chatProvider.addListener(_onChatProviderChanged);
  }
  
  /// ChatProvider의 상태 변화 감지 시 호출됨
  void _onChatProviderChanged() {
    // ChatProvider의 상태가 변경되면 ViewModel의 리스너들에게도 알림
    notifyListeners();
    debugPrint('[MessageListViewModel] ChatProvider 상태 변경 감지 및 알림');
  }
  
  /// 메시지 목록 반환
  List<Map<String, dynamic>> get messages => _chatProvider.messages;
  
  /// 메시지 개수
  int get messageCount => _chatProvider.messageCount;
  
  /// 현재 로딩 상태
  bool get isLoading => _chatProvider.isLoading;
  
  /// 에러 메시지
  String? get error => _chatProvider.error;
  
  /// 현재 세션 ID
  String? get currentSessionId => _chatProvider.currentSessionId;
  
  /// 대화가 있는지 여부
  bool get hasMessages => _chatProvider.hasMessages;
  
  /// 스크롤이 맨 아래에 고정되어 있는지 여부
  bool get isAnchored => _isAnchored;
  
  /// 스크롤 앵커 상태 설정
  void setAnchored(bool value) {
    if (_isAnchored != value) {
      _isAnchored = value;
      notifyListeners();
      debugPrint('[MessageListViewModel] isAnchored 상태 변경: $_isAnchored');
    }
  }
  
  /// 스크롤이 맨 아래에서 얼마나 떨어져 있는지 확인하여 앵커 상태 갱신
  void updateAnchoredState(ScrollController scrollController) {
    if (!scrollController.hasClients) return;
    
    // 스크롤 위치가 맨 아래에서 20픽셀 이내인 경우 앵커된 것으로 간주
    const threshold = 20.0;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.offset;
    final isAtBottom = maxScroll - currentScroll <= threshold;
    
    setAnchored(isAtBottom);
  }
  
  /// 메시지 전송
  Future<void> sendMessage(String text) async {
    await _chatProvider.sendMessage(text);
  }
  
  /// 메시지 목록 초기화
  void clearMessages() {
    _chatProvider.clearMessages();
  }
  
  /// 특정 메시지 삭제
  void removeMessage(String messageId) {
    _chatProvider.removeMessage(messageId);
  }
  
  /// 샘플 메시지 로드 (테스트용)
  void loadSampleMessages() {
    _chatProvider.loadSampleMessages();
  }
  
  /// 외부에서 생성된 메시지 설정
  void setMessages(List<Map<String, dynamic>> messages) {
    _chatProvider.setMessages(messages);
  }
  
  /// 특정 인덱스의 메시지 반환
  Map<String, dynamic>? getMessageAtIndex(int index) {
    final messageList = messages;
    if (index >= 0 && index < messageList.length) {
      return messageList[index];
    }
    return null;
  }
  
  /// 메시지가 사용자가 보낸 것인지 확인
  bool isUserMessage(Map<String, dynamic> message) {
    return message['isUser'] == true;
  }
  
  /// 메시지 타입 확인
  MessageType getMessageType(Map<String, dynamic> message) {
    return message['messageType'] as MessageType? ?? MessageType.text;
  }
  
  /// 위젯 정리
  @override
  void dispose() {
    _chatProvider.removeListener(_onChatProviderChanged);
    debugPrint('[MessageListViewModel] dispose 호출');
    super.dispose();
  }
}