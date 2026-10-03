import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'ai_provider.dart';
import 'deepseek_provider.dart';
import 'gemini_provider.dart';
import 'openai_provider.dart';

/// Factory to instantiate AI providers.
class ProviderFactory {
  static const List<String> supportedProviders = [
    'deepseek',
    'gemini',
    'openai',
  ];

  static AiProvider create(
    String providerName,
    AppConfig config, {
    http.Client? client,
  }) {
    final lower = providerName.trim().toLowerCase();
    final providerConfig = config.getProviderConfig(lower);

    switch (lower) {
      case 'deepseek':
        return DeepSeekProvider(providerConfig, client: client);
      case 'gemini':
        return GeminiProvider(providerConfig, client: client);
      case 'openai':
        return OpenAiProvider(providerConfig, client: client);
      default:
        throw ArgumentError(
          'Unsupported AI provider: "$providerName". Supported providers are: ${supportedProviders.join(', ')}',
        );
    }
  }
}
