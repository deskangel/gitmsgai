/// Configuration for a specific AI provider.
class ProviderConfig {
  final String model;
  final String? apiKey;
  final String? baseUrl;

  const ProviderConfig({required this.model, this.apiKey, this.baseUrl});

  /// Returns masked API key for safe terminal display.
  String get maskedApiKey {
    if (apiKey == null || apiKey!.isEmpty) return '(not set)';
    if (apiKey!.length <= 8) return '****';
    return '${apiKey!.substring(0, 4)}...${apiKey!.substring(apiKey!.length - 4)}';
  }

  factory ProviderConfig.fromJson(
    Map<String, dynamic> json, {
    required ProviderConfig defaults,
  }) {
    return ProviderConfig(
      model: json['model'] as String? ?? defaults.model,
      apiKey: json['api_key'] as String? ?? defaults.apiKey,
      baseUrl: json['base_url'] as String? ?? defaults.baseUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      if (apiKey != null) 'api_key': apiKey,
      if (baseUrl != null) 'base_url': baseUrl,
    };
  }

  ProviderConfig copyWith({String? model, String? apiKey, String? baseUrl}) {
    return ProviderConfig(
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}

/// Global application configuration.
class AppConfig {
  final String defaultProvider;
  final String language; // 'en' or 'zh'
  final bool emoji;
  final bool detailed;
  final int maxDiffLines;
  final Map<String, ProviderConfig> providers;

  const AppConfig({
    this.defaultProvider = 'deepseek',
    this.language = 'zh',
    this.emoji = false,
    this.detailed = false,
    this.maxDiffLines = 800,
    required this.providers,
  });

  static ProviderConfig get defaultGemini => const ProviderConfig(
    model: 'gemini-2.5-flash',
    baseUrl: 'https://generativelanguage.googleapis.com',
  );

  static ProviderConfig get defaultOpenAi => const ProviderConfig(
    model: 'gpt-4o-mini',
    baseUrl: 'https://api.openai.com/v1',
  );

  static ProviderConfig get defaultDeepSeek => const ProviderConfig(
    model: 'deepseek-chat',
    baseUrl: 'https://api.deepseek.com',
  );

  factory AppConfig.defaults() {
    return AppConfig(
      defaultProvider: 'deepseek',
      language: 'zh',
      emoji: false,
      detailed: false,
      maxDiffLines: 800,
      providers: {
        'gemini': defaultGemini,
        'openai': defaultOpenAi,
        'deepseek': defaultDeepSeek,
      },
    );
  }

  ProviderConfig getProviderConfig(String name) {
    final lower = name.toLowerCase();
    if (providers.containsKey(lower)) {
      return providers[lower]!;
    }
    return switch (lower) {
      'gemini' => defaultGemini,
      'openai' => defaultOpenAi,
      'deepseek' => defaultDeepSeek,
      _ => const ProviderConfig(model: 'default'),
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final defaults = AppConfig.defaults();
    final providersJson = json['providers'] as Map<String, dynamic>? ?? {};

    return AppConfig(
      defaultProvider:
          json['default_provider'] as String? ?? defaults.defaultProvider,
      language: json['language'] as String? ?? defaults.language,
      emoji: json['emoji'] as bool? ?? defaults.emoji,
      detailed: json['detailed'] as bool? ?? defaults.detailed,
      maxDiffLines: json['max_diff_lines'] as int? ?? defaults.maxDiffLines,
      providers: {
        'gemini': ProviderConfig.fromJson(
          providersJson['gemini'] as Map<String, dynamic>? ?? {},
          defaults: defaults.providers['gemini']!,
        ),
        'openai': ProviderConfig.fromJson(
          providersJson['openai'] as Map<String, dynamic>? ?? {},
          defaults: defaults.providers['openai']!,
        ),
        'deepseek': ProviderConfig.fromJson(
          providersJson['deepseek'] as Map<String, dynamic>? ?? {},
          defaults: defaults.providers['deepseek']!,
        ),
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'default_provider': defaultProvider,
      'language': language,
      'emoji': emoji,
      'detailed': detailed,
      'max_diff_lines': maxDiffLines,
      'providers': providers.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  AppConfig copyWith({
    String? defaultProvider,
    String? language,
    bool? emoji,
    bool? detailed,
    int? maxDiffLines,
    Map<String, ProviderConfig>? providers,
  }) {
    return AppConfig(
      defaultProvider: defaultProvider ?? this.defaultProvider,
      language: language ?? this.language,
      emoji: emoji ?? this.emoji,
      detailed: detailed ?? this.detailed,
      maxDiffLines: maxDiffLines ?? this.maxDiffLines,
      providers: providers ?? this.providers,
    );
  }
}
