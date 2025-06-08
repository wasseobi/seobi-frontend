// 메시지 타입을 정의하는 열거형
enum MessageType {
  text,      // 기본 텍스트 메시지
  action,    // 챗봇 동작 메시지 (legacy)
  card,      // 카드가 포함된 메시지
  tool_calls, // 도구 호출 메시지
  toolmessage, // 도구 실행 결과 메시지
}
