import 'package:expensetrackerpro/domain/repositories/app_launch_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAppLaunchRepository implements AppLaunchRepository {
  static const _entryFlowKey = 'entry_flow_completed';

  @override
  Future<bool> hasCompletedEntryFlow() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_entryFlowKey) ?? false;
  }

  @override
  Future<void> setCompletedEntryFlow(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_entryFlowKey, value);
  }
}
