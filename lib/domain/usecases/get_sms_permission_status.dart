import 'package:expensetrackerpro/domain/entities/sms_permission_state.dart';
import 'package:expensetrackerpro/domain/repositories/sms_permission_repository.dart';

class GetSmsPermissionStatus {
  const GetSmsPermissionStatus(this._repository);

  final SmsPermissionRepository _repository;

  Future<SmsPermissionState> call() => _repository.getStatus();
}
