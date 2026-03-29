import 'package:expensetrackerpro/core/transactions/email_transaction_parser.dart';
import 'package:expensetrackerpro/domain/entities/email_message_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses finance emails into transactions', () {
    final messages = [
      EmailMessageItem(
        sender: 'Amazon Pay <alerts@amazon.in>',
        subject: 'Payment received',
        snippet: 'INR 1,299 spent on your latest Amazon order.',
        dateLabel: '29/03/2026',
        occurredAt: DateTime(2026, 3, 29, 11, 30),
      ),
    ];

    final parsed = EmailTransactionParser.parse(messages);

    expect(parsed, hasLength(1));
    expect(parsed.first.merchant, 'Amazon');
    expect(parsed.first.amount, 1299);
    expect(parsed.first.category, 'Shopping');
    expect(parsed.first.sourceChannels, contains('gmail'));
  });

  test('does not parse due reminders as transactions', () {
    final messages = [
      EmailMessageItem(
        sender: 'HDFC Bank <alerts@hdfcbank.com>',
        subject: 'Credit card bill due reminder',
        snippet: 'Your total due is INR 8,420 and payment due on 05/04/2026.',
        dateLabel: '29/03/2026',
        occurredAt: DateTime(2026, 3, 29, 11, 30),
      ),
    ];

    final parsed = EmailTransactionParser.parse(messages);

    expect(parsed, isEmpty);
  });

  test('parses HDFC debit mail with merchant and category', () {
    final messages = [
      EmailMessageItem(
        sender: 'HDFC Bank <alerts@hdfcbank.com>',
        subject: 'Your card has been debited',
        snippet:
            'INR 482.00 has been debited on your card at Swiggy using HDFC Bank Credit Card.',
        dateLabel: '29/03/2026',
        occurredAt: DateTime(2026, 3, 29, 13, 00),
      ),
    ];

    final parsed = EmailTransactionParser.parse(messages);

    expect(parsed, hasLength(1));
    expect(parsed.first.merchant, 'Swiggy');
    expect(parsed.first.category, 'Food');
    expect(parsed.first.isCredit, isFalse);
  });

  test('parses UPI app transfers with provider naming', () {
    final messages = [
      EmailMessageItem(
        sender: 'PhonePe <support@phonepe.com>',
        subject: 'Payment successful',
        snippet: 'INR 265 paid to Uber via PhonePe UPI.',
        dateLabel: '29/03/2026',
        occurredAt: DateTime(2026, 3, 29, 14, 15),
      ),
    ];

    final parsed = EmailTransactionParser.parse(messages);

    expect(parsed, hasLength(1));
    expect(parsed.first.merchant, 'Uber');
    expect(parsed.first.category, 'Travel');
  });

  test('parses salary credit as income', () {
    final messages = [
      EmailMessageItem(
        sender: 'SBI <alerts@sbibank.com>',
        subject: 'Salary credited',
        snippet: 'Salary credited to your account. INR 42000 received today.',
        dateLabel: '29/03/2026',
        occurredAt: DateTime(2026, 3, 29, 9, 00),
      ),
    ];

    final parsed = EmailTransactionParser.parse(messages);

    expect(parsed, hasLength(1));
    expect(parsed.first.category, 'Income');
    expect(parsed.first.isCredit, isTrue);
  });
}
