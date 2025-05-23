import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:seobi_app/repositories/local_database/local_database_repository.dart';
import 'package:seobi_app/repositories/local_database/models/session.dart';
import 'package:seobi_app/repositories/local_database/models/message.dart';
import 'package:seobi_app/repositories/local_database/models/message_role.dart';

// PathProvider 모의 구현
class PathProviderMock extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => './test_db';

  @override
  Future<String?> getApplicationSupportPath() async => './test_support';

  @override
  Future<String?> getApplicationCachePath() async => './test_cache';

  @override
  Future<String?> getExternalStoragePath() async => './test_external';

  @override
  Future<List<String>?> getExternalCachePaths() async => [
    './test_external_cache',
  ];

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => ['./test_external_storage'];

  @override
  Future<String?> getDownloadsPath() async => './test_downloads';

  @override
  Future<String?> getTemporaryPath() async => './test_temp';
}

void main() {
  late LocalDatabaseRepository repository;
  DatabaseFactory? originalFactory;

  setUpAll(() async {
    // FFI 초기화
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      // 현재 팩토리가 설정되어 있다면 저장
      try {
        originalFactory = databaseFactory;
      } catch (e) {
        // 팩토리가 아직 설정되지 않았다면 무시
      }
      // FFI 팩토리로 설정
      databaseFactory = databaseFactoryFfi;
    }
    
    // PathProvider 모의 객체 설정
    PathProviderPlatform.instance = PathProviderMock();
  });

  tearDownAll(() {
    // 원래 팩토리가 있었다면 복원
    if (originalFactory != null) {
      databaseFactory = originalFactory;
    }
  });

  setUp(() async {
    // 인메모리 데이터베이스로 리포지토리 초기화
    repository = LocalDatabaseRepository();
    await repository.initialize(inMemoryDatabasePath);
  });
  tearDown(() async {
    // 각 테스트 후 데이터베이스 닫기
    await repository.close();
  });

  group('Session operations', () {
    final testStartTime = DateTime.now();
    final testSession = Session(
      id: 'test_session_1',
      startAt: testStartTime,
      title: 'Test Session',
      description: 'Test Description',
    );

    test('insertSession - success', () async {
      await repository.insertSession(testSession);
      final result = await repository.getSession(testSession.id);
      expect(result?.id, equals(testSession.id));
      expect(result?.title, equals(testSession.title));
      expect(result?.startAt?.toIso8601String(), equals(testSession.startAt?.toIso8601String()));
    });

    test('insertSession - duplicate id fails', () async {
      await repository.insertSession(testSession);
      expect(
        () => repository.insertSession(testSession),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('insertSessions - batch insert success', () async {
      final sessions = List.generate(
        3,
        (i) => Session(
          id: 'test_session_$i',
          startAt: testStartTime.add(Duration(minutes: i)),
          title: 'Test Session $i',
        ),
      );

      await repository.insertSessions(sessions);
      for (final session in sessions) {
        final result = await repository.getSession(session.id);
        expect(result?.id, equals(session.id));
      }
    });

    test('getSession - non-existent session returns null', () async {
      final result = await repository.getSession('non_existent');
      expect(result, isNull);
    });

    test('getSessions - returns all sessions ordered by start_at DESC', () async {
      final sessions = List.generate(
        3,
        (i) => Session(
          id: 'test_session_$i',
          startAt: testStartTime.add(Duration(minutes: i)),
          title: 'Test Session $i',
        ),
      );

      await repository.insertSessions(sessions);
      final results = await repository.getSessions();
      
      expect(results, hasLength(sessions.length));
      // 날짜 역순 정렬 확인
      for (var i = 0; i < results.length - 1; i++) {
        expect(
          results[i].startAt!.isAfter(results[i + 1].startAt!),
          isTrue,
          reason: '세션이 시작 시간 역순으로 정렬되어야 합니다',
        );
      }
    });

    test('deleteSession - success', () async {
      await repository.insertSession(testSession);
      await repository.deleteSession(testSession.id);
      final result = await repository.getSession(testSession.id);
      expect(result, isNull);
    });

    test('deleteSessions - batch delete success', () async {
      final sessions = List.generate(
        3,
        (i) => Session(
          id: 'test_session_$i',
          startAt: testStartTime.add(Duration(minutes: i)),
          title: 'Test Session $i',
        ),
      );

      await repository.insertSessions(sessions);
      await repository.deleteSessions(sessions.map((s) => s.id).toList());

      for (final session in sessions) {
        final result = await repository.getSession(session.id);
        expect(result, isNull);
      }
    });
  });

  group('Message operations', () {
    late Session testSession;
    late Message testMessage;
    final testStartTime = DateTime.now();

    setUp(() async {
      testSession = Session(
        id: 'test_session_1',
        startAt: testStartTime,
        title: 'Test Session',
      );
      await repository.insertSession(testSession);

      testMessage = Message(
        id: 'test_message_1',
        sessionId: testSession.id,
        content: 'Test Message',
        role: MessageRole.user,
        timestamp: testStartTime,
      );
    });

    test('insertMessage - success', () async {
      await repository.insertMessage(testMessage);
      final result = await repository.getMessage(testMessage.id);
      
      expect(result?.id, equals(testMessage.id));
      expect(result?.content, equals(testMessage.content));
      expect(result?.timestamp.toIso8601String(), equals(testMessage.timestamp.toIso8601String()));
    });

    test('insertMessage - fails with non-existent session (foreign key)', () async {
      final invalidMessage = Message(
        id: 'test_message_2',
        sessionId: 'non_existent_session',
        content: 'Test Message',
        role: MessageRole.user,
        timestamp: testStartTime,
      );

      expect(
        () => repository.insertMessage(invalidMessage),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('insertMessages - batch insert success', () async {
      final messages = List.generate(
        3,
        (i) => Message(
          id: 'test_message_$i',
          sessionId: testSession.id,
          content: 'Test Message $i',
          role: MessageRole.user,
          timestamp: testStartTime.add(Duration(minutes: i)),
        ),
      );

      await repository.insertMessages(messages);
      for (final message in messages) {
        final result = await repository.getMessage(message.id);
        expect(result?.id, equals(message.id));
        expect(result?.timestamp.toIso8601String(), equals(message.timestamp.toIso8601String()));
      }
    });

    test('getSessionMessages returns messages in correct timestamp order', () async {
      final messages = [
        Message(
          id: 'test_message_1',
          sessionId: testSession.id,
          content: 'First Message',
          role: MessageRole.user,
          timestamp: testStartTime.subtract(const Duration(minutes: 2)),
        ),
        Message(
          id: 'test_message_2',
          sessionId: testSession.id,
          content: 'Second Message',
          role: MessageRole.assistant,
          timestamp: testStartTime.subtract(const Duration(minutes: 1)),
        ),
        Message(
          id: 'test_message_3',
          sessionId: testSession.id,
          content: 'Third Message',
          role: MessageRole.user,
          timestamp: testStartTime,
        ),
      ];

      await repository.insertMessages(messages);
      final retrievedMessages = await repository.getSessionMessages(testSession.id);

      expect(retrievedMessages.length, equals(3));
      // 시간순 정렬 확인
      for (var i = 0; i < retrievedMessages.length - 1; i++) {
        expect(
          retrievedMessages[i].timestamp.isBefore(retrievedMessages[i + 1].timestamp), 
          isTrue,
          reason: '메시지가 타임스탬프 순서대로 정렬되어야 합니다',
        );
      }
    });

    test('messages are deleted when session is deleted (foreign key cascade)',
      () async {
        await repository.insertMessage(testMessage);
        await repository.deleteSession(testSession.id);

        final messageResult = await repository.getMessage(testMessage.id);
        final sessionResult = await repository.getSession(testSession.id);

        expect(messageResult, isNull);
        expect(sessionResult, isNull);
      },
    );

    test('getMessage returns null for non-existent message', () async {
      final result = await repository.getMessage('non_existent_message');
      expect(result, isNull);
    });

    test('getSessionMessages returns empty list for non-existent session',
      () async {
        final messages = await repository.getSessionMessages('non_existent_session');
        expect(messages, isEmpty);
      },
    );
  });

  group('Platform specific tests', () {
    test('database initialization succeeds on supported platforms', () async {
      final db = await repository.database;
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('web platform throws UnsupportedError', () async {
      if (kIsWeb) {
        expect(() => repository.database, throwsA(isA<UnsupportedError>()));
      }
    });
  });
}
