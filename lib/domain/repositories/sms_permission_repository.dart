import 'package:expensetrackerpro/domain/entities/sms_permission_state.dart';

abstract class SmsPermissionRepository {
  Future<SmsPermissionState> getStatus();

  Future<SmsPermissionState> requestPermission();

  Future<bool> openSettings();
}
