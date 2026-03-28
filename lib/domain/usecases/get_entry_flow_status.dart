import 'package:expensetrackerpro/domain/repositories/app_launch_repository.dart';

class GetEntryFlowStatus {
  const GetEntryFlowStatus(this._repository);

  final AppLaunchRepository _repository;

  Future<bool> call() => _repository.hasCompletedEntryFlow();
}
