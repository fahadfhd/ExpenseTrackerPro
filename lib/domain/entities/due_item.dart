class DueItem {
  const DueItem({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.source,
  });

  final String title;
  final int amount;
  final DateTime dueDate;
  final String source;
}
