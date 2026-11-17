import 'package:http/http.dart' as http;
import '../models/audit_report.dart';

/// Optional reputation integration seam. No provider is configured in the
/// local-first build, so absence of credentials is explicitly inconclusive.
class ThreatIntelligenceResult {
  final AnalysisCheck check;
  final Finding? finding;
  const ThreatIntelligenceResult({required this.check, this.finding});
}

class ThreatIntelligence {
  final String apiKey;
  final http.Client client;
  ThreatIntelligence({required this.apiKey, required this.client});

  Future<ThreatIntelligenceResult> checkUrl(String url) async {
    if (apiKey.trim().isEmpty) {
      return const ThreatIntelligenceResult(
        check: AnalysisCheck(
          name: 'Threat intelligence',
          source: AnalysisSource.threatIntelligence,
          status: CheckStatus.unavailable,
          detail:
              'No threat-intelligence provider is configured. This URL was not checked against a live reputation service.',
        ),
      );
    }
    // This app intentionally has no configured reputation endpoint. Do not
    // transmit the URL to an unknown service or imply a live lookup occurred.
    return const ThreatIntelligenceResult(
      check: AnalysisCheck(
        name: 'Threat intelligence',
        source: AnalysisSource.threatIntelligence,
        status: CheckStatus.unavailable,
        detail:
            'No provider endpoint is configured; only local URL heuristics are available.',
      ),
    );
  }
}
