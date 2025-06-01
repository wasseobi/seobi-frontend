import 'package:flutter/material.dart';
import 'message_model.dart';
import 'assistant/message_types.dart';

/// 채팅 메시지 리스트를 관리하는 ViewModel
class MessageListViewModel extends ChangeNotifier {
  List<MessageModel> _messages = [];

  /// 메시지 리스트 getter
  List<MessageModel> get messages => _messages;
  
  /// 기본 생성자
  MessageListViewModel() {
    _generateSampleMessages();
  }
  
  /// 특정 메시지 데이터로 초기화하는 생성자
  MessageListViewModel.withMessages(List<MessageModel> messages) {
    _messages = messages;
  }
  /// 간단한 예시 메시지 생성 메서드
  void _generateSampleMessages() {
    final now = DateTime.now();
    
    // 메시지 시간 생성 함수
    String _getFormattedTime(int minutesAgo) {
      final time = now.subtract(Duration(minutes: minutesAgo));
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} 전송됨';
    }

    // 기본 텍스트 메시지
    _messages.add(MessageModel(
      text: '안녕하세요!',
      isUser: true,
      messageType: MessageType.text,
      timestamp: _getFormattedTime(50),
    ));
    
    _messages.add(MessageModel(
      text: '안녕하세요! 저는 서비(Seobi)입니다. 무엇을 도와드릴까요?',
      isUser: false,
      messageType: MessageType.text,
      timestamp: _getFormattedTime(49),
    ));

    // 액션 버튼이 있는 메시지
    _messages.add(MessageModel(
      text: '오늘 뭐하지?',
      isUser: true,
      messageType: MessageType.text,
      timestamp: _getFormattedTime(30),
    ));
    
    _messages.add(MessageModel(
      text: '오늘은 어떤 활동을 하고 싶으신가요?',
      isUser: false,
      messageType: MessageType.action,
      timestamp: _getFormattedTime(29),
      actions: [
        {'icon': '📚', 'text': '독서하기'},
        {'icon': '🎬', 'text': '영화 보기'},
        {'icon': '🏃', 'text': '운동하기'},
      ],
    ));
    
    // 카드 형식의 메시지
    _messages.add(MessageModel(
      text: '내일 일정 알려줘',
      isUser: true,
      messageType: MessageType.text,
      timestamp: _getFormattedTime(10),
    ));
    
    _messages.add(MessageModel(
      text: '내일 일정은 다음과 같습니다:',
      isUser: false,
      messageType: MessageType.card,
      timestamp: _getFormattedTime(9),
      card: {
        'title': '프로젝트 회의',
        'time': '오후 2:00 - 3:30',
        'location': '회의실 3층',
      },
    ));
    
    // 가장 최근 메시지
    _messages.add(MessageModel(
      text: '고마워요!',
      isUser: true,
      messageType: MessageType.text,
      timestamp: _getFormattedTime(5),
    ));
    
    _messages.add(MessageModel(
      text: '천만에요! 다른 도움이 필요하시면 말씀해주세요.',
      isUser: false,
      messageType: MessageType.text,
      timestamp: _getFormattedTime(4),
    ));
  }

  /// Map 형식의 데이터 리스트로 메시지 초기화
  void initWithMapList(List<Map<String, dynamic>> messageList) {
    _messages = messageList.map((map) => MessageModel.fromMap(map)).toList();
    notifyListeners();
  }

  /// 새 메시지 추가
  void addMessage(MessageModel message) {
    _messages.add(message);
    notifyListeners();
  }

  /// Map 형식으로 새 메시지 추가
  void addMessageFromMap(Map<String, dynamic> messageMap) {
    final message = MessageModel.fromMap(messageMap);
    addMessage(message);
  }

  /// 특정 인덱스의 메시지 업데이트
  void updateMessage(int index, MessageModel message) {
    if (index >= 0 && index < _messages.length) {
      _messages[index] = message;
      notifyListeners();
    }
  }  /// 모든 메시지 삭제
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
  
  /// 시간 포맷 문자열을 생성하는 유틸리티 메서드
  String getFormattedTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} 전송됨';
  }
  
  /// 사용자 메시지를 전송하고 AI 응답 생성
  void sendUserMessage(String message) {
    if (message.isEmpty) return;
    
    final formattedTime = getFormattedTime();
    
    // 사용자 메시지 추가
    final userMessage = MessageModel(
      text: message,
      isUser: true,
      messageType: MessageType.text,
      timestamp: formattedTime,
    );
    
    addMessage(userMessage);
    
    // AI 응답 메시지 생성 (실제로는 API 호출 등이 필요)
    _generateAIResponse();
  }
  
  /// 테스트용 AI 응답 메시지 생성
  void _generateAIResponse() {
    final formattedTime = getFormattedTime();
    
    // 테스트용 AI 응답
    final aiMessage = MessageModel(
      text: '테스트 응답입니다.',
      isUser: false,
      messageType: MessageType.text,
      timestamp: formattedTime,
    );
    
    // 약간의 지연 후 응답 추가 (실제 응답 지연 시뮬레이션)
    Future.delayed(const Duration(milliseconds: 500), () {
      addMessage(aiMessage);
    });
  }
}
