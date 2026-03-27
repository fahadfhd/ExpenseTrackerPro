import 'package:expensetrackerpro/domain/entities/gmail_connection_state.dart';
import 'package:expensetrackerpro/domain/repositories/gmail_repository.dart';

class GetGmailConnectionState {
  const GetGmailConnectionState(this._repository);

  final GmailRepository _repository;

  Future<GmailConnectionState> call() => _repository.getConnectionState();
}
