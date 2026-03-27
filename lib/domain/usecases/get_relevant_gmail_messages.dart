import 'package:expensetrackerpro/domain/entities/email_message_item.dart';
import 'package:expensetrackerpro/domain/repositories/gmail_repository.dart';

class GetRelevantGmailMessages {
  const GetRelevantGmailMessages(this._repository);

  final GmailRepository _repository;

  Future<List<EmailMessageItem>> call() => _repository.getRelevantMessages();
}
