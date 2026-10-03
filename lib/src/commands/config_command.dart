import 'dart:io';
import '../config/config_manager.dart';
import '../ui/ansi.dart';

/// Handles `config` subcommands.
class ConfigCommand {
  final List<String> args;

  const ConfigCommand(this.args);

  int execute() {
    if (args.isEmpty || args[0] == 'list') {
      return _listConfig();
    }

    final sub = args[0].toLowerCase();
    switch (sub) {
      case 'set':
        if (args.length < 3) {
          stderr.writeln(
            Ansi.error('Usage: gitmsgai config set <key> <value>'),
          );
          stderr.writeln(
            Ansi.dim('Example: gitmsgai config set deepseek.api_key sk-xxxx'),
          );
          return 1;
        }
        return _setConfig(args[1], args[2]);
      case 'path':
        return _showPath();
      default:
        stderr.writeln(
          Ansi.error('Unknown config action: $sub. Available: list, set, path'),
        );
        return 1;
    }
  }

  int _listConfig() {
    final config = ConfigManager.loadConfig();

    stdout.writeln(Ansi.bold('=== GitMsgAI Configuration ==='));
    stdout.writeln('Default Provider : ${Ansi.cyan(config.defaultProvider)}');
    stdout.writeln('Language         : ${Ansi.cyan(config.language)}');
    stdout.writeln('Emoji enabled    : ${Ansi.cyan(config.emoji.toString())}');
    stdout.writeln(
      'Detailed mode    : ${Ansi.cyan(config.detailed.toString())}',
    );
    stdout.writeln(
      'Max Diff Lines   : ${Ansi.cyan(config.maxDiffLines.toString())}',
    );
    stdout.writeln('');

    stdout.writeln(Ansi.bold('AI Providers:'));
    for (final entry in config.providers.entries) {
      final name = entry.key;
      final prov = entry.value;
      final isDefault = name == config.defaultProvider;
      final badge = isDefault ? Ansi.green(' (default)') : '';

      stdout.writeln('  ${Ansi.bold(name)}$badge');
      stdout.writeln('    Model   : ${prov.model}');
      stdout.writeln('    API Key : ${prov.maskedApiKey}');
      if (prov.baseUrl != null && prov.baseUrl!.isNotEmpty) {
        stdout.writeln('    Base URL: ${prov.baseUrl}');
      }
    }
    stdout.writeln('');
    stdout.writeln(
      Ansi.dim('Global config file: ${ConfigManager.globalConfigFile}'),
    );
    return 0;
  }

  int _setConfig(String key, String value) {
    try {
      final current = ConfigManager.loadConfig();
      final updated = ConfigManager.updateSetting(current, key, value);
      ConfigManager.saveGlobalConfig(updated);
      stdout.writeln(Ansi.success('Configuration updated: $key = $value'));
      return 0;
    } catch (e) {
      stderr.writeln(Ansi.error('Failed to set config: $e'));
      return 1;
    }
  }

  int _showPath() {
    stdout.writeln('Global Config: ${ConfigManager.globalConfigFile}');
    stdout.writeln('Local Config : ${ConfigManager.localConfigFile}');
    return 0;
  }
}
