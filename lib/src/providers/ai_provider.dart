import '../config/app_config.dart';
import '../git/git_service.dart';

/// Context provided to the AI model to generate a commit message.
class CommitPromptContext {
  final String diff;
  final List<StagedFileInfo> stagedFiles;
  final String language; // 'en' or 'zh'
  final bool emoji;
  final bool detailed;
  final String? hint;

  const CommitPromptContext({
    required this.diff,
    required this.stagedFiles,
    this.language = 'zh',
    this.emoji = false,
    this.detailed = false,
    this.hint,
  });
}

/// Generic exception thrown by AI providers.
class AiException implements Exception {
  final String provider;
  final String message;
  final int? statusCode;

  const AiException({
    required this.provider,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() {
    final code = statusCode != null ? ' (Status: $statusCode)' : '';
    return '[$provider Error$code] $message';
  }
}

/// Abstract AI Provider interface.
abstract class AiProvider {
  String get name;
  ProviderConfig get config;

  /// Generates a commit message using the AI model.
  Future<String> generateCommitMessage(CommitPromptContext context);
}
