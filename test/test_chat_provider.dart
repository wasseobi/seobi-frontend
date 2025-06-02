// ChatProvider 기능 테스트 (실제 모델 클래스 사용)
//
// 이 파일은 ChatProvider의 기본 기능들이 정상적으로 작동하는지
// 확인하기 위한 테스트 스크립트입니다.
// 실제 Message, Session, MessageRole 클래스를 사용합니다.

import 'dart:async';
// 실제 모델 클래스들 import
import 'lib/repositories/backend/models/message.dart';
import 'lib/repositories/backend/models/session.dart';
import 'lib/repositories/local_database/models/message_role.dart';

// Flutter의 debugPrint 대신 일반 print 사용을 위한 헬퍼
void debugPrint(String message) => print(message);

/// Mock ConversationService (테스트용)
/// 실제 Message 객체를 반환하도록 수정
class MockConversationService {
  Future<Message> sendMessage({
    required String sessionId,
    required String content,
  }) async {
    // 실제 API 호출 대신 목 응답 반환
    await Future.delayed(Duration(milliseconds: 500)); // 네트워크 지연 시뮬레이션

    // 실제 Message 객체 생성
    return Message(
      id: 'mock_ai_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      content: '테스트 AI 응답: $content에 대한 답변입니다.',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      extensions: {
        'messageType': content.contains('액션') ? 'action' : 'text',
        if (content.contains('액션'))
          'actions': [
            {'icon': '🎯', 'text': '목표 설정'},
            {'icon': '📝', 'text': '계획 작성'},
          ],
      },
    );
  }
}

/// Mock MessageType enum (테스트용)
enum MockMessageType { text, action, card }

/// 간단한 ChatProvider 테스트 클래스
/// 실제 Message 클래스를 사용하도록 수정
class ChatProviderTest {
  final MockConversationService _conversationService =
      MockConversationService();

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentSessionId;

  // Getters
  List<Map<String, dynamic>> get messages =>
      _messages.map(_messageToUIFormat).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get messageCount => _messages.length;
  String? get currentSessionId => _currentSessionId;
  bool get hasMessages => _messages.isNotEmpty;

  /// 사용자 메시지 전송 (테스트용)
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      print('[Test] 빈 메시지는 전송할 수 없습니다');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      print('[Test] 메시지 전송 시작: "$text"');

      // 1. 사용자 메시지 즉시 추가 (실제 Message 객체)
      final userMessage = Message(
        id: _generateMessageId(),
        sessionId: _currentSessionId ?? _generateSessionId(),
        content: text,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      _addMessage(userMessage);

      // 세션 ID가 없었다면 새로 생성된 것으로 설정
      if (_currentSessionId == null) {
        _currentSessionId = userMessage.sessionId;
        print('[Test] 새 세션 생성: $_currentSessionId');
      }

      // 2. AI 응답 요청 (Mock, 하지만 실제 Message 반환)
      print('[Test] AI 응답 요청 중...');
      final aiMessage = await _conversationService.sendMessage(
        sessionId: _currentSessionId!,
        content: text,
      );

      // 3. AI 응답 메시지 추가
      _addMessage(aiMessage);

      print('[Test] AI 응답 완료: "${aiMessage.contentPreview}"');
    } catch (e) {
      _setError('메시지 전송 실패: $e');
      print('[Test] 메시지 전송 오류: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 샘플 메시지들로 초기화 (테스트용)
  void loadSampleMessages() {
    _messages.clear();
    _currentSessionId = _generateSessionId();

    final sampleMessages = _generateSampleMessages();
    _messages.addAll(sampleMessages);

    print('[Test] ${sampleMessages.length}개 샘플 메시지 로드');
  }

  /// 메시지 목록 지우기
  void clearMessages() {
    _messages.clear();
    _currentSessionId = null;
    _clearError();
    print('[Test] 메시지 목록 초기화');
  }

  // 내부 헬퍼 메서드들
  Map<String, dynamic> _messageToUIFormat(Message message) {
    return {
      'isUser': message.role == MessageRole.user,
      'text': message.content ?? '',
      'messageType': _extractMessageType(message),
      'timestamp': message.formattedTimestamp,
      'actions': message.extensions?['actions'],
      'card': message.extensions?['card'],
      'id': message.id,
      'sessionId': message.sessionId,
    };
  }

  MockMessageType _extractMessageType(Message message) {
    final typeString = message.extensions?['messageType'] as String?;

    switch (typeString) {
      case 'text':
        return MockMessageType.text;
      case 'action':
        return MockMessageType.action;
      case 'card':
        return MockMessageType.card;
      default:
        return MockMessageType.text;
    }
  }

  void _addMessage(Message message) {
    _messages.add(message);
    print('[Test] 메시지 추가: ${message.contentPreview}');
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      print('[Test] 로딩 상태: $loading');
    }
  }

  void _setError(String error) {
    _error = error;
    print('[Test] 에러 설정: $error');
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      print('[Test] 에러 상태 클리어');
    }
  }

  String _generateMessageId() {
    return 'test_msg_${DateTime.now().millisecondsSinceEpoch}_${_messages.length}';
  }

  String _generateSessionId() {
    return 'test_session_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 실제 Message 객체를 사용한 샘플 메시지 생성
  List<Message> _generateSampleMessages() {
    final now = DateTime.now();
    final sessionId = _currentSessionId!;
    final messages = <Message>[];

    // 사용자 메시지 1
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: sessionId,
        content: '안녕하세요, 오늘 날씨가 어때요?',
        role: MessageRole.user,
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
    );

    // AI 텍스트 응답
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: sessionId,
        content: '안녕하세요! 오늘 서울 날씨는 맑고 기온은 22도입니다.',
        role: MessageRole.assistant,
        timestamp: now.subtract(const Duration(minutes: 4)),
        extensions: {'messageType': 'text'},
      ),
    );

    // 사용자 메시지 2
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: sessionId,
        content: '액션 버튼 테스트',
        role: MessageRole.user,
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
    );

    // AI 액션 응답
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: sessionId,
        content: '오늘은 어떤 활동을 하고 싶으신가요?',
        role: MessageRole.assistant,
        timestamp: now.subtract(const Duration(minutes: 2)),
        extensions: {
          'messageType': 'action',
          'actions': [
            {'icon': '📚', 'text': '독서하기'},
            {'icon': '🎬', 'text': '영화 보기'},
            {'icon': '🏃', 'text': '운동하기'},
            {'icon': '👨‍🍳', 'text': '요리하기'},
          ],
        },
      ),
    );

    // 사용자 메시지 3 (카드 테스트용)
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: sessionId,
        content: '오늘 일정 알려줘',
        role: MessageRole.user,
        timestamp: now.subtract(const Duration(minutes: 1)),
      ),
    );

    // AI 카드 응답
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: sessionId,
        content: '오늘 일정은 다음과 같습니다:',
        role: MessageRole.assistant,
        timestamp: now,
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
      ),
    );

    return messages;
  }

  /// 실제 Message 클래스의 편의 메서드들 테스트
  void testMessageHelperMethods() {
    print('\n🔧 Message 클래스 편의 메서드 테스트');

    if (_messages.isNotEmpty) {
      final userMsg = _messages.first;
      final aiMsg =
          _messages.where((m) => m.role == MessageRole.assistant).first;

      print('   ✅ 사용자 메시지 확인:');
      print('     - isUserMessage: ${userMsg.isUserMessage}');
      print('     - roleDisplayName: ${userMsg.roleDisplayName}');
      print('     - contentPreview: "${userMsg.contentPreview}"');
      print('     - formattedTimestamp: ${userMsg.formattedTimestamp}');

      print('   ✅ AI 메시지 확인:');
      print('     - isAssistantMessage: ${aiMsg.isAssistantMessage}');
      print('     - roleDisplayName: ${aiMsg.roleDisplayName}');
      print('     - contentPreview: "${aiMsg.contentPreview}"');
      print('     - formattedTimestamp: ${aiMsg.formattedTimestamp}');
    }
  }
}

// 실제 테스트 실행
void main() async {
  print('=== ChatProvider 기능 테스트 시작 (실제 모델 사용) ===\n');

  final chatProvider = ChatProviderTest();

  // 1. 초기 상태 테스트
  print('📋 1. 초기 상태 테스트');
  print('   - 메시지 개수: ${chatProvider.messageCount}');
  print('   - 로딩 상태: ${chatProvider.isLoading}');
  print('   - 에러 상태: ${chatProvider.error}');
  print('   - 세션 ID: ${chatProvider.currentSessionId}');
  print('   - 메시지 존재: ${chatProvider.hasMessages}');

  print('\n' + '=' * 50 + '\n');

  // 2. 샘플 메시지 로드 테스트 (더 많은 메시지 포함)
  print('📝 2. 샘플 메시지 로드 테스트');
  chatProvider.loadSampleMessages();
  print('   - 로드된 메시지 개수: ${chatProvider.messageCount}');
  print('   - 세션 ID: ${chatProvider.currentSessionId}');

  // 메시지 목록 출력
  final messages = chatProvider.messages;
  print('\n   📋 로드된 메시지들:');
  for (int i = 0; i < messages.length; i++) {
    final msg = messages[i];
    final sender = msg['isUser'] ? '👤' : '🤖';
    final text = msg['text'] as String;
    final preview = text.length > 30 ? '${text.substring(0, 30)}...' : text;
    final type = msg['messageType'];

    print('   ${i + 1}. $sender [$type]: $preview');

    if (msg['actions'] != null) {
      final actions = msg['actions'] as List;
      print(
        '      └─ 액션 ${actions.length}개: ${actions.map((a) => a['text']).join(', ')}',
      );
    }

    if (msg['card'] != null) {
      final card = msg['card'] as Map<String, dynamic>;
      print('      └─ 카드: ${card['title']}');
    }
  }

  // 실제 Message 클래스 메서드 테스트
  chatProvider.testMessageHelperMethods();

  print('\n' + '=' * 50 + '\n');

  // 3. 실시간 메시지 전송 테스트
  print('💬 3. 실시간 메시지 전송 테스트');

  print('\n🔄 메시지 전송 중...');
  await chatProvider.sendMessage('테스트 메시지입니다');

  print('\n   📊 전송 후 상태:');
  print('   - 총 메시지 개수: ${chatProvider.messageCount}');
  print('   - 로딩 상태: ${chatProvider.isLoading}');
  print('   - 에러 상태: ${chatProvider.error}');

  print('\n🔄 액션 메시지 전송 중...');
  await chatProvider.sendMessage('액션 버튼을 보여주세요');

  print('\n   📊 액션 메시지 전송 후:');
  print('   - 총 메시지 개수: ${chatProvider.messageCount}');

  // 최근 메시지들 출력
  final recentMessages = chatProvider.messages.skip(6).toList();
  print('\n   📋 새로 추가된 메시지들:');
  for (int i = 0; i < recentMessages.length; i++) {
    final msg = recentMessages[i];
    final sender = msg['isUser'] ? '👤' : '🤖';
    final text = msg['text'] as String;
    final preview = text.length > 30 ? '${text.substring(0, 30)}...' : text;
    final type = msg['messageType'];

    print('   ${i + 7}. $sender [$type]: $preview');

    if (msg['actions'] != null) {
      final actions = msg['actions'] as List;
      print(
        '      └─ 액션 ${actions.length}개: ${actions.map((a) => a['text']).join(', ')}',
      );
    }
  }

  print('\n' + '=' * 50 + '\n');

  // 4. 메시지 클리어 테스트
  print('🗑️  4. 메시지 클리어 테스트');
  chatProvider.clearMessages();
  print('   - 클리어 후 메시지 개수: ${chatProvider.messageCount}');
  print('   - 세션 ID: ${chatProvider.currentSessionId}');
  print('   - 메시지 존재: ${chatProvider.hasMessages}');

  print('\n=== 모든 테스트 완료! (실제 Message 클래스 사용) ===');
}
