import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetrackerpro/app/app.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/features/reminders/application/reminder_providers.dart';
import 'package:expensetrackerpro/core/notifications/notification_service.dart';
import 'package:expensetrackerpro/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Offline-first: Firestore's local cache is the app's on-device store.
  // Writes apply locally at once and sync when connectivity returns.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final prefs = await SharedPreferences.getInstance();
  final notifications = LocalNotificationService();
  await notifications.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const ExpanseTrackerProApp(),
    ),
  );
}
