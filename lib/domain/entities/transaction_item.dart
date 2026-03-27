class TransactionItem {
  const TransactionItem({
    required this.merchant,
    required this.amount,
    required this.category,
    required this.dateLabel,
    required this.source,
    this.isCredit = false,
  });

  final String merchant;
  final int amount;
  final String category;
  final String dateLabel;
  final String source;
  final bool isCredit;
}
