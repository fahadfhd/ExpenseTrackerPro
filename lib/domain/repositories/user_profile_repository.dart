import 'package:flutter/material.dart';

abstract class UserProfileRepository {
  Future<void> syncCurrentUserProfile({
    required bool gmailConnected,
    required ThemeMode themeMode,
  });
}
