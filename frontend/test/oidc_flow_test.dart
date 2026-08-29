import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/services/oidc_flow.dart';

void main() {
  group('Pkce', () {
    test('generates verifier within RFC 7636 length bounds', () {
      final pair = Pkce.generate();
      expect(pair.verifier.length, inInclusiveRange(43, 128));
      expect(pair.verifier, matches(RegExp(r'^[A-Za-z0-9\-._~]+$')));
    });

    test('challenge is BASE64URL(SHA256(verifier)) without padding', () {
      // Vector from RFC 7636 appendix B.
      const verifier =
          'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      const expectedChallenge = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';
      expect(Pkce.challengeFromVerifier(verifier), expectedChallenge);
    });

    test('generate produces distinct pairs', () {
      expect(Pkce.generate().verifier, isNot(Pkce.generate().verifier));
    });
  });

  group('Authorize URL', () {
    test('includes all required OIDC PKCE parameters', () {
      final uri = OidcFlow.buildAuthorizeUri(
        authorizationEndpoint: 'https://idp.test/oauth/authorize',
        clientId: 'mercadomio-storefront',
        redirectUri: 'http://localhost:3000/auth/callback',
        scope: 'openid profile email offline_access',
        state: 'st4te',
        codeChallenge: 'ch4llenge',
      );

      expect(uri.toString(), startsWith('https://idp.test/oauth/authorize'));
      expect(uri.queryParameters['client_id'], 'mercadomio-storefront');
      expect(uri.queryParameters['redirect_uri'],
          'http://localhost:3000/auth/callback');
      expect(uri.queryParameters['response_type'], 'code');
      expect(uri.queryParameters['scope'],
          'openid profile email offline_access');
      expect(uri.queryParameters['state'], 'st4te');
      expect(uri.queryParameters['code_challenge'], 'ch4llenge');
      expect(uri.queryParameters['code_challenge_method'], 'S256');
    });
  });

  group('Callback handling', () {
    late OidcFlow flow;
    late Uri? openedUrl;

    setUp(() {
      openedUrl = null;
      flow = OidcFlow(
        config: const OidcConfig(
          issuer: 'https://idp.test',
          clientId: 'mercadomio-storefront',
          redirectUri: 'http://localhost:3000/auth/callback',
        ),
        httpClient: MockClient((request) async {
          if (request.url.toString() == 'https://idp.test/oauth/token') {
            expect(request.method, equalsIgnoringCase('POST'));
            final body = Uri(query: request.body).queryParameters;
            expect(body['grant_type'], 'authorization_code');
            expect(body['code'], 'the-code');
            expect(body['redirect_uri'], 'http://localhost:3000/auth/callback');
            return http.Response(
              jsonEncode({
                'access_token': 'at-123',
                'token_type': 'Bearer',
                'expires_in': 3600,
                'refresh_token': 'rt-456',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('not found', 404);
        }),
        openBrowser: (uri) async => openedUrl = uri,
      );
    });

    test('startLogin opens browser with stored state and verifier', () async {
      await flow.startLogin();

      expect(openedUrl, isNotNull);
      expect(openedUrl!.queryParameters['client_id'],
          'mercadomio-storefront');
      expect(flow.pendingState, isNotEmpty);
      expect(flow.pendingVerifier, isNotEmpty);
    });

    test('successful callback exchanges code and returns session', () async {
      await flow.startLogin();

      final session = await flow.handleCallback(
        code: 'the-code',
        state: flow.pendingState,
      );

      expect(session.accessToken, 'at-123');
      expect(session.refreshToken, 'rt-456');
      // State is single-use.
      expect(flow.pendingState, isEmpty);
    });

    test('rejects callback with mismatched state', () async {
      await flow.startLogin();

      expect(
        () => flow.handleCallback(code: 'the-code', state: 'evil-state'),
        throwsA(isA<OidcException>()),
      );
    });

    test('propagates provider error from callback params', () async {
      expect(
        () => flow.handleCallback(error: 'access_denied'),
        throwsA(isA<OidcException>()),
      );
    });

    test('surfaces token endpoint failures', () async {
      await flow.startLogin();

      final failing = OidcFlow(
        config: flow.config,
        httpClient: MockClient((request) async =>
            http.Response('{"error":"invalid_grant"}', 400)),
        openBrowser: flow.openBrowser,
      );
      failing
        ..pendingState = flow.pendingState
        ..pendingVerifier = flow.pendingVerifier;

      expect(
        () => failing.handleCallback(
            code: 'the-code', state: flow.pendingState),
        throwsA(isA<OidcException>()),
      );
    });
  });
}
