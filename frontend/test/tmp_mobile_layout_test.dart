import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

class _MockHeaders implements HttpHeaders {
  final Map<String, List<String>> _map = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _map[name] = [value.toString()];
  }

  @override
  void forEach(void Function(String name, List<String> values) f) {
    _map.forEach(f);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_MockHeaders.${invocation.memberName}');
}

class _MockResponse implements HttpClientResponse {
  _MockResponse(String body, int cl)
      : contentLength = cl <= 0 ? utf8.encode(body).length : cl,
        _stream = Stream<List<int>>.fromIterable([utf8.encode(body)]);

  final Stream<List<int>> _stream;
  @override
  final int contentLength;

  @override
  int get statusCode => HttpStatus.ok;
  @override
  String get reasonPhrase => 'OK';
  @override
  HttpHeaders get headers => _headers;
  static final _headers = _MockHeaders();
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => false;
  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];
  @override
  Stream<List<int>> handleError(Function onError,
      {bool Function(dynamic)? test}) {
    return _stream.handleError(onError, test: test);
  }

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError,
      void Function()? onDone,
      bool? cancelOnError}) {
    return _stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_MockResponse.${invocation.memberName}');
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockRequest(url);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_MockHttpClient.${invocation.memberName}');
}

class _MockRequest implements HttpClientRequest {
  _MockRequest(this.url);

  final Uri url;

  @override
  Uri get uri => url;

  @override
  Future<HttpClientResponse> close() async {
    final body = jsonEncode({
      'products': List.generate(8, (i) {
        return {
          'id': i + 1,
          'name': 'Producto de prueba $i',
          'basePrice': 10 + i,
          'category': 'Frutas',
          'images': <String>[],
        };
      }),
      'total': 8,
    });
    final body2 = jsonEncode({'categories': <Object>[]});
    if (url.path.contains('products')) return _MockResponse(body, -1);
    if (url.path.contains('categories')) return _MockResponse(body2, -1);
    return _MockResponse(jsonEncode({'status': 'ok'}), -1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_MockRequest.${invocation.memberName}');
}

void main() {
  testWidgets('Mobile storefront renders without overflow', (tester) async {
    HttpOverrides.global = _MockHttpOverrides();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Mercadomio'), findsWidgets);
    expect(find.byType(Scaffold), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Narrow desktop (800px) storefront renders without overflow',
      (tester) async {
    HttpOverrides.global = _MockHttpOverrides();
    tester.view.physicalSize = const Size(800, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Mercadomio'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}