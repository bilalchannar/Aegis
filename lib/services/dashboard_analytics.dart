import '../models/audit_report.dart';
import 'scanner.dart';

class DashboardAnalytics {
  final List<ScanResult> scans;
  final Map<ScanInputType, int> byType;
  final Map<RiskLevel, int> byRisk;
  final Map<String, int> categories;
  final List<int> dailyActivity;

  DashboardAnalytics._(
    this.scans,
    this.byType,
    this.byRisk,
    this.categories,
    this.dailyActivity,
  );

  factory DashboardAnalytics.fromScans(
    Iterable<ScanResult> source, {
    DateTime? start,
    DateTime? end,
    int days = 7,
  }) {
    final unique = <String, ScanResult>{};
    for (final scan in source) {
      final report = scan.report;
      if (start != null &&
          scan.date.isBefore(DateTime(start.year, start.month, start.day))) {
        continue;
      }
      if (end != null &&
          scan.date.isAfter(
            DateTime(end.year, end.month, end.day, 23, 59, 59),
          )) {
        continue;
      }
      final id =
          report?.id ?? '${scan.date.microsecondsSinceEpoch}:${scan.input}';
      unique.putIfAbsent(id, () => scan);
    }
    final scans = unique.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final types = {for (final type in ScanInputType.values) type: 0};
    final risks = {
      for (final risk in [
        RiskLevel.low,
        RiskLevel.medium,
        RiskLevel.high,
        RiskLevel.critical,
      ])
        risk: 0,
    };
    final categories = <String, int>{};
    for (final scan in scans) {
      final report = scan.report;
      if (report == null) continue;
      types[report.input.type] = types[report.input.type]! + 1;
      if (risks.containsKey(report.riskLevel)) {
        risks[report.riskLevel] = risks[report.riskLevel]! + 1;
      }
      for (final finding in report.findings) {
        final category =
            (finding.category?.trim().isNotEmpty == true
                    ? finding.category!
                    : finding.attackType)
                .trim();
        if (category.isNotEmpty) {
          categories.update(category, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }
    final now = end ?? DateTime.now();
    final first =
        start ??
        (days >= 3650 && scans.isNotEmpty
            ? DateTime(
                scans.first.date.year,
                scans.first.date.month,
                scans.first.date.day,
              )
            : DateTime(
                now.year,
                now.month,
                now.day,
              ).subtract(Duration(days: days - 1)));
    final count = now.difference(first).inDays.clamp(0, 3650) + 1;
    final activity = List<int>.filled(count, 0);
    for (final scan in scans) {
      final index = DateTime(
        scan.date.year,
        scan.date.month,
        scan.date.day,
      ).difference(DateTime(first.year, first.month, first.day)).inDays;
      if (index >= 0 && index < activity.length) activity[index]++;
    }
    return DashboardAnalytics._(scans, types, risks, categories, activity);
  }

  int get total => scans.length;
  int get threats =>
      (byRisk[RiskLevel.high] ?? 0) + (byRisk[RiskLevel.critical] ?? 0);
  int get safe =>
      scans.where((r) => r.report?.riskLevel == RiskLevel.low).length;
  int get highRisk => threats;
  String? get mostScannedType {
    if (byType.values.every((count) => count == 0)) return null;
    return byType.entries.reduce((a, b) => a.value >= b.value ? a : b).key.name;
  }
}
