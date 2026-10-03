import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../prompt/prompt_builder.dart';
import 'ai_provider.dart';

/// Gemini AI Provider utilizing the Google Generative Language REST API.
class GeminiProvider implements AiProvider {
  @override
  final String name = 'gemini';

  @override
  final ProviderConfig config;

  final http.Client _client;

  GeminiProvider(this.config, {http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<String> generateCommitMessage(CommitPromptContext context) async {
    final apiKey = config.apiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const AiException(
        provider: 'Gemini',
        message:
            'API Key is missing. Configure it with `gitmsgai config set gemini.api_key <KEY>` or pass `--api-key <KEY>`.',
      );
    }

    final rawBaseUrl =
        (config.baseUrl != null && config.baseUrl!.trim().isNotEmpty)
        ? config.baseUrl!.trim().replaceAll(RegExp(r'/+$'), '')
        : 'https://generativelanguage.googleapis.com';

    final model = config.model.trim().isNotEmpty
        ? config.model.trim()
        : 'gemini-2.5-flash';
    final url = Uri.parse(
      '$rawBaseUrl/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final systemPrompt = PromptBuilder.buildSystemPrompt(context);
    final userPrompt = PromptBuilder.buildUserPrompt(context);

    final requestBody = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.2},
    };

    http.Response response;
    try {
      response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
    } catch (e) {
      throw AiException(
        provider: 'Gemini',
        message: 'Network request failed: $e',
      );
    }

    if (response.statusCode != 200) {
      String errorMessage = response.body;
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        if (errorJson.containsKey('error') && errorJson['error'] is Map) {
          errorMessage =
              errorJson['error']['message'] as String? ?? response.body;
        }
      } catch (_) {}

      throw AiException(
        provider: 'Gemini',
        statusCode: response.statusCode,
        message: errorMessage,
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const AiException(
          provider: 'Gemini',
          message: 'Received empty candidates from Gemini API.',
        );
      }
      final candidate = candidates.first as Map<String, dynamic>;
      final content = candidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw const AiException(
          provider: 'Gemini',
          message: 'Received empty content parts from Gemini API.',
        );
      }
      final rawText = parts.first['text'] as String? ?? '';
      return PromptBuilder.cleanResponse(rawText);
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException(
        provider: 'Gemini',
        message: 'Failed to parse Gemini response: $e',
      );
    }
  }
}
