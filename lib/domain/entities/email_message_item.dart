class EmailMessageItem {
  const EmailMessageItem({
    required this.sender,
    required this.subject,
    required this.snippet,
    required this.dateLabel,
  });

  final String sender;
  final String subject;
  final String snippet;
  final String dateLabel;
}
