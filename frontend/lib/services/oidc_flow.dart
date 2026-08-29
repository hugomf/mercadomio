import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// PKCE helpers per RFC 7636.
class Pkce {
  static final _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  static final _random = Random.secure();

  /// Generates a code verifier (43–128 chars) and its S256 challenge.
  static ({String verifier, String challenge}) generate() {
    final verifier =
        List.generate(64, (_) => _chars[_random.nextInt(_chars.length)]).join();
    return (verifier: verifier, challenge: challengeFromVerifier(verifier));
  }

  /// Returns BASE64URL(SHA256(verifier)) without padding.
  static String challengeFromVerifier(String verifier) {
    final digest = sha256.convert(ascii.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}

/// Immutable OIDC client configuration for this app instance.
class OidcConfig {
  final String issuer;
  final String clientId;
  final String redirectUri;
  final String scope;

  const OidcConfig({
    required this.issuer,
    required this.clientId,
    required this.redirectUri,
    this.scope = 'openid profile email offline_access',
  });

  Uri get authorizationEndpoint => Uri.parse('$issuer/oauth/authorize');
  Uri get tokenEndpoint => Uri.parse('$issuer/oauth/token');
}

/// A stored token session returned by the token endpoint.
class OidcSession {
  final String accessToken;
  final String? refreshToken;
  final int expiresIn;

  const OidcSession({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn = 0,
  });
}

/// Thrown for any OIDC flow failure with a human-readable message.
class OidcException implements Exception {
  final String message;
  const OidcException(this.message);

  @override
  String toString() => message;
}

/// Pure OIDC Authorization Code + PKCE flow logic.
///
/// Browser opening is injected via [openBrowser] and HTTP via [httpClient],
/// keeping the class fully testable.
class OidcFlow {
  final OidcConfig config;
  final http.Client httpClient;
  final Future<void> Function(Uri uri) openBrowser;

  String? _pendingState;
  String? _pendingVerifier;

  OidcFlow({
    required this.config,
    required this.httpClient,
    required this.openBrowser,
  });

  /// The state issued by the last [startLogin] call, if a login is pending.
  String get pendingState => _pendingState ?? '';
  set pendingState(String value) => _pendingState = value.isEmpty ? null : value;

  /// The PKCE verifier paired with the pending state.
  String get pendingVerifier => _pendingVerifier ?? '';
  set pendingVerifier(String value) =>
      _pendingVerifier = value.isEmpty ? null : value;

  /// Builds the authorize URI for the given state/challenge pair.
  static Uri buildAuthorizeUri({
    required String authorizationEndpoint,
    required String clientId,
    required String redirectUri,
    required String scope,
    required String state,
    required String codeChallenge,
  }) {
    return Uri.parse(authorizationEndpoint).replace(queryParameters: {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scope,
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });
  }

  /// Opens the system browser at the authorize endpoint and stores the
  /// PKCE pair until the callback arrives.
  Future<void> startLogin() async {
    final pair = Pkce.generate();
    // Random URL-safe state to bind callback to this login attempt.
    final state = base64Url
        .encode(List.generate(24, (_) => Pkce._random.nextInt(256)))
        .replaceAll('=', '');

    _pendingState = state;
    _pendingVerifier = pair.verifier;

    final uri = buildAuthorizeUri(
      authorizationEndpoint: config.authorizationEndpoint.toString(),
      clientId: config.clientId,
      redirectUri: config.redirectUri,
      scope: config.scope,
      state: state,
      codeChallenge: pair.challenge,
    );
    await openBrowser(uri);
  }

  /// Handles the redirect back from the IdP: validates state, exchanges the
  /// code for tokens, clears the pending pair and returns the session.
  Future<OidcSession> handleCallback({String? code, String? state, String? error}) async {
    if (error != null && error.isNotEmpty) {
      throw OidcException('Login cancelado por el proveedor: $error');
    }
    if (_pendingState == null || _pendingVerifier == null) {
      throw const OidcException('No hay un inicio de sesión pendiente');
    }
    if (state != _pendingState) {
      throw const OidcException('Estado de seguridad inválido (state mismatch)');
    }
    if (code == null || code.isEmpty) {
      throw const OidcException('El proveedor no devolvió un código');
    }

    final session = await exchangeCode(code);
    _pendingState = null;
    _pendingVerifier = null;
    return session;
  }

  /// Exchanges an authorization code for tokens at the token endpoint.
  Future<OidcSession> exchangeCode(String code) async {
    final response = await httpClient.post(
      config.tokenEndpoint,
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': config.redirectUri,
        'client_id': config.clientId,
        'code_verifier': _pendingVerifier ?? '',
      },
    );

    if (response.statusCode != 200) {
      throw OidcException(
          'Falló el canje del código (HTTP ${response.statusCode})');
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = json['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw const OidcException('Respuesta sin access_token');
      }
      return OidcSession(
        accessToken: accessToken,
        refreshToken: json['refresh_token'] as String?,
        expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      );
    } on FormatException {
      throw OidcException(
          'Respuesta inválida del servidor de identidad (HTTP 200 no-JSON)');
    }
  }
}
