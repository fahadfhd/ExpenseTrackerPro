import 'package:expensetrackerpro/core/transactions/email_due_parser.dart';
import 'package:expensetrackerpro/domain/entities/email_message_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses credit card due emails into due items', () {
    final messages = [
      EmailMessageItem(
        sender: 'HDFC Bank <alerts@hdfcbank.com>',
        subject: 'Your credit card statement is ready',
        snippet: 'Total due INR 8,420. Payment due on 05/04/2026.',
        dateLabel: '29/03/2026',
        occurredAt: DateTime(2026, 3, 29, 11, 30),
      ),
    ];

    final dues = EmailDueParser.parse(messages);

    expect(dues, hasLength(1));
    expect(dues.first.amount, 8420);
    expect(dues.first.dueDate, DateTime(2026, 4, 5));
  });

  test('parses due emails with month-name date formats', () {
    final messages = [
      EmailMessageItem(
        sender: 'SBI Card <alerts@sbicard.com>',
        subject: 'Your card statement is ready',
        snippet:
            'Total amount due Rs. 12,999. Minimum due Rs. 500. Pay by 07 April 2026.',
        dateLabel: '29/03/2026',
        occurredAt: DateTime(2026, 3, 29, 18, 00),
      ),
    ];

    final dues = EmailDueParser.parse(messages);

    expect(dues, hasLength(1));
    expect(dues.first.amount, 12999);
    expect(dues.first.dueDate, DateTime(2026, 4, 7));
  });
}
