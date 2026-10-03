import 'package:gitmsgai/gitmsgai.dart';
import 'package:test/test.dart';

void main() {
  group('AppConfig & ProviderConfig Tests', () {
    test('default configuration contains deepseek, gemini, and openai', () {
      final config = AppConfig.defaults();
      expect(config.defaultProvider, equals('deepseek'));
      expect(config.language, equals('zh'));
      expect(config.emoji, isFalse);
      expect(config.detailed, isFalse);

      expect(config.providers.containsKey('deepseek'), isTrue);
      expect(config.providers.containsKey('gemini'), isTrue);
      expect(config.providers.containsKey('openai'), isTrue);

      final deepseek = config.getProviderConfig('deepseek');
      expect(deepseek.model, equals('deepseek-chat'));
      expect(deepseek.baseUrl, equals('https://api.deepseek.com'));

      final gemini = config.getProviderConfig('gemini');
      expect(gemini.model, equals('gemini-2.5-flash'));

      final openai = config.getProviderConfig('openai');
      expect(openai.model, equals('gpt-4o-mini'));
      expect(openai.baseUrl, equals('https://api.openai.com/v1'));
    });

    test('maskedApiKey masks API keys safely', () {
      const empty = ProviderConfig(model: 'm');
      expect(empty.maskedApiKey, equals('(not set)'));

      const shortKey = ProviderConfig(model: 'm', apiKey: '123456');
      expect(shortKey.maskedApiKey, equals('****'));

      const standardKey = ProviderConfig(
        model: 'm',
        apiKey: 'sk-abcdef1234567890',
      );
      expect(standardKey.maskedApiKey, equals('sk-a...7890'));
    });

    test('AppConfig json serialization and deserialization roundtrip', () {
      final original = AppConfig.defaults().copyWith(
        defaultProvider: 'gemini',
        language: 'en',
        emoji: true,
        detailed: true,
        maxDiffLines: 1200,
        providers: {
          'gemini': const ProviderConfig(
            model: 'gemini-2.5-pro',
            apiKey: 'test-gemini-key',
            baseUrl: 'https://custom.gemini.endpoint',
          ),
          'openai': AppConfig.defaultOpenAi,
          'deepseek': AppConfig.defaultDeepSeek,
        },
      );

      final json = original.toJson();
      final restored = AppConfig.fromJson(json);

      expect(restored.defaultProvider, equals('gemini'));
      expect(restored.language, equals('en'));
      expect(restored.emoji, isTrue);
      expect(restored.detailed, isTrue);
      expect(restored.maxDiffLines, equals(1200));

      final restoredGemini = restored.getProviderConfig('gemini');
      expect(restoredGemini.model, equals('gemini-2.5-pro'));
      expect(restoredGemini.apiKey, equals('test-gemini-key'));
      expect(restoredGemini.baseUrl, equals('https://custom.gemini.endpoint'));
    });

    test('ConfigManager.updateSetting updates keys correctly', () {
      var config = AppConfig.defaults();

      // Top level
      config = ConfigManager.updateSetting(
        config,
        'default_provider',
        'openai',
      );
      expect(config.defaultProvider, equals('openai'));

      config = ConfigManager.updateSetting(config, 'language', 'en');
      expect(config.language, equals('en'));

      config = ConfigManager.updateSetting(config, 'emoji', 'true');
      expect(config.emoji, isTrue);

      config = ConfigManager.updateSetting(config, 'max_diff_lines', '500');
      expect(config.maxDiffLines, equals(500));

      // Provider sub-keys
      config = ConfigManager.updateSetting(
        config,
        'deepseek.api_key',
        'sk-my-deepseek-key',
      );
      expect(
        config.getProviderConfig('deepseek').apiKey,
        equals('sk-my-deepseek-key'),
      );

      config = ConfigManager.updateSetting(config, 'openai.model', 'gpt-4o');
      expect(config.getProviderConfig('openai').model, equals('gpt-4o'));

      config = ConfigManager.updateSetting(
        config,
        'gemini.base_url',
        'https://proxy.example.com',
      );
      expect(
        config.getProviderConfig('gemini').baseUrl,
        equals('https://proxy.example.com'),
      );
    });
  });
}
