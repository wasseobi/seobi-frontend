import 'package:flutter/material.dart';
import 'package:seobi_app/services/conversation/history_service.dart';
import 'package:seobi_app/repositories/backend/models/message.dart';
import 'messages/user_message.dart';
import 'messages/tool_call_message.dart';
import 'messages/tool_result_message.dart';
import 'messages/assistant_message.dart';
import 'messages/error_message.dart';

class MessageList extends StatefulWidget {
  final String? sessionId;
  final ScrollController? scrollController;

  const MessageList({super.key, this.sessionId, this.scrollController});

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late final ScrollController _scrollController;
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _scrollListener() {
    final currentShow = _scrollController.hasClients && _scrollController.offset > 300;
    if (currentShow != _showScrollButton) {
      setState(() {
        _showScrollButton = currentShow;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HistoryService(),
      builder: (context, child) {
        return Stack(
          children: [
            _buildMessageListView(context),
            if (_showScrollButton)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'scrollToBottom',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black54,
                  elevation: 2,
                  onPressed: _scrollToBottom,
                  child: const Icon(Icons.arrow_downward),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleRefresh() async {
    final historyService = HistoryService();
    if (historyService.hasMoreSessions) {
      await historyService.fetchPaginatedSessions(5); // 한 번에 5개 세션씩 로드
    }
  }

  Widget _buildMessageListView(BuildContext context) {
    final historyService = HistoryService();
    final allSessions = historyService.sessions;
    final pendingMessage = historyService.pendingUserMessage;

    // 지정된 세션 ID가 있는 경우 해당 세션부터 시작
    int startSessionIndex = 0;
    if (widget.sessionId != null) {
      startSessionIndex = allSessions.indexWhere((s) => s.id == widget.sessionId);
      if (startSessionIndex == -1) startSessionIndex = 0;
    }

    // 표시할 세션들과 메시지들을 준비
    final sessionsToShow = allSessions.sublist(startSessionIndex);
    List<Message> allMessages = [];

    // 이미 로드된 세션들의 메시지만 표시
    for (final session in sessionsToShow) {
      if (session.isLoaded) {
        allMessages.addAll(session.messages);
      }
    }

    // 메시지를 시간순으로 정렬 (최신 메시지가 먼저 오도록)
    allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: _buildMessagesListView(allMessages, pendingMessage),
    );
  }

  Widget _buildMessagesListView(List<Message> messages, String? pendingMessage) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      reverse: true,
      controller: _scrollController,
      itemCount: messages.length + (pendingMessage != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (pendingMessage != null && index == 0) {
          return UserMessage(content: [pendingMessage]);
        }

        final actualIndex = pendingMessage != null ? index - 1 : index;
        final message = messages[actualIndex];
        return _buildMessageWidget(message);
      },
    );
  }

  Widget _buildMessageWidget(Message message) {
    switch (message.type) {
      case MessageType.user:
        return UserMessage(content: [message.content]);
      case MessageType.assistant:
        return AssistantMessage(content: [message.content]);
      case MessageType.tool_call:
        return ToolCallMessage(
          title: message.title ?? 'Unknown Tool',
          content: [message.content],
        );
      case MessageType.tool_result:
        return ToolResultMessage(content: [message.content]);
      case MessageType.error:
        return ErrorMessage(content: [message.content]);
    }
  }
}
