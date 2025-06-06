import 'package:flutter/material.dart';
import '../components/messages/message_list.dart';
import '../components/messages/message_list_view_model.dart';

class ChatScreen extends StatefulWidget {
  final MessageListViewModel? messageListViewModel;
  
  const ChatScreen({
    super.key, 
    this.messageListViewModel,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;  // 탭 전환 시에도 상태를 유지하도록 설정

  @override
  Widget build(BuildContext context) {
    super.build(context);  // AutomaticKeepAliveClientMixin 사용 시 필수
    return MessageList(viewModel: widget.messageListViewModel);
  }
}
