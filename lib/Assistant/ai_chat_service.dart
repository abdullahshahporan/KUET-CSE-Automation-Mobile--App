import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/ai_config.dart';
import '../services/session_service.dart';
import 'teacher_assistant_data_service.dart';

class AiChatResponse {
  final String answer;
  final String source;

  const AiChatResponse({required this.answer, required this.source});
}

class AiChatService {
  AiChatService._();

  static Future<AiChatResponse> ask(String message) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      return const AiChatResponse(
        answer: 'Please write a question first.',
        source: 'local',
      );
    }

    final endpoint = AiConfig.assistantEndpoint.trim();
    if (endpoint.isNotEmpty) {
      return _askServerAssistant(endpoint, cleanMessage);
    }

    final teacherDataIntent = TeacherAssistantDataService.detectIntent(
      cleanMessage,
    );
    if (teacherDataIntent != null) {
      return AiChatResponse(
        answer: await TeacherAssistantDataService.answer(teacherDataIntent),
        source: teacherDataIntent.name,
      );
    }

    return const AiChatResponse(
      answer:
          'The AI endpoint is not configured yet. I can already answer schedule questions like "What is my today\'s schedule?"',
      source: 'setup',
    );
  }

  static Future<AiChatResponse> _askServerAssistant(
    String endpoint,
    String message,
  ) async {
    final client = HttpClient();
    try {
      final request = await client
          .postUrl(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 10));

      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'message': message,
          'userId': SessionService.currentUserId,
          'userName': SessionService.currentEmail ?? 'Mobile user',
          'role': _normalizedRole(SessionService.currentRole),
        }),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AiChatResponse(
          answer: json['error']?.toString() ?? 'Assistant request failed.',
          source: 'server',
        );
      }

      final data = json['data'] as Map<String, dynamic>?;
      return AiChatResponse(
        answer: data?['answer']?.toString() ?? 'No answer was returned.',
        source: data?['source']?.toString() ?? 'server',
      );
    } on TimeoutException {
      return const AiChatResponse(
        answer: 'The assistant took too long to respond. Please try again.',
        source: 'server',
      );
    } catch (e) {
      return AiChatResponse(
        answer: 'Assistant connection failed: ${e.toString()}',
        source: 'server',
      );
    } finally {
      client.close(force: true);
    }
  }

  static String _normalizedRole(String? role) {
    switch ((role ?? '').toUpperCase()) {
      case 'ADMIN':
        return 'admin';
      case 'HEAD':
        return 'head';
      case 'TEACHER':
      default:
        return 'teacher';
    }
  }
}
