enum GmailConnectionStatus { connected, signedOut, unsupported }

class GmailConnectionState {
  const GmailConnectionState({
    required this.status,
    required this.title,
    required this.description,
    this.email,
  });

  final GmailConnectionStatus status;
  final String title;
  final String description;
  final String? email;

  bool get isConnected => status == GmailConnectionStatus.connected;

  bool get isUnsupported => status == GmailConnectionStatus.unsupported;

  factory GmailConnectionState.connected(String email) {
    return GmailConnectionState(
      status: GmailConnectionStatus.connected,
      title: 'Gmail connected',
      description:
          'Read-only Gmail access is active for finance-related email scanning.',
      email: email,
    );
  }

  factory GmailConnectionState.signedOut() {
    return const GmailConnectionState(
      status: GmailConnectionStatus.signedOut,
      title: 'Connect Gmail',
      description:
          'Sign in with Gmail to scan bank alerts, invoices, and payment emails in read-only mode.',
    );
  }

  factory GmailConnectionState.unsupported() {
    return const GmailConnectionState(
      status: GmailConnectionStatus.unsupported,
      title: 'Gmail not available here',
      description:
          'Gmail read-only access is supported on mobile platforms after Google sign-in is configured.',
    );
  }
}
