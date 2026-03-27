import 'dart:convert';

import 'package:expensetrackerpro/domain/entities/email_message_item.dart';
import 'package:expensetrackerpro/domain/entities/gmail_connection_state.dart';
import 'package:expensetrackerpro/domain/repositories/gmail_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleGmailRepository implements GmailRepository {
  GoogleGmailRepository({GoogleSignIn? googleSignIn, http.Client? httpClient})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
      _httpClient = httpClient ?? http.Client();

  static const _scopes = ['https://www.googleapis.com/auth/gmail.readonly'];
  static const _searchQuery =
      '("debited" OR "credited" OR "spent" OR "payment" OR "invoice" OR "upi" OR "transaction") newer_than:180d';

  final GoogleSignIn _googleSignIn;
  final http.Client _httpClient;
  bool _initialized = false;
  GoogleSignInAccount? _account;

  @override
  Future<GmailConnectionState> connectReadOnly() async {
    if (!_supportsGmail) {
      return GmailConnectionState.unsupported();
    }

    await _ensureInitialized();

    _account ??= await _googleSignIn.attemptLightweightAuthentication();
    _account ??= await _googleSignIn.authenticate(scopeHint: _scopes);
    final user = _account;
    if (user == null) return GmailConnectionState.signedOut();

    await user.authorizationClient.authorizeScopes(_scopes);
    return GmailConnectionState.connected(user.email);
  }

  @override
  Future<void> disconnect() async {
    if (!_supportsGmail) return;

    await _ensureInitialized();
    await _googleSignIn.signOut();
    _account = null;
  }

  @override
  Future<GmailConnectionState> getConnectionState() async {
    if (!_supportsGmail) {
      return GmailConnectionState.unsupported();
    }

    await _ensureInitialized();

    _account ??= await _googleSignIn.attemptLightweightAuthentication();
    final user = _account;
    if (user == null) {
      return GmailConnectionState.signedOut();
    }

    final authorization = await user.authorizationClient.authorizationForScopes(
      _scopes,
    );

    if (authorization == null) {
      return GmailConnectionState.signedOut();
    }

    return GmailConnectionState.connected(user.email);
  }

  @override
  Future<List<EmailMessageItem>> getRelevantMessages() async {
    if (!_supportsGmail) {
      return const [];
    }

    await _ensureInitialized();
    _account ??= await _googleSignIn.attemptLightweightAuthentication();
    final user = _account;
    if (user == null) {
      return const [];
    }

    final authorizationHeaders = await user.authorizationClient
        .authorizationHeaders(_scopes);
    if (authorizationHeaders == null || authorizationHeaders.isEmpty) {
      return const [];
    }

    final listUri = Uri.https(
      'gmail.googleapis.com',
      '/gmail/v1/users/me/messages',
      {'q': _searchQuery, 'maxResults': '10'},
    );

    final listResponse = await _httpClient.get(
      listUri,
      headers: authorizationHeaders,
    );

    if (listResponse.statusCode != 200) {
      return const [];
    }

    final listData = jsonDecode(listResponse.body) as Map<String, dynamic>;
    final messages = (listData['messages'] as List<dynamic>? ?? const []);
    final results = <EmailMessageItem>[];

    for (final message in messages) {
      final id = (message as Map<String, dynamic>)['id'] as String?;
      if (id == null) continue;

      final detailUri = Uri.https(
        'gmail.googleapis.com',
        '/gmail/v1/users/me/messages/$id',
        {'format': 'metadata'},
      );

      final detailResponse = await _httpClient.get(
        detailUri,
        headers: authorizationHeaders,
      );

      if (detailResponse.statusCode != 200) continue;

      final detail = jsonDecode(detailResponse.body) as Map<String, dynamic>;
      final payload = detail['payload'] as Map<String, dynamic>? ?? const {};
      final headers = (payload['headers'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final from = _headerValue(headers, 'From') ?? 'Unknown sender';
      final subject = _headerValue(headers, 'Subject') ?? 'No subject';
      final snippet = (detail['snippet'] as String? ?? '').trim();
      final internalDate = int.tryParse(
        detail['internalDate']?.toString() ?? '',
      );

      results.add(
        EmailMessageItem(
          sender: from,
          subject: subject,
          snippet: snippet,
          dateLabel: _formatDate(internalDate),
        ),
      );
    }

    return results;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    await _googleSignIn.initialize();
    _initialized = true;
  }

  bool get _supportsGmail =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String? _headerValue(List<Map<String, dynamic>> headers, String name) {
    for (final header in headers) {
      if ((header['name'] as String?)?.toLowerCase() == name.toLowerCase()) {
        return header['value'] as String?;
      }
    }

    return null;
  }

  String _formatDate(int? milliseconds) {
    if (milliseconds == null) return 'Unknown date';

    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
