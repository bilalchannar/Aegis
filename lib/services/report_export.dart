import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/audit_report.dart';

enum ReportPalette { forest, ocean, plum }

class ReportOptions {
  final String title;
  final String subtitle;
  final ReportPalette palette;
  final bool executive,
      original,
      findings,
      evidence,
      methodology,
      recommendations,
      limitations,
      detailed;

  const ReportOptions({
    this.title = 'Security assessment report',
    this.subtitle = 'Prepared with Aegis',
    this.palette = ReportPalette.forest,
    this.executive = true,
    this.original = true,
    this.findings = true,
    this.evidence = true,
    this.methodology = true,
    this.recommendations = true,
    this.limitations = true,
    this.detailed = true,
  });
}

class ReportExport {
  static PdfColor _brand(ReportPalette palette) => switch (palette) {
    ReportPalette.forest => PdfColor.fromInt(0xFF163C34),
    ReportPalette.ocean => PdfColor.fromInt(0xFF24546A),
    ReportPalette.plum => PdfColor.fromInt(0xFF59456F),
  };

  static Future<Uint8List> build(
    AuditReport report, {
    ReportOptions options = const ReportOptions(),
  }) async {
    final pdf = pw.Document();
    final brand = _brand(options.palette);
    final pale = PdfColor(brand.red, brand.green, brand.blue, .10);
    final logoBytes = (await rootBundle.load(
      'assets/app-icon.png',
    )).buffer.asUint8List();
    final logo = pw.MemoryImage(logoBytes);
    final scanTime = report.createdAt.toLocal();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(44),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Image(logo, width: 70, height: 70),
                pw.SizedBox(width: 15),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AEGIS',
                      style: pw.TextStyle(
                        color: brand,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'PERSONAL SECURITY',
                      style: pw.TextStyle(
                        color: PdfColors.grey700,
                        fontSize: 8,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 70),
            pw.Container(width: 62, height: 4, color: brand),
            pw.SizedBox(height: 22),
            pw.Text(
              options.title,
              style: pw.TextStyle(
                fontSize: 30,
                color: brand,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (options.subtitle.trim().isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                options.subtitle,
                style: pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
              ),
            ],
            pw.SizedBox(height: 36),
            _riskCard(report, brand, pale),
            pw.Spacer(),
            pw.Text(
              'Reference ${report.id}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Scanned ${scanTime.toString()}  |  ${report.input.type.name.toUpperCase()}  |  ${report.analysisLabel}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'This document summarizes one local Aegis assessment. It is intended for personal review and does not verify an organization, transaction, or sender.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );

    final sections = <pw.Widget>[];
    sections.add(_sectionTitle('Scan overview', brand));
    sections.add(
      _table(
        ['Field', 'Details'],
        [
          ['Scan type', report.input.type.name],
          ['Risk level', report.riskLevel.name.toUpperCase()],
          [
            'Risk score',
            report.riskScore == null
                ? 'Not available'
                : '${report.riskScore}/100',
          ],
          ['Scan source', report.analysisLabel],
          ['Date', scanTime.toString()],
          ['Reference', report.id],
        ],
        brand,
      ),
    );

    if (options.executive) {
      sections.add(_sectionTitle('Executive summary', brand));
      sections.add(pw.Paragraph(text: report.executiveSummary));
    }
    if (options.original) {
      sections.add(_sectionTitle('Scanned content', brand));
      final content = report.input.type == ScanInputType.screenshot
          ? (report.extractedText?.trim().isNotEmpty == true
                ? report.extractedText!
                : 'Screenshot image was assessed. Extracted text was not available.')
          : report.input.value;
      sections.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: pale,
            border: pw.Border.all(color: brand, width: .5),
          ),
          child: pw.Text(
            content,
            style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
          ),
        ),
      );
    }
    if (options.findings) {
      sections.add(_sectionTitle('Detection findings', brand));
      if (report.findings.isEmpty) {
        sections.add(
          pw.Text('No warning signs were identified by this assessment.'),
        );
      } else {
        final detailed = options.detailed;
        sections.add(
          _table(
            detailed
                ? const ['#', 'Warning sign', 'Severity', 'Explanation']
                : const ['#', 'Warning sign', 'Severity'],
            [
              for (var i = 0; i < report.findings.length; i++)
                detailed
                    ? [
                        '${i + 1}',
                        report.findings[i].title,
                        report.findings[i].severity.name.toUpperCase(),
                        report.findings[i].explanation,
                      ]
                    : [
                        '${i + 1}',
                        report.findings[i].title,
                        report.findings[i].severity.name.toUpperCase(),
                      ],
            ],
            brand,
            widths: detailed
                ? const [0.4, 1.2, 0.6, 2.8]
                : const [0.4, 2.8, 0.8],
          ),
        );
        if (options.evidence && detailed) {
          for (var i = 0; i < report.findings.length; i++) {
            final finding = report.findings[i];
            if (finding.evidence.isNotEmpty) {
              sections.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4, left: 10),
                  child: pw.Text(
                    'Evidence ${i + 1}: ${finding.evidence.map((e) => '${e.text} - ${e.explanation}').join('; ')}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              );
            }
          }
        }
      }
    }
    if (options.methodology) {
      sections.add(_sectionTitle('Methodology', brand));
      sections.add(
        pw.Text(
          '${report.analysisLabel}. Findings are derived from the checks listed below. The score is a heuristic indicator, not a statistically calibrated probability.',
          style: const pw.TextStyle(fontSize: 9),
        ),
      );
      if (report.checks.isNotEmpty && options.detailed) {
        sections.add(
          _table(
            ['Check', 'Source', 'Status', 'Details'],
            [
              for (final check in report.checks)
                [
                  check.name,
                  check.source.name,
                  check.status.name,
                  check.detail,
                ],
            ],
            brand,
            widths: const [1.2, 0.8, 0.8, 2.2],
          ),
        );
      }
    }
    if (options.recommendations) {
      sections.add(_sectionTitle('Recommendations', brand));
      if (report.recommendations.isEmpty) {
        sections.add(
          pw.Text(
            'Pause and verify independently using a trusted contact or official channel.',
          ),
        );
      } else {
        sections.add(
          _table(
            ['#', 'Recommended action', 'Priority'],
            [
              for (var i = 0; i < report.recommendations.length; i++)
                [
                  '${i + 1}',
                  '${report.recommendations[i].title}: ${report.recommendations[i].steps.join(' ')}',
                  report.recommendations[i].priority.name.toUpperCase(),
                ],
            ],
            brand,
            widths: const [0.4, 3, 0.6],
          ),
        );
      }
    }
    if (options.limitations) {
      sections.add(_sectionTitle('Limitations and safety guidance', brand));
      for (final limitation in report.limitations) {
        sections.add(
          pw.Text(
            '- ${limitation.title}: ${limitation.detail}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        );
      }
      sections.add(
        pw.Text(
          'Aegis provides heuristic awareness guidance. A low score does not guarantee safety. Do not share OTPs, PINs, passwords, recovery codes, or payment details with an unverified contact.',
          style: const pw.TextStyle(fontSize: 9),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 52, 42, 48),
        header: (_) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'AEGIS  |  SECURITY ASSESSMENT',
              style: pw.TextStyle(
                color: brand,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              report.id,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Private report - generated locally',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
        build: (_) => sections,
      ),
    );
    return Uint8List.fromList(await pdf.save());
  }

  static pw.Widget _riskCard(
    AuditReport report,
    PdfColor brand,
    PdfColor pale,
  ) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(20),
    decoration: pw.BoxDecoration(
      color: pale,
      border: pw.Border(left: pw.BorderSide(color: brand, width: 4)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RISK CLASSIFICATION',
          style: pw.TextStyle(
            color: brand,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 9),
        pw.Text(
          '${report.riskLevel.name.toUpperCase()}${report.riskScore == null ? '' : '  |  ${report.riskScore}/100'}',
          style: pw.TextStyle(
            color: brand,
            fontSize: 21,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 7),
        pw.Text(
          report.executiveSummary,
          style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
        ),
      ],
    ),
  );
  static pw.Widget _sectionTitle(String title, PdfColor brand) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        color: brand,
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
  static pw.Widget _table(
    List<String> headers,
    List<List<String>> rows,
    PdfColor brand, {
    List<double>? widths,
  }) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(
      color: PdfColors.white,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
    ),
    cellStyle: const pw.TextStyle(fontSize: 8, lineSpacing: 1.5),
    headerDecoration: pw.BoxDecoration(color: brand),
    rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
    oddRowDecoration: const pw.BoxDecoration(color: PdfColor(0.95, 0.97, 0.95)),
    border: pw.TableBorder.all(color: PdfColors.grey400, width: .4),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
    columnWidths: widths == null
        ? null
        : {
            for (var i = 0; i < widths.length; i++)
              i: pw.FlexColumnWidth(widths[i]),
          },
  );

  static Future<bool> preview(
    AuditReport report, {
    ReportOptions options = const ReportOptions(),
  }) => Printing.layoutPdf(onLayout: (_) => build(report, options: options));
  static Future<bool> share(
    AuditReport report, {
    ReportOptions options = const ReportOptions(),
  }) async => Printing.sharePdf(
    bytes: await build(report, options: options),
    filename: 'aegis-${report.id}.pdf',
  );
}
