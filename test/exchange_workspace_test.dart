import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorchepay/core/widgets/buttons.dart';
import 'package:scorchepay/features/exchange/exchange_workspace_screen.dart';
import 'package:scorchepay/theme/app_colors.dart';
import 'package:scorchepay/theme/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final width in [360.0, 1100.0]) {
      testWidgets('Exchange layouts at $width in $brightness', (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        AppColors.configure(brightness);
        for (final workspace in ExchangeWorkspace.values) {
          await tester.pumpWidget(MaterialApp(
            builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
            theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
            home: ExchangeWorkspaceScreen(key: ValueKey(workspace), workspace: workspace),
          ));
          expect(find.text('FRONTEND PREVIEW'), findsOneWidget);
          for (var i = 0; i < 3; i++) {
            await tester.tap(find.byType(ChoiceChip).at(i));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }
      });
    }
  }

  testWidgets('Search and order details preserve preview state', (tester) async {
    AppColors.configure(Brightness.dark);
    await tester.pumpWidget(MaterialApp(
            builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),theme: AppTheme.dark,
      home: const ExchangeWorkspaceScreen(workspace: ExchangeWorkspace.giftCards)));
    await tester.enterText(find.byType(TextField), 'no-such-card');
    await tester.pumpAndSettle();
    expect(find.text('No matching items. Try another search.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Amazon');
    await tester.pumpAndSettle();
    expect(find.text('Apple US'), findsNothing);
    await tester.tap(find.text('Amazon US'));
    await tester.pumpAndSettle();
    expect(find.text('Preview details · no live transaction'), findsOneWidget);
    await tester.tap(find.byType(IconCircleButton).last);
    await tester.pumpAndSettle();
    expect(find.text('Amazon US'), findsOneWidget);
    expect(find.text('Apple US'), findsNothing);
  });
}
