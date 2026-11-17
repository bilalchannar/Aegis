import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scam_fraud/main.dart';
import 'package:scam_fraud/app_state.dart';
import 'package:scam_fraud/features/account.dart';
import 'package:scam_fraud/features/check.dart';
import 'package:scam_fraud/features/safety.dart';
import 'package:scam_fraud/ui/design.dart';
import 'package:scam_fraud/services/scanner.dart';
import 'package:scam_fraud/models/audit_report.dart';
import 'package:scam_fraud/services/pro_access.dart';

Future<void> mobile(WidgetTester tester, {double width = 390}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<AppState> screen(
  WidgetTester tester,
  Widget page, {
  bool dark = false,
}) async {
  SharedPreferences.setMockInitialValues({'dark': dark});
  final state = AppState();
  await state.load();
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(theme: appTheme(dark), home: page),
    ),
  );
  await tester.pumpAndSettle();
  return state;
}

Future<void> tapVisible(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      220,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

void main() {
  test('Structured message reports preserve evidence and score safely', () {
    final report = Scanner.analyzeMessage(
      'URGENT: Your bank account will be suspended. Send your OTP and pay a fee at https://paypa1-secure.xyz',
    );
    expect(report.riskScore, inInclusiveRange(0, 100));
    expect(report.findings, isNotEmpty);
    expect(report.findings.first.evidence, isNotEmpty);
    expect(report.aiRan, isFalse);
    expect(report.riskLevel, isNot(RiskLevel.inconclusive));
    expect(report.analysisLabel, 'Deterministic rules only');
  });

  test('Empty and oversized messages are inconclusive', () {
    expect(Scanner.analyzeMessage('').riskLevel, RiskLevel.inconclusive);
    expect(Scanner.analyzeMessage('x' * 15001).riskScore, isNull);
  });

  test(
    'Urgency alone remains inconclusive, while credential requests escalate',
    () {
      final urgency = Scanner.analyzeMessage(
        'Please act immediately to review this notice.',
      );
      expect(urgency.riskLevel, RiskLevel.inconclusive);
      final otp = Scanner.analyzeMessage('Please send your OTP to confirm.');
      expect(otp.riskLevel, anyOf(RiskLevel.high, RiskLevel.critical));
    },
  );

  test('Credential and urgency variants ignore letter case', () {
    final report = Scanner.analyzeMessage('SEND YOUR OPT HURRY UP');
    expect(
      report.findings.any(
        (finding) => finding.title == 'Requests a secret authentication code',
      ),
      isTrue,
    );
    expect(
      report.findings.any(
        (finding) => finding.title == 'Uses urgency or a threat',
      ),
      isTrue,
    );
    expect(report.riskScore, inInclusiveRange(0, 100));
  });

  test('Credential warnings are not classified as credential requests', () {
    final warning = Scanner.analyzeMessage(
      'Never share your OTP with anyone, including support staff.',
    );
    expect(
      warning.findings.where(
        (finding) => finding.title == 'Requests a secret authentication code',
      ),
      isEmpty,
    );
    final request = Scanner.analyzeMessage(
      'Share your OTP with our support team immediately.',
    );
    expect(
      request.findings.any(
        (finding) => finding.title == 'Requests a secret authentication code',
      ),
      isTrue,
    );
  });

  test('Context-aware examples distinguish warnings and suspicious requests', () {
    final suspicious = Scanner.analyzeMessage(
      'Your bank account will be blocked in 30 minutes. Verify your identity immediately by sharing your OTP with our support team.',
    );
    expect(
      suspicious.findings.any(
        (finding) => finding.title == 'Requests a secret authentication code',
      ),
      isTrue,
    );

    final educational = Scanner.analyzeMessage(
      'This article explains how scammers use fake bank messages to steal passwords.',
    );
    expect(educational.findings, isEmpty);

    final receipt = Scanner.analyzeMessage(
      'Your payment of Rs. 1,500 was received successfully. Thank you for your purchase.',
    );
    expect(receipt.findings, isEmpty);

    final ambiguous = Scanner.analyzeMessage(
      'Please verify your account today.',
    );
    expect(ambiguous.findings, isNotEmpty);
    expect(
      ambiguous.findings.any(
        (finding) => finding.title == 'Uses urgency or a threat',
      ),
      isTrue,
    );
  });

  test('Refund fee and unsafe installation requests are detected', () {
    final refund = Scanner.analyzeMessage(
      'Your refund is approved. Pay a processing fee first to release the funds.',
    );
    expect(
      refund.findings.any(
        (finding) => finding.title == 'Requests money or payment details',
      ),
      isTrue,
    );

    final install = Scanner.analyzeMessage(
      'Install this unknown APK and disable your phone security to activate your account.',
    );
    expect(
      install.findings.any(
        (finding) =>
            finding.title ==
            'Requests software installation or command execution',
      ),
      isTrue,
    );
    expect(
      install.findings.any(
        (finding) =>
            finding.title == 'Requests a risky account-security change',
      ),
      isTrue,
    );
  });

  test('Roman Urdu and URL structure indicators are covered', () {
    final romanUrdu = Scanner.analyzeMessage(
      'Jaldi paise bhejo aur link kholo, inaam claim karo.',
    );
    expect(romanUrdu.findings, isNotEmpty);

    final url = Scanner.analyzeUrl(
      'https://paypal.com.evil.example:8080/download/app.apk?next=%2Flogin',
    );
    expect(
      url.findings.any(
        (finding) => finding.title == 'URL uses an unusual port',
      ),
      isTrue,
    );
    expect(
      url.findings.any(
        (finding) =>
            finding.title == 'URL points to a potentially executable download',
      ),
      isTrue,
    );
    expect(
      url.findings.any(
        (finding) =>
            finding.title == 'Trusted brand appears in a deceptive hostname',
      ),
      isTrue,
    );
  });

  test('Bare domains are normalized without opening them', () {
    final report = Scanner.analyzeUrl('example.com/path');
    expect(report.input.value, 'example.com/path');
    expect(report.riskLevel, RiskLevel.low);
    expect(report.checks, isNotEmpty);
  });

  test('Benign keyword context does not create an unsupported finding', () {
    final report = Scanner.analyzeMessage(
      'The bank sent an informational notice. I will open the official app later.',
    );
    expect(report.findings, isEmpty);
    expect(report.riskLevel, RiskLevel.low);
  });

  test(
    'URL analysis never opens the URL and reports structural indicators',
    () {
      expect(Scanner.analyzeUrl('not a url').riskLevel, RiskLevel.inconclusive);
      expect(
        Scanner.analyzeUrl('https://example.com').riskLevel,
        RiskLevel.low,
      );
      final report = Scanner.analyzeUrl(
        'http://user:pass@192.168.1.1/redirect?url=%2Flogin',
      );
      expect(report.findings.length, greaterThanOrEqualTo(3));
      expect(
        report.checks.any((check) => check.status == CheckStatus.unavailable),
        isTrue,
      );
    },
  );

  test('Report JSON round trip and corrupt optional fields are safe', () {
    final original = Scanner.analyzeUrl('https://tinyurl.com/example');
    final restored = AuditReport.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.input.type, ScanInputType.url);
    expect(restored.checks, isNotEmpty);
    final partial = AuditReport.fromJson({'id': 'partial'});
    expect(partial.riskLevel, RiskLevel.inconclusive);
    expect(partial.findings, isEmpty);
  });

  test('Screenshot analysis explicitly reports unavailable OCR', () {
    final report = Scanner.screenshotUnavailable(
      sizeBytes: 1200,
      mimeType: 'image/png',
    );
    expect(report.riskScore, isNull);
    expect(report.riskLevel, RiskLevel.inconclusive);
    expect(
      report.checks.any(
        (check) =>
            check.source == AnalysisSource.ocrVision &&
            check.status == CheckStatus.unavailable,
      ),
      isTrue,
    );
    expect(report.aiRan, isFalse);
  });

  test('Corrupt persisted reports do not prevent state loading', () async {
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'remember': true,
      'reports': ['not-json', '{"id":"broken"}'],
      'history': ['not-json'],
    });
    final state = AppState();
    await state.load();
    expect(state.ready, isTrue);
    expect(state.reports, hasLength(1));
    expect(state.history, hasLength(1));
  });

  testWidgets('History Safe filter shows only low-risk reports', (
    tester,
  ) async {
    await mobile(tester);
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    await app.load();
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: MaterialApp(
          theme: appTheme(false),
          home: const Scaffold(body: HistoryView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    app.addReport(
      AuditReport(
        id: 'safe-report',
        createdAt: DateTime(2026, 1, 1),
        input: const ScanInput(
          type: ScanInputType.message,
          value: 'A routine account notice',
        ),
        riskScore: 10,
        riskLevel: RiskLevel.low,
        executiveSummary: 'No strong indicators found.',
        findings: const [],
        recommendations: const [],
        checks: const [],
        limitations: const [],
        sources: const {AnalysisSource.deterministic},
        aiRan: false,
      ),
    );
    app.addCheck(Scanner.local(exampleMessage));
    await tester.pumpAndSettle();
    expect(find.text('Safe'), findsAtLeastNWidgets(1));
    await tester.tap(find.text('Safe').first);
    await tester.pumpAndSettle();
    expect(find.text('A routine account notice'), findsOneWidget);
    expect(find.text(exampleMessage), findsNothing);
  });

  test(
    'Concrete warning signs escalate, unknown content is not assured safe',
    () {
      final result = Scanner.local(exampleMessage);
      expect(result.verdict, 'Dangerous');
      expect(result.reasons.length, 3);
      expect(Scanner.local('https://example.com').verdict, 'Safe');
      expect(ScanResult.fromJson(result.toJson()).reasons, result.reasons);
    },
  );
  testWidgets('Splash, onboarding, authentication, and scanner work', (
    tester,
  ) async {
    await mobile(tester);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('A calmer\ndigital life.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('A second look.\nA better instinct.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Your people.\nYour peace.'), findsOneWidget);
    await tester.tap(find.text('Start with Aegis'));
    await tester.pumpAndSettle();
    expect(find.text('Your account'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tapVisible(tester, 'Create account');
    await tapVisible(tester, 'Check something');
    await tapVisible(tester, 'Danger example');
    await tapVisible(tester, 'Check for warning signs');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('DANGEROUS'), findsOneWidget);
    expect(find.text('What we noticed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('All glass navigation destinations fit a narrow screen', (
    tester,
  ) async {
    await mobile(tester, width: 375);
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'signedIn': true,
      'accountEmail': 'test@example.com',
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    for (final label in ['History', 'Learn', 'Profile', 'Home']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('Account form validates but does not create an account', (
    tester,
  ) async {
    await mobile(tester);
    await screen(tester, const AuthPage());
    await tapVisible(tester, 'Create account');
    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text('Gemini API key'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Unconfigured store product never activates Pro', (tester) async {
    await mobile(tester, width: 375);
    await screen(tester, const SubscriptionPage());
    expect(find.text('Choose your level of protection.'), findsOneWidget);
    expect(find.text('FREE'), findsWidgets);
    expect(find.text('PRO'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('ULTRA'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ULTRA'), findsWidgets);
    expect(ProAccess.instance.plan, ProPlan.free);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Trusted contact and recovery progress persist locally', (
    tester,
  ) async {
    await mobile(tester);
    final app = await screen(tester, const CirclePage());
    await tapVisible(tester, 'Add a trusted person');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'A trusted friend',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'friend@example.com',
    );
    await tapVisible(tester, 'Save trusted person');
    app.toggleStep('0:0');
    final restored = AppState();
    await restored.load();
    expect(restored.contacts.single['name'], 'A trusted friend');
    expect(restored.completedSteps, contains('0:0'));
    app.removeContact(0);
    expect(app.contacts, isEmpty);
  });
  testWidgets('Recovery checklist updates progress', (tester) async {
    await mobile(tester);
    await screen(tester, const RecoveryPage());
    await tapVisible(tester, 'Contact your payment provider');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('1 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Quiz explains choices and completes all questions', (
    tester,
  ) async {
    await mobile(tester);
    final app = await screen(tester, const QuizPage());
    for (final answer in [
      'Open the bank’s official app',
      'Call the old, trusted number',
      'Pause and verify the promotion',
    ]) {
      await tapVisible(tester, answer);
      await tapVisible(
        tester,
        answer == 'Pause and verify the promotion'
            ? 'See my progress'
            : 'Next example',
      );
    }
    expect(find.text('3 / 3 thoughtful choices'), findsOneWidget);
    expect(app.quizBest, 100);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Settings toggle dark mode and save notification preference', (
    tester,
  ) async {
    await mobile(tester);
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'signedIn': true,
      'accountEmail': 'test@example.com',
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CupertinoSwitch).first);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Dark appearance'))).brightness,
      Brightness.dark,
    );
    await tester.ensureVisible(find.text('Gentle reminders'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CupertinoSwitch).at(1));
    await tester.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getBool('reminders'), true);
    expect(tester.takeException(), isNull);
  });
}
