class SmsMessageItem {
  const SmsMessageItem({
    required this.sender,
    required this.body,
    required this.dateLabel,
  });

  final String sender;
  final String body;
  final String dateLabel;
}
