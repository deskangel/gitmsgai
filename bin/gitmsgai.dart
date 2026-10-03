import 'dart:io';
import 'package:args/args.dart';
import 'package:gitmsgai/gitmsgai.dart';

const String version = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.0.0',
);

ArgParser buildParser() {
  final parser = ArgParser();

  parser.addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Display this help information.',
  );
  parser.addFlag(
    'version',
    abbr: 'v',
    negatable: false,
    help: 'Display the tool version.',
  );
  parser.addOption(
    'provider',
    abbr: 'p',
    help: 'AI provider to use (deepseek, gemini, openai).',
    allowed: ['deepseek', 'gemini', 'openai'],
  );
  parser.addOption(
    'model',
    abbr: 'm',
    help:
        'Override model name (e.g. deepseek-chat, gemini-2.5-flash, gpt-4o-mini).',
  );
  parser.addOption(
    'api-key',
    abbr: 'k',
    help: 'AI provider API Key (defaults to config file).',
  );
  parser.addOption('base-url', abbr: 'u', help: 'Custom API base URL.');
  parser.addOption(
    'lang',
    abbr: 'l',
    help: 'Commit message language.',
    allowed: ['zh', 'en'],
  );
  parser.addFlag(
    'emoji',
    abbr: 'e',
    negatable: true,
    defaultsTo: null,
    help: 'Include Gitmoji in the commit message (e.g., ✨ feat:).',
  );
  parser.addFlag(
    'detailed',
    abbr: 'd',
    negatable: true,
    defaultsTo: null,
    help: 'Generate detailed commit message with bulleted description.',
  );
  parser.addFlag(
    'auto-commit',
    abbr: 'c',
    negatable: false,
    help: 'Automatically execute git commit without interactive prompt.',
  );
  parser.addFlag(
    'raw',
    abbr: 'r',
    negatable: false,
    help: 'Print only the commit message to stdout (ideal for shell scripts).',
  );
  parser.addOption(
    'hint',
    help:
        'Additional context or instruction for the AI (e.g. --hint "fixes #42").',
  );

  // Subcommand: config
  final configCommand = parser.addCommand('config');
  configCommand.addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Display config help.',
  );

  return parser;
}

void printUsage(ArgParser parser) {
  stdout.writeln(
    '${Ansi.bold('GitMsgAI')} - AI-powered Git commit message generator',
  );
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  gitmsgai [options]');
  stdout.writeln('  gitmsgai config <list|set|path>');
  stdout.writeln('');
  stdout.writeln('Supported AI Providers:');
  stdout.writeln('  - deepseek (default, model: deepseek-chat)');
  stdout.writeln('  - gemini   (Google Gemini, model: gemini-2.5-flash)');
  stdout.writeln(
    '  - openai   (OpenAI or any compatible API, model: gpt-4o-mini)',
  );
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(parser.usage);
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln('  # Generate and review commit message for staged files:');
  stdout.writeln('  git add . && gitmsgai');
  stdout.writeln('');
  stdout.writeln('  # Use Gemini with Chinese output and Gitmoji:');
  stdout.writeln('  gitmsgai -p gemini -l zh -e');
  stdout.writeln('');
  stdout.writeln('  # Auto commit using DeepSeek:');
  stdout.writeln('  gitmsgai -p deepseek -c');
  stdout.writeln('');
  stdout.writeln('  # Configure default API key:');
  stdout.writeln('  gitmsgai config set deepseek.api_key sk-xxxx');
  stdout.writeln('  gitmsgai config set default_provider deepseek');
}

void main(List<String> arguments) async {
  final parser = buildParser();

  try {
    final results = parser.parse(arguments);

    if (results.flag('help')) {
      printUsage(parser);
      exit(0);
    }

    if (results.flag('version')) {
      stdout.writeln('gitmsgai version: $version');
      exit(0);
    }

    // Handle subcommands
    final command = results.command;
    if (command != null && command.name == 'config') {
      if (command.flag('help')) {
        stdout.writeln('Usage: gitmsgai config <list|set|path>');
        stdout.writeln('');
        stdout.writeln('Commands:');
        stdout.writeln(
          '  list                Show active configuration and masked keys',
        );
        stdout.writeln(
          '  set <key> <val>     Update a setting, e.g. deepseek.api_key sk-xxx',
        );
        stdout.writeln('  path                Show config file path');
        exit(0);
      }
      final exitCode = ConfigCommand(command.rest).execute();
      exit(exitCode);
    }

    // Load merged configuration
    final config = ConfigManager.loadConfig(
      cliProvider: results.option('provider'),
      cliModel: results.option('model'),
      cliApiKey: results.option('api-key'),
      cliBaseUrl: results.option('base-url'),
      cliLanguage: results.option('lang'),
      cliEmoji: results.wasParsed('emoji') ? results.flag('emoji') : null,
      cliDetailed: results.wasParsed('detailed')
          ? results.flag('detailed')
          : null,
    );

    final generateCommand = GenerateCommand(
      config: config,
      printOnly: results.flag('raw'),
      autoCommit: results.flag('auto-commit'),
      initialHint: results.option('hint'),
    );

    final exitCode = await generateCommand.execute();
    exit(exitCode);
  } on FormatException catch (e) {
    stderr.writeln(Ansi.error(e.message));
    stdout.writeln('');
    printUsage(parser);
    exit(64); // ExitCode.usage
  } catch (e) {
    stderr.writeln(Ansi.error('Fatal error: $e'));
    exit(1);
  }
}
