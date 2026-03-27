import 'package:expensetrackerpro/domain/entities/email_message_item.dart';
import 'package:expensetrackerpro/domain/entities/gmail_connection_state.dart';

abstract class GmailRepository {
  Future<GmailConnectionState> getConnectionState();

  Future<GmailConnectionState> connectReadOnly();

  Future<void> disconnect();

  Future<List<EmailMessageItem>> getRelevantMessages();
}
