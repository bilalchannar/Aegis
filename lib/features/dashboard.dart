import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/audit_report.dart';
import '../services/dashboard_analytics.dart';
import '../services/pro_access.dart';
import '../services/scanner.dart';
import '../ui/design.dart';

class SecurityDashboardPage extends StatefulWidget {
  const SecurityDashboardPage({super.key});
  @override
  State<SecurityDashboardPage> createState() => _SecurityDashboardPageState();
}

class _SecurityDashboardPageState extends State<SecurityDashboardPage> {
  int days = 7;
  DateTimeRange? custom;

  Future<void> _customRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2018),
      lastDate: now,
      initialDateRange:
          custom ??
          DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now),
    );
    if (selected != null) {
      setState(() {
        custom = selected;
        days = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pro = ProAccess.instance.allows(FeatureAccess.advancedDashboard);
    final end = custom?.end ?? DateTime.now();
    final start =
        custom?.start ??
        (days == 0
            ? null
            : DateTime(
                end.year,
                end.month,
                end.day,
              ).subtract(Duration(days: days - 1)));
    final data = DashboardAnalytics.fromScans(
      app.history,
      start: start,
      end: end,
      days: days == 0 ? 3650 : days,
    );
    return PageFrame(
      title: 'Security dashboard',
      trailing: IconButton(
        tooltip: 'Refresh data',
        onPressed: () => setState(() {}),
        icon: const Icon(CupertinoIcons.refresh),
      ),
      children: [
        const SizedBox(height: 6),
        Text(
          'Your security, ${app.name == 'Your space' ? 'at a glance' : app.name}.',
          style: headline(31),
        ),
        const SizedBox(height: 8),
        caption(
          context,
          'Local scan activity • ${custom != null ? '${custom!.start.month}/${custom!.start.day}–${custom!.end.month}/${custom!.end.day}' : _rangeLabel()}',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _rangeChip('7 days', 7, pro),
            _rangeChip('30 days', 30, pro),
            _rangeChip('90 days', 90, pro),
            _rangeChip('All time', 0, pro),
            ActionChip(
              label: const Text('Custom'),
              avatar: const Icon(CupertinoIcons.calendar, size: 15),
              onPressed: pro
                  ? _customRange
                  : () => openPage(context, const SubscriptionPage()),
            ),
          ],
        ),
        const SizedBox(height: 17),
        if (data.total == 0)
          Surface(
            color: context.soft,
            child: Column(
              children: [
                iconTile(context, CupertinoIcons.chart_bar, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'No saved scans in this date range',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                caption(
                  context,
                  app.saveChecks
                      ? 'Complete a scan to start your personal dashboard.'
                      : 'Turn on saved history if you want scans to appear here.',
                ),
              ],
            ),
          )
        else ...[
          _summaryGrid(data),
          const SizedBox(height: 20),
          _chartCard(
            context,
            'Scan activity',
            'Daily scans across this date range',
            SizedBox(
              height: 174,
              child: _ActivityChart(
                data.dailyActivity,
                context.isDark ? mint : forest,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (pro) ...[
            _chartCard(
              context,
              'Risk distribution',
              'Report classifications in the selected range',
              _RiskChart(data.byRisk, context.isDark),
            ),
            const SizedBox(height: 12),
            _chartCard(
              context,
              'Scan type distribution',
              'Text, URL and screenshot reports',
              _TypeChart(data.byType),
            ),
            const SizedBox(height: 12),
            _chartCard(
              context,
              'Threat categories',
              'Most frequent categories in actual findings',
              _CategoryChart(data.categories),
            ),
            const SizedBox(height: 12),
          ] else ...[
            _chartCard(
              context,
              'Scan type distribution',
              'Basic report counts',
              _TypeChart(data.byType),
            ),
            const SizedBox(height: 12),
            Surface(
              color: context.soft,
              child: Row(
                children: [
                  const Icon(CupertinoIcons.lock_shield, color: green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: caption(
                      context,
                      'Pro unlocks risk distribution, threat category comparisons, longer date ranges and extended insights.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            ActionButton(
              'Explore advanced analytics',
              secondary: true,
              onTap: () => openPage(context, const SubscriptionPage()),
            ),
            const SizedBox(height: 12),
          ],
          _insights(context, data, app.quizBest),
          const SizedBox(height: 12),
          Text(
            'Recent activity',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...data.scans.reversed
              .take(5)
              .map(
                (scan) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _recent(context, scan),
                ),
              ),
        ],
        const SizedBox(height: 12),
        caption(
          context,
          'Analytics include only unique scan reports stored on this device. Scores are heuristics, not probabilities. History opt-out and deletion remove data from these calculations.',
        ),
      ],
    );
  }

  String _rangeLabel() => switch (days) {
    7 => 'Last 7 days',
    30 => 'Last 30 days',
    90 => 'Last 90 days',
    0 => 'All time',
    _ => 'Custom range',
  };
  Widget _rangeChip(String label, int value, bool pro) => ChoiceChip(
    label: Text(label),
    selected: days == value && custom == null,
    onSelected: (_) {
      if (!pro && value != 7) {
        openPage(context, const SubscriptionPage());
        return;
      }
      setState(() {
        days = value;
        custom = null;
      });
    },
  );

  Widget _summaryGrid(DashboardAnalytics data) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 9,
    mainAxisSpacing: 9,
    childAspectRatio: 1.75,
    children: [
      _stat('Total scans', data.total, CupertinoIcons.doc_text_search),
      _stat(
        'Threats detected',
        data.threats,
        CupertinoIcons.exclamationmark_shield,
      ),
      _stat('Safe results', data.safe, CupertinoIcons.checkmark_shield),
      _stat('High risk', data.highRisk, CupertinoIcons.exclamationmark_shield),
      _stat(
        'Text scans',
        data.byType[ScanInputType.message] ?? 0,
        CupertinoIcons.text_alignleft,
      ),
      _stat(
        'URL scans',
        data.byType[ScanInputType.url] ?? 0,
        CupertinoIcons.link,
      ),
      _stat(
        'Screenshot scans',
        data.byType[ScanInputType.screenshot] ?? 0,
        CupertinoIcons.photo,
      ),
    ],
  );

  Widget _stat(String label, int value, IconData icon) => Surface(
    child: Row(
      children: [
        Icon(icon, color: green, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _chartCard(
    BuildContext context,
    String title,
    String subtitle,
    Widget chart,
  ) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        caption(context, subtitle),
        const SizedBox(height: 14),
        chart,
      ],
    ),
  );

  Widget _insights(
    BuildContext context,
    DashboardAnalytics data,
    int quizBest,
  ) {
    final category = data.categories.entries.isEmpty
        ? null
        : data.categories.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return Surface(
      color: context.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          eyebrow(context, 'PERSONAL INSIGHTS'),
          const SizedBox(height: 9),
          Text(
            'Most scanned: ${data.mostScannedType ?? 'No type data'}',
            style: const TextStyle(fontSize: 12),
          ),
          if (category != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Most common finding: ${category.key} (${category.value})',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Quiz best score: $quizBest%',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recent(BuildContext context, ScanResult scan) {
    final report = scan.report;
    final risk = report?.riskLevel.name.toUpperCase() ?? scan.verdict;
    final type = report?.input.type.name ?? 'scan';
    return Surface(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: report == null
            ? null
            : () => openPage(context, _DashboardReportPage(report)),
        child: Row(
          children: [
            Icon(CupertinoIcons.doc_text, color: green),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${type.toUpperCase()} • $risk',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    report?.executiveSummary ?? scan.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.subtle, fontSize: 10),
                  ),
                  Text(
                    '${scan.date.month}/${scan.date.day}/${scan.date.year}',
                    style: TextStyle(color: context.subtle, fontSize: 9),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 15),
          ],
        ),
      ),
    );
  }
}

class _DashboardReportPage extends StatelessWidget {
  final AuditReport report;
  const _DashboardReportPage(this.report);
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Scan report',
    children: [
      const SizedBox(height: 12),
      Text(
        '${report.riskLevel.name.toUpperCase()}${report.riskScore == null ? '' : ' • ${report.riskScore}/100'}',
        style: headline(30),
      ),
      const SizedBox(height: 12),
      Text(report.executiveSummary),
      const SizedBox(height: 15),
      ...report.findings.map(
        (f) => ListTile(title: Text(f.title), subtitle: Text(f.explanation)),
      ),
      ...report.recommendations.map(
        (r) =>
            ListTile(title: Text(r.title), subtitle: Text(r.steps.join(' '))),
      ),
    ],
  );
}

class _ActivityChart extends StatelessWidget {
  final List<int> values;
  final Color color;
  const _ActivityChart(this.values, this.color);
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(double.infinity, 155),
    painter: _ActivityPainter(values, color),
  );
}

class _ActivityPainter extends CustomPainter {
  final List<int> values;
  final Color color;
  _ActivityPainter(this.values, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    const pad = 14.0;
    final w = size.width - pad * 2;
    final h = size.height - 22;
    final grid = Paint()
      ..color = const Color(0xFF9AA9A0).withValues(alpha: .25)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = h * i / 3;
      canvas.drawLine(Offset(pad, y), Offset(size.width - pad, y), grid);
    }
    if (values.isEmpty) return;
    final maxValue = math.max(1, values.reduce(math.max));
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : pad + w * i / (values.length - 1);
      final y = h - values[i] / maxValue * (h - 10) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(pad + w, h)
      ..lineTo(pad, h)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: .10));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : pad + w * i / (values.length - 1);
      final y = h - values[i] / maxValue * (h - 10) - 4;
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityPainter old) =>
      !listEquals(values, old.values) || color != old.color;
}

class _RiskChart extends StatelessWidget {
  final Map<RiskLevel, int> values;
  final bool dark;
  const _RiskChart(this.values, this.dark);
  @override
  Widget build(BuildContext context) {
    final colors = [green, amber, rust, const Color(0xFF7D3035)];
    final risks = [
      RiskLevel.low,
      RiskLevel.medium,
      RiskLevel.high,
      RiskLevel.critical,
    ];
    return Row(
      children: [
        SizedBox(
          width: 132,
          height: 132,
          child: CustomPaint(
            painter: _DonutPainter([
              for (final r in risks) values[r] ?? 0,
            ], colors),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < risks.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: colors[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          risks[i].name,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Text(
                        '${values[risks[i]] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;
  _DonutPainter(this.values, this.colors);
  @override
  void paint(Canvas c, Size s) {
    final total = values.fold<int>(0, (a, b) => a + b);
    final rect = Rect.fromLTWH(8, 8, s.width - 16, s.height - 16);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 19
      ..strokeCap = StrokeCap.butt;
    var start = -math.pi / 2;
    if (total == 0) {
      p.color = const Color(0xFFB8C2BC);
      c.drawArc(rect, 0, math.pi * 2, false, p);
      return;
    }
    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      p.color = colors[i];
      final sweep = math.pi * 2 * values[i] / total;
      c.drawArc(rect, start, sweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      !listEquals(values, old.values);
}

class _TypeChart extends StatelessWidget {
  final Map<ScanInputType, int> values;
  const _TypeChart(this.values);
  @override
  Widget build(BuildContext context) {
    final types = [
      ScanInputType.message,
      ScanInputType.url,
      ScanInputType.screenshot,
    ];
    final max = math.max(1, values.values.fold<int>(0, math.max));
    return Column(
      children: [
        for (final type in types)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 82,
                  child: Text(type.name, style: const TextStyle(fontSize: 10)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: LinearProgressIndicator(
                      value: (values[type] ?? 0) / max,
                      minHeight: 9,
                      backgroundColor: context.line,
                      color: green,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  '${values[type] ?? 0}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final Map<String, int> values;
  const _CategoryChart(this.values);
  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return caption(context, 'No categorized findings in this range.');
    }
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = entries.first.value;
    return Column(
      children: [
        for (final item in entries.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 95,
                  child: Text(
                    item.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: LinearProgressIndicator(
                      value: item.value / max,
                      minHeight: 9,
                      backgroundColor: context.line,
                      color: forest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${item.value}', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
      ],
    );
  }
}
