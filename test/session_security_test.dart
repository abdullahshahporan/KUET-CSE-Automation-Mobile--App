import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuet_cse_automation/services/authenticated_data_client.dart';
import 'package:kuet_cse_automation/services/session_token_store.dart';
import 'package:kuet_cse_automation/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'user_token': 'legacy-secret'});
  });
  test('private queries fail closed without a server token', () async {
    var called = false;
    final client = AuthenticatedDataClient(
      inner: MockClient((_) async {
        called = true;
        return http.Response('[]', 200);
      }),
    );
    await expectLater(
      client.get(Uri.parse('https://example.invalid/rest/v1/profiles')),
      throwsStateError,
    );
    expect(called, isFalse);
    client.close();
  });
  test(
    'queries use authenticated gateway and do not forward the anon key',
    () async {
      await SessionTokenStore.write('signed-session');
      final client = AuthenticatedDataClient(
        inner: MockClient((request) async {
          expect(request.url.path, '/api/data/notifications');
          expect(request.url.queryParameters['select'], 'id,title');
          expect(request.headers['authorization'], 'Bearer signed-session');
          expect(request.headers.containsKey('apikey'), isFalse);
          return http.Response('[]', 200);
        }),
      );
      await client.get(
        Uri.parse(
          'https://example.invalid/rest/v1/notifications?select=id,title',
        ),
        headers: {'apikey': 'anon-key'},
      );
      client.close();
    },
  );
  test('logout clears secure bearer and legacy preferences', () async {
    await SessionTokenStore.write('signed-session');
    await SessionService.clearSession();
    expect(await SessionTokenStore.read(), isNull);
    expect(
      (await SharedPreferences.getInstance()).getString('user_token'),
      isNull,
    );
  });
}
