class ApiConfig {
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );
  static const groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const groqModel = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'qwen/qwen3.8-27b',
  );

  static bool get hasGemini => geminiApiKey.trim().isNotEmpty;
  static bool get hasGroq => groqApiKey.trim().isNotEmpty;
  static bool get hasAi => hasGemini || hasGroq;

  static String? validate({String? apiKey, String? model}) {
    final key = (apiKey ?? geminiApiKey).trim();
    final selectedModel = (model ?? geminiModel).trim();
    if (key.isEmpty) return 'GEMINI_API_KEY is missing or empty.';
    if (selectedModel.isEmpty) return 'GEMINI_MODEL is missing or empty.';
    if (selectedModel.contains('/') ||
        selectedModel.contains(':') ||
        selectedModel.contains(' ')) {
      return 'GEMINI_MODEL must be a model identifier such as gemini-3.8-flash.';
    }
    return null;
  }

  static String? validateGroq({String? apiKey, String? model}) {
    final key = (apiKey ?? groqApiKey).trim();
    final selectedModel = (model ?? groqModel).trim();
    if (key.isEmpty) return 'GROQ_API_KEY is missing or empty.';
    if (selectedModel.isEmpty) return 'GROQ_MODEL is missing or empty.';
    if (selectedModel.contains(' ')) {
      return 'GROQ_MODEL must be a valid Groq model identifier.';
    }
    return null;
  }
}

class AnalysisServiceException implements Exception {
  final String message;
  final bool configuration;
  final bool quota;
  final bool timeout;

  const AnalysisServiceException(
    this.message, {
    this.configuration = false,
    this.quota = false,
    this.timeout = false,
  });

  @override
  String toString() => message;
}
