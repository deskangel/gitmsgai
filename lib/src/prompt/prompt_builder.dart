import '../providers/ai_provider.dart';

/// Constructs prompts for AI commit message generation and cleans model outputs.
class PromptBuilder {
  /// Builds the system prompt guiding the AI to adhere to Conventional Commits.
  static String buildSystemPrompt(CommitPromptContext context) {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are an expert developer assistant specialized in writing clear, standard Git commit messages following the Conventional Commits specification (v1.0.0).',
    );
    buffer.writeln();
    buffer.writeln('FORMAT GUIDELINES:');
    buffer.writeln('1. Structure: <type>(<optional-scope>): <subject>');
    buffer.writeln(
      '2. Common types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.',
    );
    buffer.writeln(
      '3. Scope: Optional lowercase identifier for the modified module (e.g. auth, api, cli, ui).',
    );
    buffer.writeln(
      '4. Subject: Concise summary in imperative mood, present tense, no period at the end.',
    );

    if (context.emoji) {
      buffer.writeln(
        '5. EMOJI: Prefix the type with standard Gitmoji (e.g., ✨ feat:, 🐛 fix:, 📝 docs:, ♻️ refactor:, ⚡️ perf:, 🧪 test:, 🔧 chore:).',
      );
    } else {
      buffer.writeln('5. EMOJI: Do NOT use emojis.');
    }

    if (context.language.toLowerCase().startsWith('zh')) {
      buffer.writeln(
        '6. LANGUAGE: Write the commit subject (and body) in Simplified Chinese (简体中文). The type and scope remain in English. Example: feat(auth): 新增用户登录校验逻辑',
      );
    } else {
      buffer.writeln(
        '6. LANGUAGE: Write the commit subject (and body) in English. Example: feat(auth): add user login validation logic',
      );
    }

    if (context.detailed) {
      buffer.writeln(
        '7. DETAIL LEVEL: Provide a header line, followed by an empty line, followed by concise bullet points (- item) explaining key changes.',
      );
    } else {
      buffer.writeln(
        '7. DETAIL LEVEL: Provide ONLY the single concise header line. Do NOT output a body or multiple lines.',
      );
    }

    buffer.writeln();
    buffer.writeln('CRITICAL INSTRUCTIONS:');
    buffer.writeln('- Output ONLY the raw commit message.');
    buffer.writeln(
      '- DO NOT wrap your output in markdown code blocks (such as ``` or ```text).',
    );
    buffer.writeln(
      '- DO NOT include conversational phrases like "Here is the commit message:".',
    );
    buffer.writeln('- DO NOT add introductory or concluding text.');

    return buffer.toString();
  }

  /// Builds the user prompt containing staged files, user hint, and diff.
  static String buildUserPrompt(CommitPromptContext context) {
    final buffer = StringBuffer();

    if (context.hint != null && context.hint!.trim().isNotEmpty) {
      buffer.writeln('Developer Context / Hint:');
      buffer.writeln(context.hint!.trim());
      buffer.writeln();
    }

    if (context.stagedFiles.isNotEmpty) {
      buffer.writeln('Staged Files:');
      for (final file in context.stagedFiles) {
        buffer.writeln('  [${file.status}] ${file.path}');
      }
      buffer.writeln();
    }

    buffer.writeln('Git Staged Diff:');
    buffer.writeln('```diff');
    buffer.writeln(context.diff);
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('Generate the commit message:');

    return buffer.toString();
  }

  /// Cleans response from AI, stripping accidental markdown code blocks and excess whitespace.
  static String cleanResponse(String raw) {
    var text = raw.trim();

    // Strip leading code fence ```text or ```gitcommit or ```
    final fenceStart = RegExp(r'^```[a-zA-Z0-9_-]*\s*\n?');
    if (fenceStart.hasMatch(text)) {
      text = text.replaceFirst(fenceStart, '');
    }

    // Strip trailing code fence ```
    final fenceEnd = RegExp(r'\n?```\s*$');
    if (fenceEnd.hasMatch(text)) {
      text = text.replaceFirst(fenceEnd, '');
    }

    // Strip surrounding quotes if wrapped
    if ((text.startsWith('"') && text.endsWith('"')) ||
        (text.startsWith("'") && text.endsWith("'"))) {
      text = text.substring(1, text.length - 1);
    }

    return text.trim();
  }
}
