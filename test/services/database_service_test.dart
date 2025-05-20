import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:seobi_app/models/message.dart';
import 'package:seobi_app/models/message_role.dart';
import 'package:seobi_app/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService db;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  
  setUp(() async {
    // Create a fresh database instance for each test
    db = DatabaseService();
    // Initialize and clear the database
    final database = await db.database;
    await database.execute('DELETE FROM message');
    await database.execute('DELETE FROM session');
  });

  tearDown(() async {
    // Clear the database after each test
    final database = await db.database;
    await database.execute('DELETE FROM message');
    await database.execute('DELETE FROM session');
  });

  group('Session tests', () {
    test('Create session', () async {
      final userId = 'test-user-id';
      final sessionId = await db.createSession(userId);

      expect(sessionId, isNotEmpty);

      final session = await db.getSession(sessionId);
      expect(session, isNotNull);
      expect(session?.userId, equals(userId));
      expect(session?.startAt, isNotNull);
    });

    test('Get session', () async {
      final userId = 'test-user-id';
      final sessionId = await db.createSession(userId);

      final session = await db.getSession(sessionId);
      expect(session, isNotNull);
      expect(session?.id, equals(sessionId));
      expect(session?.userId, equals(userId));
    });

    test('Get sessions list', () async {
      final userId = 'test-user-id';
      await db.createSession(userId);
      await db.createSession(userId);

      final sessions = await db.getSessions(userId);
      expect(sessions.length, equals(2));
      expect(sessions.every((s) => s.userId == userId), isTrue);
    });

    test('Update session', () async {
      final userId = 'test-user-id';
      final sessionId = await db.createSession(userId);
      final session = await db.getSession(sessionId);

      final updatedSession = session!.copyWith(
        title: 'Test Title',
        description: 'Test Description',
        finishAt: DateTime.now(),
      );

      await db.updateSession(updatedSession);

      final fetchedSession = await db.getSession(sessionId);
      expect(fetchedSession?.title, equals('Test Title'));
      expect(fetchedSession?.description, equals('Test Description'));
      expect(fetchedSession?.finishAt, isNotNull);
    });

    test('Delete session', () async {
      final userId = 'test-user-id';
      final sessionId = await db.createSession(userId);

      await db.deleteSession(sessionId);

      final session = await db.getSession(sessionId);
      expect(session, isNull);
    });
  });

  group('Message tests', () {
    late String sessionId;
    late String userId;

    setUp(() async {
      userId = 'test-user-id';
      sessionId = await db.createSession(userId);
    });

    test('Create message', () async {
      final message = Message(
        id: '', // Will be set by the service
        sessionId: sessionId,
        userId: userId,
        content: 'Test message',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      final messageId = await db.createMessage(message);
      expect(messageId, isNotEmpty);

      final savedMessage = await db.getMessage(messageId);
      expect(savedMessage, isNotNull);
      expect(savedMessage?.content, equals('Test message'));
      expect(savedMessage?.role, equals(MessageRole.user));
    });

    test('Get session messages', () async {
      // Create multiple messages
      final messages = [
        Message(
          id: '',
          sessionId: sessionId,
          userId: userId,
          content: 'Message 1',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
        Message(
          id: '',
          sessionId: sessionId,
          userId: userId,
          content: 'Message 2',
          role: MessageRole.assistant,
          timestamp: DateTime.now().add(const Duration(minutes: 1)),
        ),
      ];

      for (final message in messages) {
        await db.createMessage(message);
      }

      final sessionMessages = await db.getSessionMessages(sessionId);
      expect(sessionMessages.length, equals(2));
      expect(sessionMessages.first.content, equals('Message 1'));
      expect(sessionMessages.last.content, equals('Message 2'));
    });

    test('Update message', () async {
      final message = Message(
        id: '',
        sessionId: sessionId,
        userId: userId,
        content: 'Original content',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      final messageId = await db.createMessage(message);
      final savedMessage = await db.getMessage(messageId);

      final updatedMessage = savedMessage!.copyWith(
        content: 'Updated content',
        role: MessageRole.assistant,
      );

      await db.updateMessage(updatedMessage);

      final fetchedMessage = await db.getMessage(messageId);
      expect(fetchedMessage?.content, equals('Updated content'));
      expect(fetchedMessage?.role, equals(MessageRole.assistant));
    });

    test('Delete message', () async {
      final message = Message(
        id: '',
        sessionId: sessionId,
        userId: userId,
        content: 'Test message',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      final messageId = await db.createMessage(message);
      await db.deleteMessage(messageId);

      final fetchedMessage = await db.getMessage(messageId);
      expect(fetchedMessage, isNull);
    });
  });

  group('Integration tests', () {
    test('Delete session cascades to messages', () async {
      final userId = 'test-user-id';
      final sessionId = await db.createSession(userId);

      // Create messages for the session
      final messages = [
        Message(
          id: '',
          sessionId: sessionId,
          userId: userId,
          content: 'Message 1',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
        Message(
          id: '',
          sessionId: sessionId,
          userId: userId,
          content: 'Message 2',
          role: MessageRole.assistant,
          timestamp: DateTime.now().add(const Duration(minutes: 1)),
        ),
      ];

      for (final message in messages) {
        await db.createMessage(message);
      }

      // Verify messages exist
      var sessionMessages = await db.getSessionMessages(sessionId);
      expect(sessionMessages.length, equals(2));

      // Delete session
      await db.deleteSession(sessionId);

      // Verify session is deleted
      final deletedSession = await db.getSession(sessionId);
      expect(deletedSession, isNull);

      // Verify messages are cascade deleted
      sessionMessages = await db.getSessionMessages(sessionId);
      expect(sessionMessages.length, equals(0));
    });

    test('Messages with different roles', () async {
      final userId = 'test-user-id';
      final sessionId = await db.createSession(userId);

      // Create messages with different roles
      final messages = [
        Message(
          id: '',
          sessionId: sessionId,
          userId: userId,
          content: 'User message',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
        Message(
          id: '',
          sessionId: sessionId,
          userId: userId,
          content: 'Assistant message',
          role: MessageRole.assistant,
          timestamp: DateTime.now().add(const Duration(minutes: 1)),
        ),
        Message(
          id: '',
          sessionId: sessionId,
          userId: userId,
          content: 'System message',
          role: MessageRole.system,
          timestamp: DateTime.now().add(const Duration(minutes: 2)),
        ),
        Message(
          id: '',
          sessionId: sessionId,
          userId: userId,
          content: 'Tool message',
          role: MessageRole.tool,
          timestamp: DateTime.now().add(const Duration(minutes: 3)),
        ),
      ];

      for (final message in messages) {
        await db.createMessage(message);
      }

      final sessionMessages = await db.getSessionMessages(sessionId);
      expect(sessionMessages.length, equals(4));
      expect(sessionMessages[0].role, equals(MessageRole.user));
      expect(sessionMessages[1].role, equals(MessageRole.assistant));
      expect(sessionMessages[2].role, equals(MessageRole.system));
      expect(sessionMessages[3].role, equals(MessageRole.tool));
    });
  });
}
