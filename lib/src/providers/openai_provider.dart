import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../prompt/prompt_builder.dart';
import 'ai_provider.dart';

/// Provider for OpenAI and all OpenAI-compatible services.
class OpenAiProvider implements AiProvider {
  final String _customName;

  @override
  String get name => _customName;

  @override
  final ProviderConfig config;

  final http.Client _client;

  OpenAiProvider(this.config, {String? name, http.Client? client})
    : _customName = name ?? 'openai',
      _client = client ?? http.Client();

  Uri _resolveEndpoint() {
    final raw = (config.baseUrl != null && config.baseUrl!.trim().isNotEmpty)
        ? config.baseUrl!.trim().replaceAll(RegExp(r'/+$'), '')
        : 'https://api.openai.com/v1';

    if (raw.endsWith('/chat/completions')) {
      return Uri.parse(raw);
    }
    return Uri.parse('$raw/chat/completions');
  }

  @override
  Future<String> generateCommitMessage(CommitPromptContext context) async {
    final apiKey = config.apiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw AiException(
        provider: _customName,
        message:
            'API Key is missing. Configure it with `gitmsgai config set $_customName.api_key <KEY>` or pass `--api-key <KEY>`.',
      );
    }

    final endpoint = _resolveEndpoint();
    final model = config.model.trim().isNotEmpty
        ? config.model.trim()
        : 'gpt-4o-mini';

    final systemPrompt = PromptBuilder.buildSystemPrompt(context);
    final userPrompt = PromptBuilder.buildUserPrompt(context);

    final requestBody = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.2,
    };

    http.Response response;
    try {
      response = await _client.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );
    } catch (e) {
      throw AiException(
        provider: _customName,
        message: 'Network request failed to $endpoint: $e',
      );
    }

    if (response.statusCode != 200) {
      String errorMessage = response.body;
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        if (errorJson.containsKey('error')) {
          final err = errorJson['error'];
          if (err is Map) {
            errorMessage = err['message'] as String? ?? response.body;
          } else if (err is String) {
            errorMessage = err;
          }
        }
      } catch (_) {}

      throw AiException(
        provider: _customName,
        statusCode: response.statusCode,
        message: errorMessage,
      );
    }

    try {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw AiException(
          provider: _customName,
          message: 'Received empty choices from API response.',
        );
      }
      final firstChoice = choices.first as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;
      final rawText = message?['content'] as String? ?? '';
      return PromptBuilder.cleanResponse(rawText);
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException(
        provider: _customName,
        message: 'Failed to parse response: $e',
      );
    }
  }
}
