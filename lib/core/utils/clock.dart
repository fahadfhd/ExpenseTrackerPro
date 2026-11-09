import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time. A provider so tests can move it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
