import 'package:expensetrackerpro/domain/repositories/user_profile_repository.dart';
import 'package:flutter/material.dart';

class SyncCurrentUserProfile {
  const SyncCurrentUserProfile(this._repository);

  final UserProfileRepository _repository;

  Future<void> call({
    required bool gmailConnected,
    required ThemeMode themeMode,
  }) {
    return _repository.syncCurrentUserProfile(
      gmailConnected: gmailConnected,
      themeMode: themeMode,
    );
  }
}
