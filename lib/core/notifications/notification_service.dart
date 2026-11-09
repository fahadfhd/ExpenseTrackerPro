import 'package:kept/core/errors/app_failure.dart';
import 'package:kept/core/notifications/notification_planner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Device notification scheduling. An interface so widget tests can run
/// without the platform plugin.
abstract class NotificationService {
  Future<void> init();

  Future<bool> requestPermission();

  Future<bool> areEnabled();

  /// Sets the name and description Android shows for the reminders channel in
  /// the system's notification settings, in the app's current language. A
  /// no-op elsewhere.
  Future<void> setChannelText({
    required String name,
    required String description,
  });

  /// Makes the device's pending notifications exactly match [desired]:
  /// cancels ones no longer planned, (re)schedules new or changed ones, and
  /// leaves identical ones alone. Ids are deterministic, so this is safe to
  /// call any number of times and never duplicates.
  Future<ReconcileResult> reconcile(List<PlannedNotification> desired);
}

class ReconcileResult {
  const ReconcileResult({
    required this.scheduled,
    required this.cancelled,
    required this.unchanged,
    this.failures = 0,
  });

  final int scheduled;
  final int cancelled;
  final int unchanged;
  final int failures;
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _channelId = 'reminders';

  // The channel's name and description are set in the app's language by
  // `setChannelText`; these are only the fallback if that has not run yet.
  static const _channel = AndroidNotificationDetails(
    _channelId,
    'Reminders',
    channelDescription: 'Bill, EMI, card and personal reminders',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _details = NotificationDetails(
    android: _channel,
    iOS: DarwinNotificationDetails(),
  );

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> init() async {
    if (_ready || !_supported) return;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // Unknown zone id: fall back to UTC offsets, still deterministic.
      debugPrint('Timezone lookup failed: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    await init();
    if (!_supported) return false;
    if (_android != null) {
      final granted = await _android!.requestNotificationsPermission() ?? false;
      return granted;
    }
    return await _ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  @override
  Future<void> setChannelText({
    required String name,
    required String description,
  }) async {
    await init();
    // Creating a channel that already exists only updates its name and
    // description; the user's own sound/importance choices are kept.
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        name,
        description: description,
        importance: Importance.high,
      ),
    );
  }

  @override
  Future<bool> areEnabled() async {
    await init();
    if (!_supported) return false;
    if (_android != null) {
      return await _android!.areNotificationsEnabled() ?? false;
    }
    final options = await _ios?.checkPermissions();
    return options?.isEnabled ?? false;
  }

  @override
  Future<ReconcileResult> reconcile(List<PlannedNotification> desired) async {
    await init();
    if (!_supported) {
      return const ReconcileResult(scheduled: 0, cancelled: 0, unchanged: 0);
    }
    final pending = await _plugin.pendingNotificationRequests();
    final pendingPayload = {for (final p in pending) p.id: p.payload};
    final desiredIds = {for (final d in desired) d.id};

    var cancelled = 0, scheduled = 0, unchanged = 0, failures = 0;
    for (final p in pending) {
      if (!desiredIds.contains(p.id)) {
        await _plugin.cancel(id: p.id);
        cancelled++;
      }
    }

    final exact = await _android?.canScheduleExactNotifications() ?? true;
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final n in desired) {
      if (pendingPayload[n.id] == n.payload) {
        unchanged++;
        continue;
      }
      try {
        await _plugin.zonedSchedule(
          id: n.id,
          title: n.title,
          body: n.body,
          payload: n.payload,
          scheduledDate: tz.TZDateTime(
            tz.local,
            n.fireAt.year,
            n.fireAt.month,
            n.fireAt.day,
            n.fireAt.hour,
            n.fireAt.minute,
          ),
          notificationDetails: _details,
          androidScheduleMode: mode,
        );
        scheduled++;
      } catch (e) {
        failures++;
        debugPrint('Scheduling ${n.id} failed: ${AppFailure.from(e)}');
      }
    }
    return ReconcileResult(
      scheduled: scheduled,
      cancelled: cancelled,
      unchanged: unchanged,
      failures: failures,
    );
  }
}
