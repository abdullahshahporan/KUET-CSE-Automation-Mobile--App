import 'dart:convert';
import 'dart:io';
import '../config/supabase_config.dart';
import 'session_token_store.dart';

class AuthenticatedApi {
  AuthenticatedApi._();
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) => send('POST', path, body);
  static Future<Map<String, dynamic>> send(
    String method,
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await SessionTokenStore.read();
    if (token == null || token.isEmpty)
      return {'success': false, 'message': 'Please sign in again.'};
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.openUrl(
        method,
        Uri.parse('${SupabaseConfig.backendUrl}$path'),
      );
      request.headers.contentType = ContentType.json;
      request.headers.set('authorization', 'Bearer $token');
      request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final text = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));
      final result = text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>;
      result['success'] =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          result['success'] != false;
      result['message'] ??= result['error'] ?? 'Request completed';
      return result;
    } catch (_) {
      return {
        'success': false,
        'message': 'The secure service is unavailable. Please try again later.',
      };
    } finally {
      client.close(force: true);
    }
  }
}
