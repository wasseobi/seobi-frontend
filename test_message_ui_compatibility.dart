import 'lib/repositories/backend/models/message.dart';
import 'lib/repositories/local_database/models/message_role.dart';

// MessageType enum 정의 (UI에서 사용하는 것과 동일)
enum MessageType { text, action, card }

void main() {
  print('=== Message 모델 → UI 호환성 테스트 ===\n');

  // 1. 사용자 메시지 테스트
  testUserMessage();

  print('\n' + '=' * 50 + '\n');

  // 2. AI 텍스트 메시지 테스트
  testAITextMessage();

  print('\n' + '=' * 50 + '\n');

  // 3. AI 액션 메시지 테스트
  testAIActionMessage();

  print('\n' + '=' * 50 + '\n');

  // 4. AI 카드 메시지 테스트
  testAICardMessage();

  print('\n=== 테스트 완료 ===');
}

void testUserMessage() {
  print('📱 사용자 메시지 테스트');

  // Message 객체 생성
  final userMessage = Message(
    id: 'user_msg_1',
    sessionId: 'test_session',
    content: '안녕하세요, 오늘 날씨가 어때요?',
    role: MessageRole.user,
    timestamp: DateTime.now(),
  );

  print('✅ Message 객체 생성 성공');
  print('   - id: ${userMessage.id}');
  print('   - content: ${userMessage.content}');
  print('   - role: ${userMessage.role}');
  print('   - timestamp: ${userMessage.timestamp}');

  // UI에서 기대하는 형태로 변환 시도
  try {
    final uiData = {
      'isUser': userMessage.role == MessageRole.user,
      'text': userMessage.content,
      'messageType': MessageType.text, // 사용자는 항상 text
      'timestamp': userMessage.formattedTimestamp,
    };

    print('\n✅ UI 형태 변환 성공:');
    print('   - isUser: ${uiData['isUser']}');
    print('   - text: ${uiData['text']}');
    print('   - messageType: ${uiData['messageType']}');
    print('   - timestamp: ${uiData['timestamp']}');

    // UserMessage 위젯에 필요한 데이터 확인
    print('\n🎯 UserMessage 위젯 호환성:');
    print('   - message: ${uiData['text']} ✅');
    print('   - isSentByUser: ${uiData['isUser']} ✅');
  } catch (e) {
    print('❌ UI 형태 변환 실패: $e');
  }
}

void testAITextMessage() {
  print('🤖 AI 텍스트 메시지 테스트');

  // AI 응답 Message 객체 생성
  final aiMessage = Message(
    id: 'ai_msg_1',
    sessionId: 'test_session',
    content: '안녕하세요! 오늘 서울 날씨는 맑고 기온은 22도입니다.',
    role: MessageRole.assistant,
    timestamp: DateTime.now(),
    extensions: {
      'messageType': 'text', // UI에서 기대하는 messageType
    },
  );

  print('✅ AI Message 객체 생성 성공');
  print('   - content: ${aiMessage.content}');
  print('   - extensions: ${aiMessage.extensions}');

  // UI 형태로 변환 시도
  try {
    final uiData = {
      'isUser': aiMessage.role == MessageRole.user,
      'text': aiMessage.content,
      'messageType': _extractMessageType(aiMessage),
      'timestamp': aiMessage.formattedTimestamp,
      'actions': aiMessage.extensions?['actions'],
      'card': aiMessage.extensions?['card'],
    };

    print('\n✅ UI 형태 변환 성공:');
    print('   - isUser: ${uiData['isUser']}');
    print('   - text: ${uiData['text']}');
    print('   - messageType: ${uiData['messageType']}');
    print('   - timestamp: ${uiData['timestamp']}');

    // AssistantMessage 위젯에 필요한 데이터 확인
    print('\n🎯 AssistantMessage 위젯 호환성:');
    print('   - message: ${uiData['text']} ✅');
    print('   - type: ${uiData['messageType']} ✅');
    print('   - timestamp: ${uiData['timestamp']} ✅');
    print('   - actions: ${uiData['actions']} ✅ (null이지만 정상)');
    print('   - card: ${uiData['card']} ✅ (null이지만 정상)');
  } catch (e) {
    print('❌ UI 형태 변환 실패: $e');
  }
}

void testAIActionMessage() {
  print('🎬 AI 액션 메시지 테스트');

  // 액션 버튼이 있는 AI 메시지
  final actionMessage = Message(
    id: 'ai_action_1',
    sessionId: 'test_session',
    content: '오늘은 어떤 활동을 하고 싶으신가요?',
    role: MessageRole.assistant,
    timestamp: DateTime.now(),
    extensions: {
      'messageType': 'action',
      'actions': [
        {'icon': '📚', 'text': '독서하기'},
        {'icon': '🎬', 'text': '영화 보기'},
        {'icon': '🏃', 'text': '운동하기'},
        {'icon': '👨‍🍳', 'text': '요리하기'},
      ],
    },
  );

  print('✅ AI Action Message 객체 생성 성공');
  print('   - content: ${actionMessage.content}');
  print('   - extensions: ${actionMessage.extensions}');

  // UI 형태로 변환 시도
  try {
    final uiData = {
      'isUser': actionMessage.role == MessageRole.user,
      'text': actionMessage.content,
      'messageType': _extractMessageType(actionMessage),
      'timestamp': actionMessage.formattedTimestamp,
      'actions': actionMessage.extensions?['actions'],
      'card': actionMessage.extensions?['card'],
    };

    print('\n✅ UI 형태 변환 성공:');
    print('   - messageType: ${uiData['messageType']}');
    print('   - actions: ${uiData['actions']}');

    // AssistantMessage 위젯 호환성 확인
    print('\n🎯 AssistantMessage (Action) 위젯 호환성:');
    final actions = uiData['actions'] as List?;
    if (actions != null && actions.isNotEmpty) {
      print('   - actions 개수: ${actions.length} ✅');
      print('   - 첫 번째 액션: ${actions[0]} ✅');
    } else {
      print('   - actions: null ❌');
    }
  } catch (e) {
    print('❌ UI 형태 변환 실패: $e');
  }
}

void testAICardMessage() {
  print('📋 AI 카드 메시지 테스트');

  // 카드가 있는 AI 메시지
  final cardMessage = Message(
    id: 'ai_card_1',
    sessionId: 'test_session',
    content: '오늘 일정은 다음과 같습니다:',
    role: MessageRole.assistant,
    timestamp: DateTime.now(),
    extensions: {
      'messageType': 'card',
      'card': {
        'title': '프로젝트 회의',
        'time': '오후 2:00 - 3:30',
        'location': '회의실 3층',
      },
      'actions': [
        {'icon': '📝', 'text': '메모 추가하기'},
        {'icon': '🔔', 'text': '알림 설정하기'},
      ],
    },
  );

  print('✅ AI Card Message 객체 생성 성공');
  print('   - content: ${cardMessage.content}');
  print('   - extensions: ${cardMessage.extensions}');

  // UI 형태로 변환 시도
  try {
    final uiData = {
      'isUser': cardMessage.role == MessageRole.user,
      'text': cardMessage.content,
      'messageType': _extractMessageType(cardMessage),
      'timestamp': cardMessage.formattedTimestamp,
      'actions': cardMessage.extensions?['actions'],
      'card': cardMessage.extensions?['card'],
    };

    print('\n✅ UI 형태 변환 성공:');
    print('   - messageType: ${uiData['messageType']}');
    print('   - card: ${uiData['card']}');
    print('   - actions: ${uiData['actions']}');

    // AssistantMessage 위젯 호환성 확인
    print('\n🎯 AssistantMessage (Card) 위젯 호환성:');
    final card = uiData['card'] as Map<String, dynamic>?;
    final actions = uiData['actions'] as List?;

    if (card != null) {
      print('   - card title: ${card['title']} ✅');
      print('   - card time: ${card['time']} ✅');
      print('   - card location: ${card['location']} ✅');
    } else {
      print('   - card: null ❌');
    }

    if (actions != null && actions.isNotEmpty) {
      print('   - actions 개수: ${actions.length} ✅');
    } else {
      print('   - actions: null ❌');
    }
  } catch (e) {
    print('❌ UI 형태 변환 실패: $e');
  }
}

// MessageType 추출 헬퍼 함수
MessageType _extractMessageType(Message message) {
  final typeString = message.extensions?['messageType'] as String?;

  switch (typeString) {
    case 'text':
      return MessageType.text;
    case 'action':
      return MessageType.action;
    case 'card':
      return MessageType.card;
    default:
      return MessageType.text; // 기본값
  }
}
