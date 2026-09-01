// ============================================
// TESTS: ApiService — reintento por 401 + single-flight
// ============================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uniplan/config/api_config.dart';
import 'package:uniplan/services/api_service.dart';

void main() {
  // ApiService es singleton: se limpia el estado relevante antes de cada test.
  final api = ApiService();

  tearDown(() {
    api.clearToken();
    api.setRefreshCallback(() async => false);
  });

  test('un 401 dispara el refresh y reintenta la petición una vez', () async {
    var authed = false;
    var calls = 0;

    api.setHttpClient(MockClient((request) async {
      calls++;
      if (!authed) {
        return http.Response(jsonEncode({'success': false}), 401);
      }
      return http.Response(jsonEncode({'success': true, 'data': 'ok'}), 200);
    }));

    var refreshCalls = 0;
    api.setRefreshCallback(() async {
      refreshCalls++;
      authed = true;
      return true;
    });

    final res = await api.get('/api/tasks');

    expect(res['success'], true);
    expect(refreshCalls, 1);
    expect(calls, 2); // 401 + reintento
  });

  test('varios 401 concurrentes comparten un solo refresh (single-flight)', () async {
    var authed = false;

    api.setHttpClient(MockClient((request) async {
      if (!authed) {
        return http.Response(jsonEncode({'success': false}), 401);
      }
      return http.Response(jsonEncode({'success': true}), 200);
    }));

    var refreshCalls = 0;
    api.setRefreshCallback(() async {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      authed = true;
      return true;
    });

    await Future.wait([
      api.get('/api/tasks'),
      api.get('/api/notes'),
      api.get('/api/grades'),
    ]);

    expect(refreshCalls, 1);
  });

  test('si el refresh falla, el 401 se propaga como ApiException', () async {
    api.setHttpClient(MockClient((request) async {
      return http.Response(jsonEncode({'success': false}), 401);
    }));
    api.setRefreshCallback(() async => false);

    expect(
      () => api.get('/api/tasks'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
    );
  });

  test('un 401 en /auth/refresh no dispara otro refresh (sin bucle)', () async {
    var calls = 0;
    api.setHttpClient(MockClient((request) async {
      calls++;
      return http.Response(jsonEncode({'success': false}), 401);
    }));

    var refreshCalls = 0;
    api.setRefreshCallback(() async {
      refreshCalls++;
      return true;
    });

    await expectLater(
      () => api.post(ApiConfig.refresh, {'refreshToken': 'x'}),
      throwsA(isA<ApiException>()),
    );

    expect(refreshCalls, 0);
    expect(calls, 1);
  });
}
