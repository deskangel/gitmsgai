import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'openai_provider.dart';

/// DeepSeek AI Provider (powered by DeepSeek's OpenAI-compatible API).
class DeepSeekProvider extends OpenAiProvider {
  DeepSeekProvider(ProviderConfig config, {http.Client? client})
    : super(
        ProviderConfig(
          model: config.model.isNotEmpty ? config.model : 'deepseek-chat',
          apiKey: config.apiKey,
          baseUrl: (config.baseUrl != null && config.baseUrl!.isNotEmpty)
              ? config.baseUrl
              : 'https://api.deepseek.com',
        ),
        name: 'deepseek',
        client: client,
      );
}
