import 'package:expensetrackerpro/domain/entities/sms_message_item.dart';
import 'package:expensetrackerpro/domain/repositories/sms_inbox_repository.dart';

class GetRelevantSmsMessages {
  const GetRelevantSmsMessages(this._repository);

  final SmsInboxRepository _repository;

  Future<List<SmsMessageItem>> call() => _repository.getRelevantMessages();
}
