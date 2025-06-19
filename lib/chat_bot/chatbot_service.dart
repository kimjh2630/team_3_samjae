import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  final String apiUrl;
  ChatbotService({this.apiUrl = 'https://a562-183-109-28-98.ngrok-free.app/chat/'});

  Future<String> sendMessage(String prompt, String langCode) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt, 'lang': langCode}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['reply'] ?? '오류: 응답이 없습니다.';
    } else {
      return '서버 오류: ${response.statusCode}';
    }
  }

  /// 답변에서 명령어(예: 병원찾기, 약국찾기 등)를 파싱하는 예시 메서드
  String? parseCommand(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('병원') || lower.contains('hospital')) return 'hospital';
    if (lower.contains('약국') || lower.contains('pharmacy')) return 'pharmacy';
    if (lower.contains('응급') || lower.contains('emergency')) return 'emergency';
    if (lower.contains('예약') || lower.contains('reserve') || lower.contains('booking')) return 'reservation';
    return null;
  }
}