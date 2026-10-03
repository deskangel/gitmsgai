import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'app_config.dart';

/// Manages loading, merging, and saving configurations.
class ConfigManager {
  static String get userHomeDir {
    final env = Platform.environment;
    if (Platform.isWindows) {
      return env['UserProfile'] ?? env['HomeDrive'] ?? '';
    }
    return env['HOME'] ?? '';
  }

  static String get globalConfigDir {
    return p.join(userHomeDir, '.config', 'gitmsgai');
  }

  static String get globalConfigFile {
    return p.join(globalConfigDir, 'config.json');
  }

  static String get localConfigFile {
    return p.join(Directory.current.path, '.gitmsgai.json');
  }

  /// Loads merged config with hierarchy:
  /// CLI flags > Environment variables > Project config > Global config > Defaults.
  static AppConfig loadConfig({
    String? cliProvider,
    String? cliModel,
    String? cliApiKey,
    String? cliBaseUrl,
    String? cliLanguage,
    bool? cliEmoji,
    bool? cliDetailed,
  }) {
    AppConfig config = AppConfig.defaults();

    // 1. Read global config if exists
    final globalFile = File(globalConfigFile);
    if (globalFile.existsSync()) {
      try {
        final content = globalFile.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        config = AppConfig.fromJson(json);
      } catch (_) {
        // Fallback to defaults on parse error
      }
    }

    // 2. Read local project config if exists
    final localFile = File(localConfigFile);
    if (localFile.existsSync()) {
      try {
        final content = localFile.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        config = AppConfig.fromJson(json);
      } catch (_) {
        // Fallback
      }
    }

    final providers = Map<String, ProviderConfig>.from(config.providers);

    // 4. CLI flags (Highest priority)
    final selectedProvider = (cliProvider ?? config.defaultProvider)
        .toLowerCase();

    if (cliModel != null || cliApiKey != null || cliBaseUrl != null) {
      final current = config.getProviderConfig(selectedProvider);
      providers[selectedProvider] = current.copyWith(
        model: cliModel ?? current.model,
        apiKey: cliApiKey ?? current.apiKey,
        baseUrl: cliBaseUrl ?? current.baseUrl,
      );
    }

    config = config.copyWith(
      defaultProvider: selectedProvider,
      language: cliLanguage ?? config.language,
      emoji: cliEmoji ?? config.emoji,
      detailed: cliDetailed ?? config.detailed,
      providers: providers,
    );

    return config;
  }

  /// Saves config to global configuration file.
  static void saveGlobalConfig(AppConfig config) {
    final dir = Directory(globalConfigDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File(globalConfigFile);
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(config.toJson()));
  }

  /// Sets a specific key by dotted path, e.g. "default_provider", "deepseek.api_key", "openai.model".
  static AppConfig updateSetting(
    AppConfig current,
    String keyPath,
    String value,
  ) {
    final parts = keyPath.split('.');
    if (parts.length == 1) {
      final key = parts[0].toLowerCase();
      switch (key) {
        case 'default_provider':
        case 'provider':
          return current.copyWith(defaultProvider: value.toLowerCase());
        case 'language':
        case 'lang':
          return current.copyWith(language: value.toLowerCase());
        case 'emoji':
          return current.copyWith(emoji: value.toLowerCase() == 'true');
        case 'detailed':
          return current.copyWith(detailed: value.toLowerCase() == 'true');
        case 'max_diff_lines':
          final n = int.tryParse(value);
          if (n != null) return current.copyWith(maxDiffLines: n);
          break;
        default:
          throw ArgumentError('Unknown configuration key: $keyPath');
      }
    } else if (parts.length == 2) {
      final provider = parts[0].toLowerCase();
      final subKey = parts[1].toLowerCase();
      final currentProvider = current.getProviderConfig(provider);
      final providers = Map<String, ProviderConfig>.from(current.providers);

      ProviderConfig updated;
      switch (subKey) {
        case 'api_key':
        case 'key':
          updated = currentProvider.copyWith(apiKey: value);
          break;
        case 'model':
          updated = currentProvider.copyWith(model: value);
          break;
        case 'base_url':
        case 'url':
          updated = currentProvider.copyWith(baseUrl: value);
          break;
        default:
          throw ArgumentError(
            'Unknown provider configuration sub-key: $subKey in $keyPath',
          );
      }
      providers[provider] = updated;
      return current.copyWith(providers: providers);
    } else {
      throw ArgumentError('Invalid configuration path format: $keyPath');
    }
    return current;
  }
}
