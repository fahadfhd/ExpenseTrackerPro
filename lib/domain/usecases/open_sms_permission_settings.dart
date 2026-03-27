import 'package:expensetrackerpro/domain/repositories/sms_permission_repository.dart';

class OpenSmsPermissionSettings {
  const OpenSmsPermissionSettings(this._repository);

  final SmsPermissionRepository _repository;

  Future<bool> call() => _repository.openSettings();
}
