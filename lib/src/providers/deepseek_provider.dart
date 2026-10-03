import '../config/app_config.dart';
import 'openai_provider.dart';

/// DeepSeek AI Provider (powered by DeepSeek's OpenAI-compatible API).
class DeepSeekProvider extends OpenAiProvider {
  DeepSeekProvider(ProviderConfig config, {super.client})
    : super(
        ProviderConfig(
          model: config.model.isNotEmpty ? config.model : 'deepseek-chat',
          apiKey: config.apiKey,
          baseUrl: (config.baseUrl != null && config.baseUrl!.isNotEmpty)
              ? config.baseUrl
              : 'https://api.deepseek.com',
        ),
        name: 'deepseek',
      );
}
