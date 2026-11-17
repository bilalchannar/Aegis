import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:scam_fraud/models/audit_report.dart';
import 'package:scam_fraud/services/ai_analyzer.dart';
import 'package:scam_fraud/services/api_config.dart';
import 'package:scam_fraud/services/threat_intelligence.dart';
import 'package:scam_fraud/services/scanner.dart';

class FakeClient extends http.BaseClient {
  final http.Response Function(http.BaseRequest) handler;
  FakeClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

class DelayedClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{}')),
      200,
      request: request,
    );
  }
}

Map<String, dynamic> validReport() => {
  'riskScore': 75,
  'riskLevel': 'high',
  'executiveSummary': 'The message requests a secret code.',
  'findings': [
    {
      'title': 'Credential request',
      'severity': 'critical',
      'explanation': 'The content requests an authentication code.',
      'confidence': 'Uncalibrated AI assessment.',
      'evidence': [
        {'text': 'OTP', 'explanation': 'Codes should not be shared.'},
      ],
      'attackType': 'Credential theft',
      'priority': 'immediate',
      'recommendedAction': 'Do not share the code.',
    },
  ],
  'recommendations': [
    {
      'priority': 'immediate',
      'title': 'Pause',
      'why': 'The request is unverified.',
      'steps': ['Verify independently.'],
      'expectedOutcome': 'No secret is disclosed.',
      'requiresConfirmation': false,
    },
  ],
  'limitations': [],
};

http.Response geminiResponse(Object value) => http.Response(
  jsonEncode({
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': jsonEncode(value)},
          ],
        },
      },
    ],
  }),
  200,
);

void main() {
  test(
    'Configuration validation accepts the demo model and rejects bad values',
    () {
      expect(ApiConfig.geminiModel, 'gemini-2.5-flash');
      expect(
        ApiConfig.validate(apiKey: '', model: 'gemini-3.8-flash'),
        isNotNull,
      );
      expect(ApiConfig.validate(apiKey: 'key', model: ''), isNotNull);
      expect(
        ApiConfig.validate(apiKey: 'key', model: 'models/gemini-3.8-flash'),
        isNotNull,
      );
      expect(
        ApiConfig.validate(apiKey: 'key', model: 'gemini-3.8-flash'),
        isNull,
      );
    },
  );

  test('Missing AI configuration fails without a fallback report', () async {
    final analyzer = AiAnalyzer(apiKey: '', groqApiKey: '');
    await expectLater(
      analyzer.analyzeMessage('hello'),
      throwsA(
        isA<AnalysisServiceException>().having(
          (error) => error.configuration,
          'configuration',
          true,
        ),
      ),
    );
  });

  test('Groq is used when Gemini fails', () async {
    final hosts = <String>[];
    final analyzer = AiAnalyzer(
      apiKey: 'bad-gemini-key',
      model: 'gemini-3.8-flash',
      groqApiKey: 'test-groq-key',
      groqModel: 'test-groq-model',
      client: FakeClient((request) {
        hosts.add(request.url.host);
        if (request.url.host.contains('google')) {
          return http.Response('{}', 503);
        }
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': jsonEncode(validReport())},
              },
            ],
          }),
          200,
        );
      }),
    );
    final report = await analyzer.analyzeMessage('Send your OTP');
    expect(report.aiRan, isTrue);
    expect(hosts, contains('generativelanguage.googleapis.com'));
    expect(hosts, contains('api.groq.com'));
    expect(report.checks.any((check) => check.detail.contains('Groq')), isTrue);
  });

  test('Groq failure is explicit and does not fabricate a report', () async {
    final analyzer = AiAnalyzer(
      apiKey: 'bad-gemini-key',
      groqApiKey: 'bad-groq-key',
      client: FakeClient((request) => http.Response('{}', 401)),
    );
    await expectLater(
      analyzer.analyzeMessage('hello'),
      throwsA(
        isA<AnalysisServiceException>().having(
          (error) => error.message,
          'message',
          contains('Groq fallback also failed'),
        ),
      ),
    );
  });

  test('Valid Gemini JSON becomes an AI-marked structured report', () async {
    String? requestedPath;
    final analyzer = AiAnalyzer(
      apiKey: 'test-key',
      model: 'gemini-3.8-flash',
      client: FakeClient((request) {
        requestedPath = request.url.path;
        return geminiResponse(validReport());
      }),
    );
    final report = await analyzer.analyzeMessage('Send your OTP');
    expect(report.aiRan, isTrue);
    expect(report.sources, contains(AnalysisSource.ai));
    expect(report.findings.single.evidence.single.text, 'OTP');
    expect(requestedPath, '/v1beta/models/gemini-3.8-flash:generateContent');
  });

  test('Malformed AI JSON is rejected without creating a report', () async {
    final analyzer = AiAnalyzer(
      apiKey: 'test-key',
      client: FakeClient(
        (_) => http.Response(
          '{"candidates":[{"content":{"parts":[{"text":"not json"}]}}]}',
          200,
        ),
      ),
    );
    await expectLater(
      analyzer.analyzeMessage('hello'),
      throwsA(isA<AnalysisServiceException>()),
    );
  });

  test('Invalid AI finding and recommendation enums are rejected', () async {
    final invalid = validReport();
    (invalid['findings'] as List).first['severity'] = 'extreme';
    final analyzer = AiAnalyzer(
      apiKey: 'test-key',
      client: FakeClient((_) => geminiResponse(invalid)),
    );
    await expectLater(
      analyzer.analyzeMessage('hello'),
      throwsA(isA<AnalysisServiceException>()),
    );

    final invalidRecommendation = validReport();
    (invalidRecommendation['recommendations'] as List).first['priority'] =
        'urgent';
    final secondAnalyzer = AiAnalyzer(
      apiKey: 'test-key',
      client: FakeClient((_) => geminiResponse(invalidRecommendation)),
    );
    await expectLater(
      secondAnalyzer.analyzeMessage('hello'),
      throwsA(isA<AnalysisServiceException>()),
    );
  });

  test('AI and deterministic findings are reconciled', () {
    final deterministic = Scanner.analyzeMessage('Send your OTP now.');
    final ai = AuditReport.fromJson({
      ...validReport(),
      'aiRan': true,
      'input': const ScanInput(
        type: ScanInputType.message,
        value: 'Send your OTP now.',
      ).toJson(),
    });
    final merged = Scanner.reconcileReports(deterministic, ai);
    expect(merged.aiRan, isTrue);
    expect(
      merged.findings.any(
        (finding) => finding.title == 'Requests a secret authentication code',
      ),
      isTrue,
    );
    expect(merged.sources, contains(AnalysisSource.deterministic));
    expect(merged.sources, contains(AnalysisSource.ai));
  });

  test('Quota responses are surfaced as quota errors', () async {
    final analyzer = AiAnalyzer(
      apiKey: 'test-key',
      client: FakeClient((_) => http.Response('{}', 429)),
    );
    await expectLater(
      analyzer.analyzeMessage('hello'),
      throwsA(
        isA<AnalysisServiceException>().having(
          (error) => error.quota,
          'quota',
          true,
        ),
      ),
    );
  });

  test('HTTP model and credential errors are explicit', () async {
    for (final status in [400, 401, 403, 404]) {
      final analyzer = AiAnalyzer(
        apiKey: 'test-key',
        client: FakeClient((_) => http.Response('{}', status)),
      );
      await expectLater(
        analyzer.analyzeMessage('hello'),
        throwsA(
          isA<AnalysisServiceException>().having(
            (error) => error.configuration,
            'configuration',
            true,
          ),
        ),
      );
    }
  });

  test('Timeouts are explicit and never become fallback reports', () async {
    final analyzer = AiAnalyzer(
      apiKey: 'test-key',
      timeout: const Duration(milliseconds: 1),
      client: DelayedClient(),
    );
    await expectLater(
      analyzer.analyzeMessage('hello'),
      throwsA(
        isA<AnalysisServiceException>().having(
          (error) => error.timeout,
          'timeout',
          true,
        ),
      ),
    );
  });

  test(
    'Vision requests include the image and preserve screenshot input',
    () async {
      var sawImage = false;
      final analyzer = AiAnalyzer(
        apiKey: 'test-key',
        client: FakeClient((request) {
          sawImage = request.url.path.contains('generateContent');
          return geminiResponse({
            ...validReport(),
            'extractedText': 'Your payment is due',
          });
        }),
      );
      final report = await analyzer.analyzeScreenshot(
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/png',
      );
      expect(sawImage, isTrue);
      expect(report.input.type, ScanInputType.screenshot);
      expect(report.sources, contains(AnalysisSource.ocrVision));
      expect(report.extractedText, 'Your payment is due');
    },
  );

  test(
    'Screenshot validation rejects empty, oversized, and unsupported images',
    () async {
      final analyzer = AiAnalyzer(apiKey: 'test-key');
      await expectLater(
        analyzer.analyzeScreenshot(bytes: Uint8List(0), mimeType: 'image/png'),
        throwsA(isA<AnalysisServiceException>()),
      );
      await expectLater(
        analyzer.analyzeScreenshot(
          bytes: Uint8List(AiAnalyzer.maxImageBytes + 1),
          mimeType: 'image/png',
        ),
        throwsA(isA<AnalysisServiceException>()),
      );
      await expectLater(
        analyzer.analyzeScreenshot(
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/bmp',
        ),
        throwsA(isA<AnalysisServiceException>()),
      );
    },
  );

  test(
    'Missing threat-intelligence configuration is unavailable, not clean',
    () async {
      final result = await ThreatIntelligence(
        apiKey: '',
        client: FakeClient((_) => http.Response('{}', 200)),
      ).checkUrl('https://example.com');
      expect(result.check.status, CheckStatus.unavailable);
      expect(result.finding, isNull);
    },
  );
}
