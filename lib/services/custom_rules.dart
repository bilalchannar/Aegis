import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audit_report.dart';

class CustomDetectionRule {
  final String id, phrase, explanation;
  final FindingSeverity severity;
  const CustomDetectionRule({
    required this.id,
    required this.phrase,
    required this.explanation,
    required this.severity,
  });
  Map<String, Object?> toJson() => {
    'id': id,
    'phrase': phrase,
    'explanation': explanation,
    'severity': severity.name,
  };
  factory CustomDetectionRule.fromJson(Map<String, dynamic> json) =>
      CustomDetectionRule(
        id:
            json['id'] as String? ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        phrase: json['phrase'] as String? ?? '',
        explanation:
            json['explanation'] as String? ?? 'Matched a user-defined phrase.',
        severity: FindingSeverity.values.firstWhere(
          (v) => v.name == json['severity'],
          orElse: () => FindingSeverity.medium,
        ),
      );
}

class CustomRuleBook extends ChangeNotifier {
  CustomRuleBook._();
  static final instance = CustomRuleBook._();
  static const _key = 'customDetectionRules';
  List<CustomDetectionRule> rules = [];
  Future<void>? _loading;

  Future<void> load() => _loading ??= _read();
  Future<void> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_key) ?? const <String>[];
    final restored = <CustomDetectionRule>[];
    for (final value in encoded) {
      try {
        restored.add(
          CustomDetectionRule.fromJson(
            Map<String, dynamic>.from(jsonDecode(value) as Map),
          ),
        );
      } catch (_) {
        // Ignore malformed local rule entries and keep other rules usable.
      }
    }
    rules = restored;
  }

  Future<bool> add(
    String phrase,
    String explanation,
    FindingSeverity severity,
  ) async {
    await load();
    final normalized = phrase.trim();
    if (normalized.length < 3 ||
        rules.any((r) => r.phrase.toLowerCase() == normalized.toLowerCase())) {
      return false;
    }
    rules = [
      ...rules,
      CustomDetectionRule(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        phrase: normalized,
        explanation: explanation.trim().isEmpty
            ? 'Matched a phrase you chose to flag.'
            : explanation.trim(),
        severity: severity,
      ),
    ];
    await _save();
    return true;
  }

  Future<void> remove(String id) async {
    await load();
    rules = rules.where((rule) => rule.id != id).toList();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      rules.map((r) => jsonEncode(r.toJson())).toList(),
    );
    notifyListeners();
  }

  Future<AuditReport> apply(AuditReport report, String input) async {
    await load();
    final matched = rules
        .where(
          (rule) => input.toLowerCase().contains(rule.phrase.toLowerCase()),
        )
        .toList();
    if (matched.isEmpty) {
      return report;
    }
    final additions = matched
        .map(
          (rule) => Finding(
            title: 'Your rule matched: ${rule.phrase}',
            ruleId: 'USER-${rule.id}',
            category: 'user_defined',
            source: AnalysisSource.deterministic,
            severity: rule.severity,
            explanation: rule.explanation,
            confidence: 'Local user-defined phrase match',
            evidence: [
              Evidence(
                text: rule.phrase,
                explanation:
                    'This phrase matched a rule stored on this device.',
              ),
            ],
            attackType: 'User-defined indicator',
            priority: RecommendationPriority.medium,
            recommendedAction: 'Pause and verify independently.',
          ),
        )
        .toList();
    final scoreFloor = matched
        .map(
          (rule) => switch (rule.severity) {
            FindingSeverity.critical => 90,
            FindingSeverity.high => 70,
            FindingSeverity.medium => 40,
            FindingSeverity.low => 15,
          },
        )
        .reduce((a, b) => a > b ? a : b);
    final score = report.riskScore == null
        ? scoreFloor
        : (report.riskScore! > scoreFloor ? report.riskScore! : scoreFloor);
    final level = score >= 90
        ? RiskLevel.critical
        : score >= 70
        ? RiskLevel.high
        : score >= 40
        ? RiskLevel.medium
        : RiskLevel.low;
    return report.copyWith(
      riskScore: score,
      riskLevel: level,
      findings: [...report.findings, ...additions],
      sources: {...report.sources, AnalysisSource.deterministic},
    );
  }
}
