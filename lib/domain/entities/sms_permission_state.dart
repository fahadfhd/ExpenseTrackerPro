enum SmsPermissionStatusType { granted, denied, permanentlyDenied, unsupported }

class SmsPermissionState {
  const SmsPermissionState({
    required this.status,
    required this.title,
    required this.description,
  });

  final SmsPermissionStatusType status;
  final String title;
  final String description;

  bool get isGranted => status == SmsPermissionStatusType.granted;

  bool get needsSettings => status == SmsPermissionStatusType.permanentlyDenied;

  bool get isUnsupported => status == SmsPermissionStatusType.unsupported;

  factory SmsPermissionState.granted() {
    return const SmsPermissionState(
      status: SmsPermissionStatusType.granted,
      title: 'SMS access enabled',
      description:
          'ExpanseTrackerPro can now read transaction alerts and prepare your expense timeline.',
    );
  }

  factory SmsPermissionState.denied() {
    return const SmsPermissionState(
      status: SmsPermissionStatusType.denied,
      title: 'SMS access required',
      description:
          'We only use transaction messages from banks, UPI apps, and cards to build your spending history.',
    );
  }

  factory SmsPermissionState.permanentlyDenied() {
    return const SmsPermissionState(
      status: SmsPermissionStatusType.permanentlyDenied,
      title: 'Enable SMS access in Settings',
      description:
          'Android blocked the prompt. Open app settings and allow SMS so parsing can work again.',
    );
  }

  factory SmsPermissionState.unsupported() {
    return const SmsPermissionState(
      status: SmsPermissionStatusType.unsupported,
      title: 'Android-only feature',
      description:
          'SMS permissions are available only on Android. You can still preview the app interface on this device.',
    );
  }
}
