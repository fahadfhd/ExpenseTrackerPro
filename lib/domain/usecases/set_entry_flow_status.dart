import 'package:expensetrackerpro/domain/repositories/app_launch_repository.dart';

class SetEntryFlowStatus {
  const SetEntryFlowStatus(this._repository);

  final AppLaunchRepository _repository;

  Future<void> call(bool value) => _repository.setCompletedEntryFlow(value);
}
