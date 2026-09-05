import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import 'session_token_store.dart';

/// Routes database requests through the verified server session. No database
/// signing key or service-role credential is ever distributed to the app.
class AuthenticatedDataClient extends http.BaseClient {
  final http.Client _inner;
  AuthenticatedDataClient({http.Client? inner})
    : _inner = inner ?? http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!request.url.path.startsWith('/rest/v1/')) return _inner.send(request);
    final resource = request.url.path.substring('/rest/v1/'.length);
    if (resource.contains('/'))
      throw StateError('Direct database RPC is disabled');
    final uri = Uri.parse(
      '${SupabaseConfig.backendUrl}/api/data/$resource',
    ).replace(query: request.url.query);
    final forwarded = http.Request(request.method, uri);
    forwarded.headers.addAll(request.headers);
    forwarded.headers.remove('apikey');
    final token = await SessionTokenStore.read();
    if (token == null || token.isEmpty)
      throw StateError('Please sign in again');
    forwarded.headers['authorization'] = 'Bearer $token';
    forwarded.bodyBytes = await request.finalize().toBytes();
    return _inner.send(forwarded).timeout(const Duration(seconds: 20));
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
