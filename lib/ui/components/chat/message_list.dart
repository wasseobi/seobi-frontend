import 'package:flutter/material.dart';
import 'package:seobi_app/services/conversation/history_service.dart';
import 'package:seobi_app/repositories/backend/models/message.dart';
import 'package:seobi_app/ui/components/chat/messages/summary_message.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
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
    final currentShow =
        _scrollController.hasClients && _scrollController.offset > 300;
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
          alignment: Alignment.bottomCenter,
          children: [
            _buildMessageListView(context),
            if (_showScrollButton)
              Positioned(
                bottom:
                    AppDimensions.borderRadiusLarge +
                    AppDimensions.paddingSmall,
                child: FloatingActionButton(
                  mini: true,
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
      startSessionIndex = allSessions.indexWhere(
        (s) => s.id == widget.sessionId,
      );
      if (startSessionIndex == -1) startSessionIndex = 0;
    }

    // 표시할 세션들과 메시지들을 준비
    final sessionsToShow = allSessions.sublist(startSessionIndex);
    List<Message> allMessages = [];

    // 이미 로드된 세션들의 메시지만 표시
    for (final session in sessionsToShow) {
      if (session.isLoaded) {
        if (session.finishAt != null) {
          final summaryMessage = Message(
            id: 'summary-${session.id}',
            sessionId: session.id,
            type: MessageType.summary,
            title: session.title,
            content: session.description != null ? session.description! : '',
            timestamp: session.startAt,
            sessionFinishedAt: session.finishAt,
          );
          allMessages.add(summaryMessage);
        }
        allMessages.addAll(session.messages);
      }
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: _buildMessagesListView(
        allMessages,
        pendingMessage,
        historyService.isGenerating,
      ),
    );
  }

  Widget _buildMessagesListView(
    List<Message> messages,
    String? pendingMessage,
    bool isGenerating,
  ) {
    final count =
        messages.length + (pendingMessage != null || isGenerating ? 1 : 0);

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: AppDimensions.paddingLarge + AppDimensions.borderRadiusLarge,
      ),
      reverse: true,
      controller: _scrollController,
      itemCount: count,
      itemBuilder: (context, index) {
        if (pendingMessage != null && index == 0) {
          return UserMessage(content: [pendingMessage], isPending: true);
        }

        if (isGenerating && index == 0) {
          return Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Row(
              children: [
                SizedBox(
                  width: AppDimensions.progressIndicatorMedium,
                  height: AppDimensions.progressIndicatorMedium,
                  child: const CircularProgressIndicator(
                    color: AppColors.main100,
                  ),
                ),
              ],
            ),
          );
        }

        final actualIndex =
            (pendingMessage != null || isGenerating) ? index - 1 : index;
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
        return AssistantMessage(
          content: [message.content],
          timestamp: message.timestamp,
        );
      case MessageType.toolCall:
        return ToolCallMessage(
          title: message.title ?? '도구 호출',
          content: [message.content],
        );
      case MessageType.toolResult:
        return ToolResultMessage(
          title: message.title ?? '도구 실행 결과',
          content: [message.content],
        );
      case MessageType.error:
        return ErrorMessage(content: [message.content]);
      case MessageType.summary:
        return SummaryMessage(
          content: [message.content],
          title: message.title ?? '세션이 종료되었습니다.',
          description:
              message.content.isNotEmpty
                  ? message.content
                  : '세션 내용을 요약하는 중이니 잠시 기다려주세요...',
          startDate: message.timestamp,
          endDate: message.sessionFinishedAt!,
        );
    }
  }
}
