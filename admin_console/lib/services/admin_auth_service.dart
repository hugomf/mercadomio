import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'oidc_flow.dart';

/// OIDC authentication for the admin console against the userbrew IdP.
///
/// Plain singleton (no GetX): the console is a plain MaterialApp app.
class AdminAuthService {
  AdminAuthService._();

  static final AdminAuthService instance = AdminAuthService._();

  static const String adminGroup = 'mercadomio-admin';

  final _storage = GetStorage('auth');
  OidcFlow? _flow;

  String? _accessToken;
  bool _isAdmin = false;

  String? get token => _accessToken;
  bool get isAuthenticated => _accessToken != null;
  bool get isAdmin => _isAdmin;

  OidcConfig get _config {
    return const OidcConfig(
      issuer: 'http://localhost:8090',
      clientId: 'mercadomio-admin',
      redirectUri: 'http://localhost:3100/auth/callback',
    );
  }

  OidcFlow get flow {
    _flow ??= OidcFlow(
      config: _config,
      httpClient: _client,
      openBrowser: (uri) async {
        if (!await launchUrl(uri, webOnlyWindowName: '_self')) {
          throw const OidcException('No se pudo abrir el navegador');
        }
      },
    );
    return _flow!;
  }

  set httpClient(http.Client client) => _client = client;
  http.Client _client = http.Client();
  /// Redirects the browser to the hosted login UI.
  Future<void> startLogin() => flow.startLogin();

  /// Completes the callback, stores the session and evaluates the admin role
  /// from the token's group claims. Server-side enforcement remains in the API.
  Future<bool> handleCallback({String? code, String? state, String? error}) async {
    try {
      final session =
          await flow.handleCallback(code: code, state: state, error: error);
      _accessToken = session.accessToken;
      _isAdmin = _tokenRoles(_accessToken!).contains(adminGroup);
      await _storage.write('accessToken', _accessToken);
      return true;
    } on OidcException {
      rethrow;
    }
  }

  /// Restores a persisted session, if any.
  void restore() {
    final stored = _storage.read<String>('accessToken');
    if (stored != null && stored.isNotEmpty) {
      _accessToken = stored;
      _isAdmin = _tokenRoles(stored).contains(adminGroup);
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _isAdmin = false;
    await _storage.remove('accessToken');
  }

  Map<String, dynamic> _tokenClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return const {};
      final normalized = base64Url.normalize(parts[1].padRight(
          (parts[1].length + 3) & ~3, '='));
      return jsonDecode(utf8.decode(base64Url.decode(normalized)))
          as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  List<String> _tokenRoles(String token) {
    final roles = _tokenClaims(token)['roles'];
    if (roles is List) return roles.map((r) => r.toString()).toList();
    return const [];
  }
}
