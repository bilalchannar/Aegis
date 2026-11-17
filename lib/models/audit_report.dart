import 'dart:convert';

enum ScanInputType { message, url, screenshot }

enum RiskLevel { critical, high, medium, low, inconclusive }

enum FindingSeverity { critical, high, medium, low }

enum AnalysisSource { deterministic, ai, threatIntelligence, ocrVision }

enum CheckStatus { passed, flagged, unavailable, error, inconclusive }

enum RecommendationPriority { immediate, high, medium, low }

String _enumValue(Object? value) => value.toString().split('.').last;

T _enumFrom<T>(Iterable<T> values, String? value, T fallback) {
  for (final item in values) {
    if (_enumValue(item) == value) return item;
  }
  return fallback;
}

class ScanInput {
  final ScanInputType type;
  final String value;
  final String? mimeType;
  final int? sizeBytes;

  const ScanInput({
    required this.type,
    required this.value,
    this.mimeType,
    this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
    'type': _enumValue(type),
    'value': value,
    if (mimeType != null) 'mimeType': mimeType,
    if (sizeBytes != null) 'sizeBytes': sizeBytes,
  };

  factory ScanInput.fromJson(Map<String, dynamic> json) => ScanInput(
    type: _enumFrom(
      ScanInputType.values,
      json['type'] as String?,
      ScanInputType.message,
    ),
    value: json['value'] is String ? json['value'] as String : '',
    mimeType: json['mimeType'] as String?,
    sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
  );
}

class Evidence {
  final String text;
  final int? start;
  final int? end;
  final String explanation;

  const Evidence({
    required this.text,
    required this.explanation,
    this.start,
    this.end,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'explanation': explanation,
    if (start != null) 'start': start,
    if (end != null) 'end': end,
  };

  factory Evidence.fromJson(Map<String, dynamic> json) => Evidence(
    text: json['text'] is String ? json['text'] as String : '',
    explanation: json['explanation'] is String
        ? json['explanation'] as String
        : '',
    start: (json['start'] as num?)?.toInt(),
    end: (json['end'] as num?)?.toInt(),
  );
}

class Finding {
  final String title;
  final String? ruleId;
  final String? category;
  final AnalysisSource? source;
  final FindingSeverity severity;
  final String explanation;
  final String confidence;
  final List<Evidence> evidence;
  final String attackType;
  final RecommendationPriority priority;
  final String recommendedAction;
  final String? limitation;

  const Finding({
    required this.title,
    this.ruleId,
    this.category,
    this.source,
    required this.severity,
    required this.explanation,
    required this.confidence,
    required this.evidence,
    required this.attackType,
    required this.priority,
    required this.recommendedAction,
    this.limitation,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    if (ruleId != null) 'ruleId': ruleId,
    if (category != null) 'category': category,
    if (source != null) 'source': _enumValue(source!),
    'severity': _enumValue(severity),
    'explanation': explanation,
    'confidence': confidence,
    'evidence': evidence.map((item) => item.toJson()).toList(),
    'attackType': attackType,
    'priority': _enumValue(priority),
    'recommendedAction': recommendedAction,
    if (limitation != null) 'limitation': limitation,
  };

  factory Finding.fromJson(Map<String, dynamic> json) => Finding(
    title: json['title'] is String ? json['title'] as String : 'Finding',
    ruleId: json['ruleId'] is String ? json['ruleId'] as String : null,
    category: json['category'] is String ? json['category'] as String : null,
    source: json['source'] is String
        ? _enumFrom(
            AnalysisSource.values,
            json['source'] as String,
            AnalysisSource.deterministic,
          )
        : null,
    severity: _enumFrom(
      FindingSeverity.values,
      json['severity'] as String?,
      FindingSeverity.medium,
    ),
    explanation: json['explanation'] is String
        ? json['explanation'] as String
        : '',
    confidence: json['confidence'] is String
        ? json['confidence'] as String
        : 'Uncalibrated deterministic assessment',
    evidence: _mapList(
      json['evidence'],
    ).map(Evidence.fromJson).toList(growable: false),
    attackType: json['attackType'] is String
        ? json['attackType'] as String
        : 'Suspicious activity',
    priority: _enumFrom(
      RecommendationPriority.values,
      json['priority'] as String?,
      RecommendationPriority.medium,
    ),
    recommendedAction: json['recommendedAction'] is String
        ? json['recommendedAction'] as String
        : 'Verify independently before acting.',
    limitation: json['limitation'] is String
        ? json['limitation'] as String
        : null,
  );
}

class Recommendation {
  final RecommendationPriority priority;
  final String title;
  final String why;
  final List<String> steps;
  final String expectedOutcome;
  final bool requiresConfirmation;

  const Recommendation({
    required this.priority,
    required this.title,
    required this.why,
    required this.steps,
    required this.expectedOutcome,
    required this.requiresConfirmation,
  });

  Map<String, dynamic> toJson() => {
    'priority': _enumValue(priority),
    'title': title,
    'why': why,
    'steps': steps,
    'expectedOutcome': expectedOutcome,
    'requiresConfirmation': requiresConfirmation,
  };

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
    priority: _enumFrom(
      RecommendationPriority.values,
      json['priority'] as String?,
      RecommendationPriority.medium,
    ),
    title: json['title'] is String ? json['title'] as String : 'Verify safely',
    why: json['why'] is String ? json['why'] as String : '',
    steps: _stringList(json['steps']),
    expectedOutcome: json['expectedOutcome'] is String
        ? json['expectedOutcome'] as String
        : '',
    requiresConfirmation: json['requiresConfirmation'] == true,
  );
}

class AnalysisCheck {
  final String name;
  final AnalysisSource source;
  final CheckStatus status;
  final String detail;

  const AnalysisCheck({
    required this.name,
    required this.source,
    required this.status,
    required this.detail,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'source': _enumValue(source),
    'status': _enumValue(status),
    'detail': detail,
  };

  factory AnalysisCheck.fromJson(Map<String, dynamic> json) => AnalysisCheck(
    name: json['name'] is String ? json['name'] as String : 'Analysis check',
    source: _enumFrom(
      AnalysisSource.values,
      json['source'] as String?,
      AnalysisSource.deterministic,
    ),
    status: _enumFrom(
      CheckStatus.values,
      json['status'] as String?,
      CheckStatus.inconclusive,
    ),
    detail: json['detail'] is String ? json['detail'] as String : '',
  );
}

class AnalysisLimitation {
  final String title;
  final String detail;

  const AnalysisLimitation({required this.title, required this.detail});

  Map<String, dynamic> toJson() => {'title': title, 'detail': detail};

  factory AnalysisLimitation.fromJson(Map<String, dynamic> json) =>
      AnalysisLimitation(
        title: json['title'] is String ? json['title'] as String : 'Limitation',
        detail: json['detail'] is String ? json['detail'] as String : '',
      );
}

class AuditReport {
  static const currentSchemaVersion = 1;
  final String id;
  final DateTime createdAt;
  final ScanInput input;
  final int? riskScore;
  final RiskLevel riskLevel;
  final String executiveSummary;
  final String? extractedText;
  final List<Finding> findings;
  final List<Recommendation> recommendations;
  final List<AnalysisCheck> checks;
  final List<AnalysisLimitation> limitations;
  final Set<AnalysisSource> sources;
  final bool aiRan;
  final int schemaVersion;

  const AuditReport({
    required this.id,
    required this.createdAt,
    required this.input,
    required this.riskScore,
    required this.riskLevel,
    required this.executiveSummary,
    this.extractedText,
    required this.findings,
    required this.recommendations,
    required this.checks,
    required this.limitations,
    required this.sources,
    required this.aiRan,
    this.schemaVersion = currentSchemaVersion,
  });

  bool get isInconclusive =>
      riskLevel == RiskLevel.inconclusive || riskScore == null;

  String get analysisLabel {
    final providerCheck = checks.where(
      (check) =>
          check.source == AnalysisSource.ai ||
          check.source == AnalysisSource.ocrVision,
    );
    final usedGroq = providerCheck.any(
      (check) => check.name.toLowerCase().contains('groq'),
    );
    final usedGemini = providerCheck.any(
      (check) => check.name.toLowerCase().contains('gemini'),
    );
    final aiFailed = providerCheck.any(
      (check) => check.status == CheckStatus.error,
    );
    if (aiRan && usedGroq) {
      return 'AI-generated report • Groq fallback';
    }
    if (aiRan && usedGemini) {
      return 'AI-generated report • Gemini';
    }
    if (aiRan) {
      return 'AI-generated report';
    }
    if (aiFailed) {
      return 'Deterministic rules • AI unavailable';
    }
    return 'Deterministic rules only';
  }

  AuditReport copyWith({
    int? riskScore,
    RiskLevel? riskLevel,
    String? executiveSummary,
    String? extractedText,
    List<Finding>? findings,
    List<Recommendation>? recommendations,
    List<AnalysisCheck>? checks,
    List<AnalysisLimitation>? limitations,
    Set<AnalysisSource>? sources,
    bool? aiRan,
  }) => AuditReport(
    id: id,
    createdAt: createdAt,
    input: input,
    riskScore: riskScore ?? this.riskScore,
    riskLevel: riskLevel ?? this.riskLevel,
    executiveSummary: executiveSummary ?? this.executiveSummary,
    extractedText: extractedText ?? this.extractedText,
    findings: findings ?? this.findings,
    recommendations: recommendations ?? this.recommendations,
    checks: checks ?? this.checks,
    limitations: limitations ?? this.limitations,
    sources: sources ?? this.sources,
    aiRan: aiRan ?? this.aiRan,
    schemaVersion: schemaVersion,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'input': input.toJson(),
    if (riskScore != null) 'riskScore': riskScore,
    'riskLevel': _enumValue(riskLevel),
    'executiveSummary': executiveSummary,
    if (extractedText != null) 'extractedText': extractedText,
    'findings': findings.map((item) => item.toJson()).toList(),
    'recommendations': recommendations.map((item) => item.toJson()).toList(),
    'checks': checks.map((item) => item.toJson()).toList(),
    'limitations': limitations.map((item) => item.toJson()).toList(),
    'sources': sources.map(_enumValue).toList(),
    'aiRan': aiRan,
  };

  String encode() => jsonEncode(toJson());

  factory AuditReport.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    return AuditReport(
      id: json['id'] is String ? json['id'] as String : _newId(),
      createdAt: createdAt ?? DateTime.now(),
      input: json['input'] is Map
          ? ScanInput.fromJson(Map<String, dynamic>.from(json['input'] as Map))
          : const ScanInput(type: ScanInputType.message, value: ''),
      riskScore: (json['riskScore'] as num?)?.toInt(),
      riskLevel: _enumFrom(
        RiskLevel.values,
        json['riskLevel'] as String?,
        RiskLevel.inconclusive,
      ),
      executiveSummary: json['executiveSummary'] is String
          ? json['executiveSummary'] as String
          : 'This assessment is inconclusive.',
      extractedText: json['extractedText'] is String
          ? json['extractedText'] as String
          : null,
      findings: _mapList(
        json['findings'],
      ).map(Finding.fromJson).toList(growable: false),
      recommendations: _mapList(
        json['recommendations'],
      ).map(Recommendation.fromJson).toList(growable: false),
      checks: _mapList(
        json['checks'],
      ).map(AnalysisCheck.fromJson).toList(growable: false),
      limitations: _mapList(
        json['limitations'],
      ).map(AnalysisLimitation.fromJson).toList(growable: false),
      sources: _stringList(json['sources'])
          .map(
            (value) => _enumFrom(
              AnalysisSource.values,
              value,
              AnalysisSource.deterministic,
            ),
          )
          .toSet(),
      aiRan: json['aiRan'] == true,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
    );
  }

  factory AuditReport.decode(String value) =>
      AuditReport.fromJson(Map<String, dynamic>.from(jsonDecode(value) as Map));
}

List<String> _stringList(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const [];

List<Map<String, dynamic>> _mapList(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const [];

String _newId() => '${DateTime.now().microsecondsSinceEpoch}';
