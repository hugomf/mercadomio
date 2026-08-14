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
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_MockResponse.${invocation.memberName}');
}

class _MockRequest implements HttpClientRequest {
  _MockRequest(this.url);

  final Uri url;

  @override
  final HttpHeaders headers = _MockHeaders();

  @override
  bool followRedirects = false;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = false;

  @override
  Future<HttpClientResponse> close() async {
    return _MockResponse(_responseBodyFor(url), 0);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final _ in stream) {}
  }

  @override
  void add(List<int> data) {}

  @override
  void write(Object? object) {}

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  String _responseBodyFor(Uri url) {
    final path = url.path;
    if (path.contains('/api/cart')) {
      final now = DateTime.now().toUtc().toIso8601String();
      return json.encode({
        'id': 'guest-cart',
        'userId': null,
        'items': <Object>[],
        'createdAt': now,
        'updatedAt': now,
      });
    }
    if (path == '/api/products') {
      // CategoryService.getFilteredProducts expects {data, total}
      return json.encode({'data': <Object>[], 'total': 0});
    }
    // categories, reviews, related products, etc. are lists
    return '[]';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_MockRequest.${invocation.memberName}');
}

class _MockHttpClient implements HttpClient {
  _MockHttpClient();

  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockRequest(url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_MockHttpClient.${invocation.memberName}');
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Replace the test binding's HTTP block (returns 400 for everything)
    // with a mock that answers the API calls the app makes in its first
    // frame. Must be set inside the test body, after the binding is ready.
    HttpOverrides.global = _MockHttpOverrides();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify our main widgets exist
    expect(find.text('Tianguis Botis'), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}