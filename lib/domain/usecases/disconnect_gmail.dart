import 'package:expensetrackerpro/domain/repositories/gmail_repository.dart';

class DisconnectGmail {
  const DisconnectGmail(this._repository);

  final GmailRepository _repository;

  Future<void> call() => _repository.disconnect();
}
