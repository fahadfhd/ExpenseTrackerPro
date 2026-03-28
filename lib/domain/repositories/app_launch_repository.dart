abstract class AppLaunchRepository {
  Future<bool> hasCompletedEntryFlow();

  Future<void> setCompletedEntryFlow(bool value);
}
