import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../app_state.dart';
import '../models/audit_report.dart';
import '../services/ai_analyzer.dart';
import '../services/api_config.dart';
import '../services/scanner.dart';
import '../ui/design.dart';
import '../services/report_export.dart';
import '../services/pro_access.dart';
import '../services/custom_rules.dart';
import 'safety.dart';

const safeMessageExample =
    'Your appointment is confirmed for tomorrow at 10:30 AM. Please arrive 10 minutes early. To reschedule, call the clinic using the number on your appointment card.';
const dangerousMessageExample =
    'URGENT: Your PayPal account will be permanently suspended in 10 minutes. Verify your identity immediately. Reply with your password and OTP now, or your account and balance will be deleted. Pay a \$499 recovery fee to restore access.';
// Compatibility name retained for the original widget/evaluation tests.
const exampleMessage = dangerousMessageExample;
const safeLinkExample = 'https://www.google.com/';
const dangerousLinkExample =
    'http://paypa1-secure.zyx:8080/verify?password=test&otp=123456&next=%2Flogin';
Color verdictColor(String v) => v == 'Dangerous'
    ? rust
    : v == 'Safe'
    ? green
    : amber;

String? _imageMimeType(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return 'image/png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 6 &&
      ((bytes[0] == 0x47 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x38 &&
          (bytes[4] == 0x37 || bytes[4] == 0x39) &&
          bytes[5] == 0x61))) {
    return 'image/gif';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

class CheckPage extends StatefulWidget {
  final int initialMode;
  const CheckPage({super.key, this.initialMode = 0});
  @override
  State<CheckPage> createState() => _CheckPageState();
}

class _CheckPageState extends State<CheckPage> {
  late int mode = widget.initialMode;
  final input = TextEditingController();
  Uint8List? imageBytes;
  String? imageMimeType;
  String? error;
  bool busy = false;
  bool useAi = false;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (image == null) {
        return;
      }
      final bytes = await image.readAsBytes();
      final mimeType = _imageMimeType(bytes);
      if (mimeType == null) {
        throw Exception(
          'Unsupported image format. Choose a JPEG, PNG, WebP, or GIF image.',
        );
      }
      if (bytes.length > AiAnalyzer.maxImageBytes) {
        throw Exception('Please choose an image smaller than 8 MB.');
      }
      if (mounted) {
        setState(() {
          imageBytes = bytes;
          imageMimeType = mimeType;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Could not load this image. Try a smaller screenshot and check photo permissions.',
        );
      }
    }
  }

  Future<void> scan() async {
    final app = AppScope.of(context);
    if (mode == 2) {
      if (imageBytes == null) {
        setState(() => error = 'Choose a screenshot before checking it.');
        return;
      }
      final access = ProAccess.instance;
      final canUseAi =
          access.allows(FeatureAccess.advancedTextScan) && ApiConfig.hasAi;
      var aiReserved = false;
      if (canUseAi) {
        aiReserved = await access.reserveAiRequest();
        if (!aiReserved) {
          if (mounted) {
            setState(
              () => error =
                  'Your daily AI request limit has been reached. Try again after the daily reset.',
            );
          }
          return;
        }
      }
      final AuditReport report;
      var aiSucceeded = false;
      setState(() {
        busy = true;
        error = null;
      });
      try {
        report = canUseAi
            ? await AiAnalyzer().analyzeScreenshot(
                bytes: imageBytes!,
                mimeType: imageMimeType!,
              )
            : Scanner.screenshotUnavailable(
                sizeBytes: imageBytes!.length,
                mimeType: imageMimeType,
              );
        aiSucceeded = report.aiRan;
      } on AnalysisServiceException catch (exception) {
        if (mounted) setState(() => error = exception.message);
        return;
      } finally {
        if (aiReserved) await access.finishAiRequest(succeeded: aiSucceeded);
        if (mounted) setState(() => busy = false);
      }
      if (!mounted) return;
      app.addReport(report);
      openPage(context, ResultPage(result: report.toLegacyResult()));
      return;
    }
    final text = input.text.trim();
    if (text.isEmpty) {
      setState(() => error = 'Paste something you would like to check.');
      return;
    }
    if (text.length > 15000) {
      setState(
        () => error = 'Please keep the message under 15,000 characters.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    late final AuditReport report;
    final access = ProAccess.instance;
    final requiresAiEntitlement =
        useAi &&
        !access.allows(
          mode == 1
              ? FeatureAccess.advancedUrlScan
              : FeatureAccess.advancedTextScan,
        );
    if (requiresAiEntitlement) {
      if (mounted) setState(() => busy = false);
      openPage(context, const SubscriptionPage());
      return;
    }
    if (!useAi) {
      report = _analyzeWithRules(text);
    } else if (!ApiConfig.hasAi) {
      report = _rulesFallback(
        text,
        'No AI provider is configured. Used on-device rules instead.',
      );
    } else {
      var reserved = false;
      var aiSucceeded = false;
      try {
        reserved = await access.reserveAiRequest();
        if (!reserved) {
          if (mounted) {
            setState(() {
              busy = false;
              error =
                  'Your daily AI request limit has been reached. Try again after the daily reset.';
            });
          }
          return;
        }
        final analyzer = AiAnalyzer();
        report = mode == 1
            ? await analyzer.analyzeUrl(text)
            : await analyzer.analyzeMessage(text);
        aiSucceeded = report.aiRan;
      } on AnalysisServiceException catch (exception) {
        report = _rulesFallback(text, exception.message);
      } finally {
        if (reserved) await access.finishAiRequest(succeeded: aiSucceeded);
      }
    }
    final enhancedReport = ProAccess.instance.allows(FeatureAccess.customRules)
        ? await CustomRuleBook.instance.apply(report, text)
        : report;
    final result = enhancedReport.toLegacyResult();
    if (!mounted) {
      return;
    }
    app.addReport(enhancedReport);
    setState(() => busy = false);
    openPage(context, ResultPage(result: result));
  }

  AuditReport _analyzeWithRules(String text) =>
      mode == 1 ? Scanner.analyzeUrl(text) : Scanner.analyzeMessage(text);

  AuditReport _rulesFallback(String text, String reason) {
    final deterministic = _analyzeWithRules(text);
    return deterministic.copyWith(
      checks: [
        ...deterministic.checks,
        AnalysisCheck(
          name: 'AI analysis',
          source: AnalysisSource.ai,
          status: CheckStatus.error,
          detail: '$reason Rules based analysis was used instead.',
        ),
      ],
      limitations: [
        ...deterministic.limitations,
        const AnalysisLimitation(
          title: 'AI analysis unavailable',
          detail:
              'The selected AI provider did not return a usable report. This result uses the app’s on-device rules instead.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'A second opinion',
    children: [
      const SizedBox(height: 9),
      Row(
        children: [
          const Pill('CHECK WITH CONFIDENCE', icon: CupertinoIcons.shield),
          const Spacer(),
          Icon(
            CupertinoIcons.sparkles,
            color: context.isDark ? mint : green,
            size: 22,
          ),
        ],
      ),
      const SizedBox(height: 24),
      Text('Something\nfeel off?', style: headline(43)),
      const SizedBox(height: 13),
      caption(context, 'Let’s find a little clarity before you act.'),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<int>(
          groupValue: mode,
          backgroundColor: context.soft,
          thumbColor: context.card,
          children: {
            0: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
              child: Text(
                'Message',
                style: TextStyle(color: context.ink, fontSize: 12),
              ),
            ),
            1: Text('Link', style: TextStyle(color: context.ink, fontSize: 12)),
            2: Text(
              'Screenshot',
              style: TextStyle(color: context.ink, fontSize: 12),
            ),
          },
          onValueChanged: (value) {
            if (!busy && value != null) {
              setState(() {
                mode = value;
                error = null;
              });
            }
          },
        ),
      ),
      if (mode != 2) ...[
        const SizedBox(height: 14),
        Row(
          children: [
            eyebrow(context, 'ANALYSIS METHOD'),
            if (useAi && ApiConfig.hasAi)
              const Pill('AI READY', icon: CupertinoIcons.sparkles),
            if (useAi && !ApiConfig.hasAi)
              const Pill('RULES FALLBACK', color: amber),
          ],
        ),
        const SizedBox(height: 9),
        Surface(
          padding: const EdgeInsets.all(5),
          radius: 20,
          child: Row(
            children: [
              _analysisMethodOption(
                title: 'Rules',
                subtitle: 'On-device checks',
                icon: CupertinoIcons.checkmark_shield,
                selected: !useAi,
                onTap: () => setState(() => useAi = false),
              ),
              _analysisMethodOption(
                title: 'AI analysis',
                subtitle: ApiConfig.hasAi
                    ? 'Rules fallback ready'
                    : 'No key · rules fallback',
                icon: CupertinoIcons.sparkles,
                selected: useAi,
                onTap: () {
                  final feature = mode == 1
                      ? FeatureAccess.advancedUrlScan
                      : FeatureAccess.advancedTextScan;
                  if (ApiConfig.hasAi && !ProAccess.instance.allows(feature)) {
                    openPage(context, const SubscriptionPage());
                    return;
                  }
                  setState(() => useAi = true);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        caption(
          context,
          useAi
              ? 'AI mode sends this ${mode == 1 ? 'link' : 'message'} to a configured provider. If unavailable, on-device rules run automatically.'
              : 'Rules mode stays on this device. Your ${mode == 1 ? 'link' : 'message'} is not uploaded.',
        ),
      ],
      const SizedBox(height: 22),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: mode == 2
            ? GestureDetector(
                key: const ValueKey('image'),
                onTap: busy ? null : pickImage,
                child: Surface(
                  child: SizedBox(
                    height: 225,
                    width: double.infinity,
                    child: imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              imageBytes!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Center(
                                child: Text(
                                  'This image could not be displayed.',
                                ),
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              iconTile(
                                context,
                                CupertinoIcons.viewfinder,
                                size: 66,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Choose a screenshot',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 9),
                              caption(context, 'One image. A clearer picture.'),
                              const SizedBox(height: 15),
                              const Pill('PNG, JPG • UP TO 8 MB'),
                            ],
                          ),
                  ),
                ),
              )
            : TextField(
                key: const ValueKey('text'),
                controller: input,
                enabled: !busy,
                minLines: mode == 1 ? 4 : 7,
                maxLines: 9,
                keyboardType: mode == 1
                    ? TextInputType.url
                    : TextInputType.multiline,
                style: const TextStyle(fontSize: 15, height: 1.6),
                decoration: InputDecoration(
                  hintText: mode == 1
                      ? 'Paste a suspicious link…'
                      : 'Paste the message, email or social post here…',
                  hintStyle: TextStyle(color: context.subtle, fontSize: 14),
                  fillColor: context.card,
                  contentPadding: const EdgeInsets.all(22),
                ),
              ),
      ),
      if (mode != 2)
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (mounted && data?.text != null) {
                        input.text = data!.text!;
                      }
                    },
              icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 14),
              label: const Text('Paste', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => input.text = mode == 1
                        ? safeLinkExample
                        : safeMessageExample,
              child: const Text('Safe example', style: TextStyle(fontSize: 11)),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => input.text = mode == 1
                        ? dangerousLinkExample
                        : dangerousMessageExample,
              child: const Text(
                'Danger example',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        )
      else ...[
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: pickImage,
          icon: const Icon(CupertinoIcons.photo, size: 15),
          label: Text(
            imageBytes == null ? 'Browse photos' : 'Choose another image',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
      if (error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            error!,
            style: const TextStyle(color: rust, fontSize: 13, height: 1.5),
          ),
        ),
      const SizedBox(height: 15),
      ActionButton(
        busy
            ? 'Looking for warning signs…'
            : mode == 2
            ? 'About image analysis'
            : 'Check for warning signs',
        busy: busy,
        icon: CupertinoIcons.sparkles,
        onTap: scan,
      ),
      const SizedBox(height: 18),
      if (mode == 2)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CupertinoIcons.lock_shield, size: 16, color: context.subtle),
            const SizedBox(width: 9),
            Expanded(
              child: caption(
                context,
                !ProAccess.instance.allows(FeatureAccess.advancedTextScan)
                    ? 'Free keeps this screenshot on your device. It can show the analysis status, but local OCR is not available; Pro enables supported AI image analysis.'
                    : ApiConfig.hasAi
                    ? 'This screenshot will be sent to the configured Gemini or Groq vision provider for visible-text and security-content analysis. Provider limits still apply.'
                    : 'The screenshot stays local. Configure an AI provider to analyze visible text and security content.',
              ),
            ),
          ],
        ),
      const SizedBox(height: 25),
    ],
  );

  Widget _analysisMethodOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) => Expanded(
    child: InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? context.soft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? (context.isDark ? mint : green).withValues(alpha: .55)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? (context.isDark ? mint : green)
                      : context.subtle,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.subtle, fontSize: 10),
            ),
          ],
        ),
      ),
    ),
  );
}

class ResultPage extends StatelessWidget {
  final ScanResult result;
  final bool sample;
  const ResultPage({super.key, required this.result, this.sample = false});
  @override
  Widget build(BuildContext context) {
    final color = verdictColor(result.verdict);
    final report = result.report;
    final riskLabel = report == null
        ? null
        : switch (report.riskLevel) {
            RiskLevel.low => 'SAFE',
            RiskLevel.medium || RiskLevel.inconclusive => 'SUSPICIOUS',
            RiskLevel.high || RiskLevel.critical => 'DANGEROUS',
          };
    return PageFrame(
      title: 'Your clarity card',
      children: [
        if (sample) ...[
          const Center(
            child: Pill('SAMPLE RESULT • NOT YOUR SCREENSHOT', color: amber),
          ),
          const SizedBox(height: 15),
        ],
        Entrance(
          child: Surface(
            color: color.withValues(alpha: context.isDark ? .14 : .07),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    result.verdict == 'Safe'
                        ? CupertinoIcons.checkmark_shield
                        : CupertinoIcons.exclamationmark_shield,
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(height: 20),
                Pill(result.verdict.toUpperCase(), color: color),
                const SizedBox(height: 20),
                Text(
                  result.verdict == 'Dangerous'
                      ? 'Your pause\nwas a good instinct.'
                      : result.verdict == 'Safe'
                      ? 'No obvious\nwarning signs.'
                      : 'Worth a\ncloser look.',
                  textAlign: TextAlign.center,
                  style: headline(34),
                ),
                const SizedBox(height: 16),
                Text(
                  result.summary,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.subtle,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
                if (report != null) ...[
                  const SizedBox(height: 17),
                  Text(
                    report.riskScore == null
                        ? '$riskLabel · SCORE UNAVAILABLE'
                        : '$riskLabel · RISK SCORE ${report.riskScore}/100',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        section(context, 'What we noticed'),
        const SizedBox(height: 15),
        ...result.reasons.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key + 1}'.padLeft(2, '0'),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (report != null && report.findings.isNotEmpty) ...[
          const SizedBox(height: 12),
          section(context, 'Evidence and severity'),
          const SizedBox(height: 12),
          ...report.findings.map(
            (finding) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            finding.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Pill(
                          finding.severity.name.toUpperCase(),
                          color: verdictColor(
                            finding.severity == FindingSeverity.critical ||
                                    finding.severity == FindingSeverity.high
                                ? 'Dangerous'
                                : 'Suspicious',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...finding.evidence.map(
                      (evidence) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Text(
                          '“${evidence.text}” — ${evidence.explanation}',
                          style: TextStyle(
                            color: context.subtle,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (report != null) ...[
          const SizedBox(height: 12),
          section(context, 'Recommended actions'),
          const SizedBox(height: 12),
          ...report.recommendations.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Surface(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recommendation.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Pill(recommendation.priority.name.toUpperCase()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    caption(context, recommendation.why),
                    const SizedBox(height: 8),
                    ...recommendation.steps.map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '• $step',
                          style: const TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            title: const Text(
              'Checks and limitations',
              style: TextStyle(fontSize: 13),
            ),
            children: [
              ...report.checks.map(
                (check) => ListTile(
                  dense: true,
                  title: Text(check.name, style: const TextStyle(fontSize: 12)),
                  subtitle: Text(
                    '${check.status.name}: ${check.detail}',
                    style: TextStyle(color: context.subtle, fontSize: 11),
                  ),
                ),
              ),
              ...report.limitations.map(
                (limitation) => ListTile(
                  dense: true,
                  title: Text(
                    limitation.title,
                    style: const TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(
                    limitation.detail,
                    style: TextStyle(color: context.subtle, fontSize: 11),
                  ),
                ),
              ),
              ListTile(
                dense: true,
                title: const Text(
                  'Analysis source',
                  style: TextStyle(fontSize: 12),
                ),
                subtitle: Text(
                  report.analysisLabel,
                  style: TextStyle(color: context.subtle, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Surface(
          color: context.soft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              eyebrow(context, 'YOUR NEXT BEST MOVE'),
              const SizedBox(height: 12),
              const Text(
                'Verify somewhere\nyou already trust.',
                style: TextStyle(
                  fontSize: 23,
                  height: 1.15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 12),
              caption(
                context,
                'Open the official app or contact the organisation independently before replying, paying, or sharing codes.',
              ),
              const SizedBox(height: 18),
              ActionButton(
                'Ask your trusted circle',
                secondary: true,
                icon: CupertinoIcons.person_2,
                onTap: () => openPage(context, const CirclePage()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Surface(
          padding: EdgeInsets.zero,
          child: MenuRow(
            'Already shared something?',
            icon: CupertinoIcons.heart,
            subtitle: 'Make a simple recovery plan',
            color: rust,
            onTap: () => openPage(context, const RecoveryPage()),
          ),
        ),
        const SizedBox(height: 22),
        Material(
          color: context.card,
          borderRadius: BorderRadius.circular(20),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            title: const Text(
              'Original content',
              style: TextStyle(fontSize: 13),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: SelectableText(
                  result.input,
                  style: TextStyle(
                    color: context.subtle,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${report?.analysisLabel ?? result.source}\nAn assessment, never a guarantee of safety.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.subtle, fontSize: 10, height: 1.8),
        ),
        const SizedBox(height: 25),
        if (report != null && !sample) ...[
          ActionButton(
            'Preview report PDF',
            secondary: true,
            onTap: () async {
              openPage(context, ReportCustomizePage(report: report));
            },
          ),
          const SizedBox(height: 9),
          ActionButton(
            'Share report PDF',
            secondary: true,
            onTap: () => openPage(context, ReportCustomizePage(report: report)),
          ),
          const SizedBox(height: 9),
        ],
        ActionButton('Done', onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

class ReportCustomizePage extends StatefulWidget {
  final AuditReport report;
  const ReportCustomizePage({super.key, required this.report});
  @override
  State<ReportCustomizePage> createState() => _ReportCustomizePageState();
}

class _ReportCustomizePageState extends State<ReportCustomizePage> {
  late final title = TextEditingController(text: 'Security assessment report');
  late final subtitle = TextEditingController(text: 'Prepared with Aegis');
  ReportPalette palette = ReportPalette.forest;
  bool executive = true, original = true, findings = true, evidence = true;
  bool methodology = true,
      recommendations = true,
      limitations = true,
      detailed = true;
  @override
  void dispose() {
    title.dispose();
    subtitle.dispose();
    super.dispose();
  }

  ReportOptions get options {
    final pro = ProAccess.instance.allows(FeatureAccess.multiplePdf);
    return ReportOptions(
      title: title.text.trim().isEmpty
          ? 'Security assessment report'
          : title.text.trim(),
      subtitle: subtitle.text.trim(),
      palette: pro ? palette : ReportPalette.forest,
      executive: executive,
      original: original,
      findings: findings,
      evidence: pro && evidence,
      methodology: methodology,
      recommendations: recommendations,
      limitations: limitations,
      detailed: pro && detailed,
    );
  }

  Future<void> _run(Future<bool> Function() action) async {
    final access = ProAccess.instance;
    if (!await access.reservePdfExport()) {
      if (!mounted) return;
      openPage(context, const SubscriptionPage());
      return;
    }
    var succeeded = false;
    try {
      succeeded = await action();
      if (!succeeded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF export canceled. Your quota was not used.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The PDF could not be completed. Your quota was not used.',
            ),
          ),
        );
      }
    } finally {
      await access.finishPdfExport(succeeded: succeeded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pro = ProAccess.instance.allows(FeatureAccess.multiplePdf);
    return PageFrame(
      title: 'Customize report',
      children: [
        const SizedBox(height: 12),
        caption(
          context,
          'This report uses the selected scan result. Exporting does not change your history preference.',
        ),
        const SizedBox(height: 8),
        Text(
          ProAccess.instance.pdfLimit == null
              ? 'PDF usage: Unlimited'
              : 'PDF exports this month: ${ProAccess.instance.pdfExportsThisMonth} / ${ProAccess.instance.pdfLimit} · ${ProAccess.instance.pdfRemaining} remaining',
          style: TextStyle(color: context.subtle, fontSize: 12),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: title,
          enabled: pro,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Report title',
            suffixIcon: pro ? null : const Icon(CupertinoIcons.lock, size: 17),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: subtitle,
          enabled: pro,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Subtitle',
            suffixIcon: pro ? null : const Icon(CupertinoIcons.lock, size: 17),
          ),
        ),
        const SizedBox(height: 18),
        eyebrow(context, 'BRAND PALETTE'),
        Wrap(
          spacing: 8,
          children: ReportPalette.values
              .map(
                (value) => ChoiceChip(
                  label: Text(value.name),
                  selected: palette == value,
                  onSelected: pro
                      ? (_) => setState(() => palette = value)
                      : (_) => openPage(context, const SubscriptionPage()),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        eyebrow(context, 'REPORT SECTIONS'),
        _option(
          'Executive summary',
          executive,
          (v) => setState(() => executive = v),
        ),
        _option(
          'Original scanned content',
          original,
          (v) => setState(() => original = v),
        ),
        _option(
          'Detailed findings',
          findings,
          (v) => setState(() => findings = v),
        ),
        _option(
          'Evidence excerpts',
          evidence,
          (v) => setState(() => evidence = v),
          locked: !pro,
        ),
        _option(
          'Detection methodology',
          methodology,
          (v) => setState(() => methodology = v),
          locked: !pro,
        ),
        _option(
          'Recommendations',
          recommendations,
          (v) => setState(() => recommendations = v),
        ),
        _option(
          'Limitations and safety guidance',
          limitations,
          (v) => setState(() => limitations = v),
        ),
        _option(
          'Detailed layout',
          detailed,
          (v) => setState(() => detailed = v),
          locked: !pro,
        ),
        if (!pro)
          ActionButton(
            'Unlock full report customization',
            secondary: true,
            onTap: () => openPage(context, const SubscriptionPage()),
          ),
        const SizedBox(height: 14),
        ActionButton(
          'Preview / save / print PDF',
          onTap: () =>
              _run(() => ReportExport.preview(widget.report, options: options)),
        ),
        const SizedBox(height: 9),
        ActionButton(
          'Share PDF',
          secondary: true,
          onTap: () =>
              _run(() => ReportExport.share(widget.report, options: options)),
        ),
      ],
    );
  }

  Widget _option(
    String label,
    bool value,
    ValueChanged<bool> changed, {
    bool locked = false,
  }) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    secondary: locked ? const Icon(CupertinoIcons.lock, size: 17) : null,
    value: value,
    onChanged: locked ? null : changed,
  );
}

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});
  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final query = TextEditingController();
  String filter = 'All';
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final proHistory = ProAccess.instance.allows(FeatureAccess.extendedHistory);
    final visibleHistory = proHistory
        ? app.history
        : app.history.take(20).toList();
    final results = visibleHistory
        .where(
          (r) =>
              (filter == 'All' ||
                  (filter == 'Safe'
                      ? r.report?.riskLevel == RiskLevel.low
                      : r.verdict == filter)) &&
              r.input.toLowerCase().contains(query.text.toLowerCase()),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 27, 24, 125),
      children: [
        eyebrow(context, 'YOUR ACTIVITY'),
        const SizedBox(height: 12),
        Text('Small checks.\nClearer decisions.', style: headline(37)),
        const SizedBox(height: 16),
        caption(
          context,
          app.saveChecks
              ? 'Your checks, saved only on this device.'
              : 'Your checks stay here for this session.',
        ),
        const SizedBox(height: 25),
        TextField(
          controller: query,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Find a check',
            hintStyle: TextStyle(color: context.subtle, fontSize: 13),
            prefixIcon: const Icon(CupertinoIcons.search, size: 19),
            fillColor: context.card,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: ['All', 'Dangerous', 'Suspicious', 'Safe']
              .map(
                (v) => ChoiceChip(
                  label: Text(v, style: const TextStyle(fontSize: 11)),
                  selected: filter == v,
                  onSelected: (_) => setState(() => filter = v),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 22),
        if (!proHistory && app.history.length > visibleHistory.length)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ActionButton(
              'Unlock your full history',
              secondary: true,
              onTap: () => openPage(context, const SubscriptionPage()),
            ),
          ),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 42),
            child: Column(
              children: [
                iconTile(context, CupertinoIcons.clock, size: 78),
                const SizedBox(height: 24),
                Text(
                  app.history.isEmpty
                      ? 'Your first moment of clarity.'
                      : 'No checks found.',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  app.history.isEmpty
                      ? 'Check a message or link.\nYour results will find a home here.'
                      : 'Try another search or filter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.subtle,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 27),
                ActionButton(
                  'Check something',
                  onTap: () => openPage(context, const CheckPage()),
                ),
              ],
            ),
          )
        else
          ...results.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HistoryCard(r),
            ),
          ),
      ],
    );
  }
}

class HistoryCard extends StatelessWidget {
  final ScanResult result;
  const HistoryCard(this.result, {super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return GestureDetector(
      onTap: () => openPage(context, ResultPage(result: result)),
      child: Surface(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            iconTile(
              context,
              CupertinoIcons.doc_text_search,
              color: verdictColor(result.verdict),
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.input,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${result.date.day}/${result.date.month} · On-device check',
                    style: TextStyle(color: context.subtle, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (result.report != null)
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value != 'delete') return;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete this report?'),
                      content: const Text(
                        'This removes its saved scan record from this device.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) app.removeReport(result.report!.id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Delete report')),
                ],
              ),
            Pill(result.verdict, color: verdictColor(result.verdict)),
          ],
        ),
      ),
    );
  }
}
