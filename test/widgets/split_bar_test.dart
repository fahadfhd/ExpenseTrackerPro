import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/theme/app_theme.dart';
import 'package:kept/shared/widgets/charts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the split bar draws both segments, sized by their share', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.build(Brightness.light),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20),
              child: SplitBar(
                aLabel: 'Principal',
                aMinor: 60000000,
                bLabel: 'Interest',
                bMinor: 15000000,
              ),
            ),
          ),
        ),
      ),
    );

    // The two coloured segments and the 2 px gap between them. They used to
    // collapse to zero height, so the bar never showed.
    final boxes = find.descendant(
      of: find.byType(SplitBar),
      matching: find.byType(ColoredBox),
    );
    final sizes = [
      for (final e in boxes.evaluate()) tester.getSize(find.byWidget(e.widget)),
    ];
    expect(sizes, hasLength(3));
    for (final size in sizes) {
      expect(size.height, 14);
    }
    // 80% principal, 20% interest.
    expect(sizes.first.width / sizes.last.width, closeTo(4, 0.1));
  });
}
