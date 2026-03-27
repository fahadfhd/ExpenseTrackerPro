import 'package:expensetrackerpro/domain/entities/sms_permission_state.dart';
import 'package:expensetrackerpro/domain/repositories/sms_permission_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerSmsPermissionRepository
    implements SmsPermissionRepository {
  const PermissionHandlerSmsPermissionRepository();

  @override
  Future<SmsPermissionState> getStatus() async {
    if (!_supportsSmsPermission) {
      return SmsPermissionState.unsupported();
    }

    final status = await Permission.sms.status;
    return _mapStatus(status);
  }

  @override
  Future<bool> openSettings() {
    if (!_supportsSmsPermission) {
      return Future.value(false);
    }

    return openAppSettings();
  }

  @override
  Future<SmsPermissionState> requestPermission() async {
    if (!_supportsSmsPermission) {
      return SmsPermissionState.unsupported();
    }

    final status = await Permission.sms.request();
    return _mapStatus(status);
  }

  bool get _supportsSmsPermission =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  SmsPermissionState _mapStatus(PermissionStatus status) {
    if (status.isGranted) {
      return SmsPermissionState.granted();
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      return SmsPermissionState.permanentlyDenied();
    }

    return SmsPermissionState.denied();
  }
}
