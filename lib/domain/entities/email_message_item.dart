class EmailMessageItem {
  const EmailMessageItem({
    required this.sender,
    required this.subject,
    required this.snippet,
    required this.dateLabel,
    required this.occurredAt,
  });

  final String sender;
  final String subject;
  final String snippet;
  final String dateLabel;
  final DateTime occurredAt;
}
