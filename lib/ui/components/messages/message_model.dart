import 'assistant/message_types.dart';

/// 채팅 메시지 데이터 모델
class MessageModel {
  final String text;
  final bool isUser;
  final MessageType messageType;
  final List<Map<String, String>>? actions;  // AssistantMessage에 맞게 타입 지정
  final Map<String, String>? card;  // AssistantMessage에 맞게 타입 지정
  final String? timestamp;

  MessageModel({
    required this.text,
    required this.isUser,
    this.messageType = MessageType.text,
    this.actions,
    this.card,
    this.timestamp,
  });

  /// Map에서 ChatMessageModel 객체로 변환하는 팩토리 메소드
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    // 액션 변환 로직
    List<Map<String, String>>? actionsList;
    if (map['actions'] != null) {
      actionsList = (map['actions'] as List)
          .map((action) => Map<String, String>.from(action as Map))
          .toList();
    }
    
    // 카드 변환 로직
    Map<String, String>? cardMap;
    if (map['card'] != null) {
      cardMap = Map<String, String>.from(map['card'] as Map);
    }
    
    return MessageModel(
      text: map['text'] as String,
      isUser: map['isUser'] as bool,
      messageType: map['messageType'] ?? MessageType.text,
      actions: actionsList,
      card: cardMap,
      timestamp: map['timestamp'] as String?,
    );
  }

  /// ChatMessageModel을 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'messageType': messageType,
      'actions': actions,
      'card': card,
      'timestamp': timestamp,
    };
  }
}
