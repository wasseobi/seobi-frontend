import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../components/navigation/custom_navigation_bar.dart';
import '../components/drawer/custom_drawer.dart';
import '../components/auth/sign_in_bottom_sheet.dart';
import '../../services/auth/auth_service.dart';
import '../components/input_bar/input_bar.dart';
import '../components/messages/assistant/message_types.dart'; // MessageType enum import
import '../utils/measure_size.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();

  // 입력창 관련
  final TextEditingController _chatController = TextEditingController();
  // FocusNode를 final로 선언
  final FocusNode _focusNode = FocusNode();

  // 메시지 리스트
  final List<Map<String, dynamic>> _messages = [];
  // InputBar 관련 높이를 동적으로 추적하기 위한 변수
  double _inputBarHeight = 64; // 기본값 설정

  @override
  void initState() {
    super.initState();
    // 초기 예시 메시지 20개 생성
    _generateSampleMessages();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // AuthService는 main에서 이미 초기화되었으므로 여기서는 상태만 확인합니다
      if (!_authService.isLoggedIn && mounted) {
        _showSignInBottomSheet();
      }
    });
  }  // 예시 메시지 20개 생성하는 메서드
  void _generateSampleMessages() {
    // 현재 시간에서 10분씩 이전 시간으로 설정하여 대화 흐름 표현
    final now = DateTime.now();
    
    // 기본 텍스트 메시지 샘플
    final List<Map<String, dynamic>> conversations = [
      {
        'userMsg': '안녕하세요, 자기소개해주세요.',
        'aiMsg': '안녕하세요! 저는 서비(Seobi)라고 합니다. 언어 학습, 문서 작업, 일상 질문 등 다양한 주제에 대해 도움을 드릴 수 있어요. 무엇을 도와드릴까요?',
        'messageType': MessageType.text
      },
      {
        'userMsg': '오늘 날씨가 어때요?',
        'aiMsg': '죄송합니다. 저는 실시간 날씨 정보에 접근할 수 없습니다. 하지만 날씨에 대해 궁금하시다면 기상청 웹사이트나 날씨 앱을 확인해보시는 것을 추천드립니다.',
        'messageType': MessageType.text
      },
      {
        'userMsg': '영어로 "안녕하세요"는 뭐예요?',
        'aiMsg': '"안녕하세요"는 영어로 "Hello"입니다. 비슷한 인사말로는 "Hi", "Hey", "Greetings" 등이 있습니다. 좀 더 정중하게 말하고 싶으시면 "Good morning/afternoon/evening"도 사용할 수 있습니다.',
        'messageType': MessageType.text
      }
    ];
    
    // 액션 버튼이 포함된 메시지 샘플
    final List<Map<String, dynamic>> actionMessages = [
      {
        'userMsg': '오늘 뭐하지?',
        'aiMsg': '오늘은 어떤 활동을 하고 싶으신가요?',
        'messageType': MessageType.action,
        'actions': [
          {'icon': '📚', 'text': '독서하기'},
          {'icon': '🎬', 'text': '영화 보기'},
          {'icon': '🏃', 'text': '운동하기'},
          {'icon': '👨‍🍳', 'text': '요리하기'}
        ]
      },
      {
        'userMsg': '추천해줘',
        'aiMsg': '어떤 분야의 추천이 필요하세요?',
        'messageType': MessageType.action,
        'actions': [
          {'icon': '🍽️', 'text': '맛집 추천'},
          {'icon': '📱', 'text': '앱 추천'},
          {'icon': '📺', 'text': '영화/드라마 추천'},
          {'icon': '📖', 'text': '책 추천'}
        ]
      },
      {
        'userMsg': '언어 학습 방법 알려줘',
        'aiMsg': '어떤 언어를 배우고 싶으신가요?',
        'messageType': MessageType.action,
        'actions': [
          {'icon': '🇺🇸', 'text': '영어'},
          {'icon': '🇯🇵', 'text': '일본어'},
          {'icon': '🇨🇳', 'text': '중국어'},
          {'icon': '🇫🇷', 'text': '프랑스어'}
        ]
      }
    ];
    
    // 카드가 포함된 메시지 샘플
    final List<Map<String, dynamic>> cardMessages = [
      {
        'userMsg': '오늘 일정 알려줘',
        'aiMsg': '오늘 일정은 다음과 같습니다:',
        'messageType': MessageType.card,
        'card': {
          'title': '프로젝트 회의',
          'time': '오후 2:00 - 3:30',
          'location': '회의실 3층'
        },
        'actions': [
          {'icon': '📝', 'text': '메모 추가하기'},
          {'icon': '🔔', 'text': '알림 설정하기'}
        ]
      },
      {
        'userMsg': '내일 약속 있어?',
        'aiMsg': '내일 약속이 있습니다:',
        'messageType': MessageType.card,
        'card': {
          'title': '점심 약속',
          'time': '오후 12:30 - 14:00',
          'location': '시청역 인근 식당'
        }
      },
      {
        'userMsg': '다음 주 계획은?',
        'aiMsg': '다음 주 일정은 다음과 같습니다:',
        'messageType': MessageType.card,
        'card': {
          'title': '프로젝트 데드라인',
          'time': '2025년 6월 5일',
          'location': '회사'
        },
        'actions': [
          {'icon': '📋', 'text': '할 일 목록 보기'},
          {'icon': '✏️', 'text': '일정 수정하기'}
        ]
      }
    ];
    
    // 모든 메시지 유형을 하나의 리스트로 합침
    final allMessages = [...conversations, ...actionMessages, ...cardMessages];
    
    int messageCount = 0;
    int messageIndex = 0;
    
    // 20개의 메시지 생성
    while (messageCount < 20) {
      // 모든 타입의 메시지를 순환하며 사용
      final messageData = allMessages[messageIndex % allMessages.length];
      
      // 시간 설정 - 이전 메시지일수록 더 과거 시간으로 표시
      final messageTime = now.subtract(Duration(minutes: 10 * (messageCount ~/ 2)));
      final formattedTime = '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')} 전송됨';
      
      // 사용자 메시지
      _messages.add({
        'isUser': true,
        'text': messageData['userMsg'],
        'messageType': MessageType.text, // 사용자는 항상 텍스트 메시지
        'timestamp': formattedTime,
      });
      messageCount++;
      
      // 메시지 수가 20개 이상이면 중단
      if (messageCount >= 20) break;
      
      // AI 응답 메시지 - 30초 후 응답한 것처럼 표시
      final responseTime = messageTime.add(const Duration(seconds: 30));
      final responseFormattedTime = '${responseTime.hour.toString().padLeft(2, '0')}:${responseTime.minute.toString().padLeft(2, '0')} 전송됨';
      
      // MessageType에 따라 다른 형태의 응답 메시지 생성
      final Map<String, dynamic> aiMessage = {
        'isUser': false,
        'text': messageData['aiMsg'],
        'messageType': messageData['messageType'],
        'timestamp': responseFormattedTime,
      };
      
      // 액션 버튼이 있는 경우 추가
      if (messageData['messageType'] == MessageType.action && messageData.containsKey('actions')) {
        aiMessage['actions'] = messageData['actions'];
      }
      
      // 카드가 있는 경우 추가
      if (messageData['messageType'] == MessageType.card && messageData.containsKey('card')) {
        aiMessage['card'] = messageData['card'];
        
        // 카드에 액션 버튼이 있는 경우 추가
        if (messageData.containsKey('actions')) {
          aiMessage['actions'] = messageData['actions'];
        }
      }
      
      _messages.add(aiMessage);
      messageCount++;
      
      // 다음 메시지로
      messageIndex++;
    }
    
    // 메시지 순서를 시간순으로 정렬 (오래된 것부터)
    _messages.sort((a, b) {
      final timeA = a['timestamp'] as String;
      final timeB = b['timestamp'] as String;
      return timeA.compareTo(timeB);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chatController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showSignInBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // 사용자가 임의로 닫을 수 없도록 함
      enableDrag: false, // 드래그로 닫기 방지
      builder: (context) => const SignInBottomSheet(),
    );
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  void _handleSend() {
    final message = _chatController.text.trim();
    if (message.isNotEmpty) {
      debugPrint("보낸 메시지: $message");
      setState(() {
        // 사용자 메시지를 리스트 끝에 추가
        _messages.add({
          'isUser': true,
          'text': message,
          'messageType': MessageType.text, // 사용자 메시지는 항상 text 타입
          'timestamp': '${DateTime.now().hour}:${DateTime.now().minute} 전송됨',
        });

        // 테스트를 위한 AI 응답 메시지를 리스트 끝에 추가
        _messages.add({
          'isUser': false,
          'text': '테스트 응답입니다.',
          'messageType': MessageType.text,
          'timestamp': '${DateTime.now().hour}:${DateTime.now().minute} 전송됨',
        });
      });
      _chatController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const CustomDrawer(),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  CustomNavigationBar(
                    selectedTabIndex: _selectedIndex,
                    onTabChanged: _onTabTapped,
                    onMenuPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: _inputBarHeight),
                          child: Column(
                            children: [
                              Expanded(child: ChatScreen(messages: _messages)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: _inputBarHeight),
                          child: const Center(child: Text('보관함 화면')),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: _inputBarHeight),
                          child: const Center(child: Text('통계 화면')),
                        ),
                      ],
                    ),
                  ),
                ],
              ), // 입력 바
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: MeasureSize(
                  onChange: (size) {
                    // 입력 바의 높이가 변경될 때 상태 업데이트
                    if (mounted && size.height != _inputBarHeight) {
                      setState(() {
                        _inputBarHeight = size.height;
                      });
                    }
                  },
                  child: InputBar(
                    controller: _chatController,
                    focusNode: _focusNode,
                    onSend: _handleSend,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
