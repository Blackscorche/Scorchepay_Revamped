import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorchepay/core/widgets/scorch_mascot.dart';
import 'package:scorchepay/core/widgets/scorch_character.dart';
import 'package:scorchepay/features/onboarding/onboarding_screen.dart';
import 'package:scorchepay/features/flows/shared/processing_screen.dart';
import 'package:scorchepay/features/live/live_signup_screen.dart';
import 'package:scorchepay/theme/app_colors.dart';
import 'package:scorchepay/theme/app_theme.dart';

Widget host(Widget child,
        {bool reduced = false,
        double scale = 1,
        Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
      builder: (context, body) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              disableAnimations: reduced, textScaler: TextScaler.linear(scale)),
          child: body!),
      home: child,
    );
void main() {
  testWidgets('Scorch animates, then stops for reduced motion and hidden tabs',
      (tester) async {
    await tester
        .pumpWidget(host(const ScorchMascot(activity: ScorchActivity.wallet)));
    final motion = find.byKey(const ValueKey('scorch-motion'));
    final first = tester.widget<Transform>(motion).transform.clone();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<Transform>(motion).transform, isNot(first));
    await tester.pumpWidget(host(
        const ScorchMascot(activity: ScorchActivity.wallet),
        reduced: true));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(
        host(const TickerMode(enabled: false, child: ScorchMascot())));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets('Scorch restores the original artwork for each activity',
      (tester) async {
    for (final activity in ScorchActivity.values) {
      await tester
          .pumpWidget(host(ScorchMascot(activity: activity), reduced: true));
      final character =
          tester.widget<ScorchCharacter>(find.byType(ScorchCharacter));
      final expected = switch (activity) {
        ScorchActivity.protect => 'assets/scorch_protect.png',
        ScorchActivity.celebrate => 'assets/scorch_celebrate.png',
        ScorchActivity.welcome ||
        ScorchActivity.explore ||
        ScorchActivity.rest =>
          'assets/scorch_mascot.png',
        _ => 'assets/scorch_wallet.png',
      };
      expect(character.asset, expected);
    }
  });
  for (final brightness in Brightness.values) {
    testWidgets(
        'onboarding remains usable at 360px with large text in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      AppColors.configure(brightness);
      await tester.pumpWidget(host(const OnboardingScreen(),
          reduced: true, scale: 1.5, brightness: brightness));
      for (var i = 0; i < 5; i++) {
        expect(tester.takeException(), isNull);
        if (i < 4) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      }
      expect(find.text('Get Started'), findsOneWidget);
    });
  }
  testWidgets('processing catches immediate failure and accepts empty steps',
      (tester) async {
    await tester.pumpWidget(host(
        ProcessingScreen<void>(
            steps: const [],
            task: () => Future.error(StateError('test failure'))),
        reduced: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('We could not confirm the result'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
  testWidgets('processing timeout cannot report success', (tester) async {
    final pending = Completer<void>();
    await tester.pumpWidget(host(
        ProcessingScreen<void>(
            steps: const [],
            task: () => pending.future,
            timeout: const Duration(seconds: 1)),
        reduced: true));
    expect(find.text('Working on it…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('We could not confirm the result'), findsOneWidget);
    pending.complete();
    await tester.pump();
    expect(find.text('We could not confirm the result'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('live signup validates without submitting invalid details',
      (tester) async {
    await tester.pumpWidget(host(const LiveSignupScreen(), reduced: true));
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Include your country code'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('onboarding visual preview', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppColors.configure(Brightness.light);
    await tester.pumpWidget(host(
        const RepaintBoundary(
            key: ValueKey('preview'), child: OnboardingScreen()),
        reduced: true));
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const ValueKey('preview')),
        matchesGoldenFile('goldens/scorch_onboarding.png'));
  });
}
