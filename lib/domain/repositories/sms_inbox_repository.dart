import 'package:kept/domain/entities/sms_message_item.dart';

abstract class SmsInboxRepository {
  Future<List<SmsMessageItem>> getRelevantMessages();
}
