import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/features/categories/data/category_repository.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/categories/domain/custom_category.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) throw StateError('Requires a signed-in user');
  return CategoryRepository(
    userDoc: userDoc,
    writer: ref.watch(writeDispatcherProvider),
    transactions: ref.watch(transactionRepositoryProvider),
  );
});

/// The user's own categories. Every emission also refreshes the
/// `Categories` registry so domain code and label lookups resolve custom
/// ids; widgets that show categories watch this provider to rebuild when a
/// category is added, renamed or archived. The registry is emptied when the
/// provider is disposed (sign-out), so one user's categories never leak into
/// the next session.
final customCategoriesProvider = StreamProvider<List<CustomCategory>>((ref) {
  ref.onDispose(() => Categories.setCustom(const []));
  return ref.watch(categoryRepositoryProvider).watchAll().map((list) {
    Categories.setCustom(list.map((c) => c.toCategory()));
    return list;
  });
});
