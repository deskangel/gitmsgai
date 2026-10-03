import 'package:gitmsgai/gitmsgai.dart';
import 'package:test/test.dart';

void main() {
  group('PromptBuilder Tests', () {
    test('buildSystemPrompt includes conventional commits and rules', () {
      const context = CommitPromptContext(
        diff: 'diff --git a/file.txt b/file.txt',
        stagedFiles: [StagedFileInfo('M', 'file.txt')],
        language: 'zh',
        emoji: false,
        detailed: false,
      );

      final prompt = PromptBuilder.buildSystemPrompt(context);
      expect(prompt, contains('Conventional Commits'));
      expect(prompt, contains('Simplified Chinese'));
      expect(prompt, contains('Do NOT use emojis'));
      expect(prompt, contains('ONLY the single concise header line'));
      expect(
        prompt,
        contains('DO NOT wrap your output in markdown code blocks'),
      );
    });

    test('buildSystemPrompt adapts to english, emoji, and detailed mode', () {
      const context = CommitPromptContext(
        diff: 'diff --git a/app.dart b/app.dart',
        stagedFiles: [StagedFileInfo('A', 'app.dart')],
        language: 'en',
        emoji: true,
        detailed: true,
      );

      final prompt = PromptBuilder.buildSystemPrompt(context);
      expect(
        prompt,
        contains('Write the commit subject (and body) in English'),
      );
      expect(prompt, contains('Prefix the type with standard Gitmoji'));
      expect(
        prompt,
        contains(
          'DETAIL LEVEL: Provide a header line, followed by an empty line',
        ),
      );
    });

    test('buildUserPrompt includes hint, staged files, and diff', () {
      const context = CommitPromptContext(
        diff: '+ const apiKey = "123";',
        stagedFiles: [
          StagedFileInfo('M', 'lib/config.dart'),
          StagedFileInfo('A', 'test/config_test.dart'),
        ],
        hint: 'fixes issue with api key validation',
      );

      final prompt = PromptBuilder.buildUserPrompt(context);
      expect(prompt, contains('Developer Context / Hint:'));
      expect(prompt, contains('fixes issue with api key validation'));
      expect(prompt, contains('Staged Files:'));
      expect(prompt, contains('[M] lib/config.dart'));
      expect(prompt, contains('[A] test/config_test.dart'));
      expect(prompt, contains('+ const apiKey = "123";'));
    });

    test('cleanResponse cleans various AI markdown block wraps', () {
      // Standard markdown block
      expect(
        PromptBuilder.cleanResponse('```\nfeat: add login feature\n```'),
        equals('feat: add login feature'),
      );

      // Markdown block with language tag
      expect(
        PromptBuilder.cleanResponse(
          '```gitcommit\nfix(auth): resolve token refresh\n```',
        ),
        equals('fix(auth): resolve token refresh'),
      );

      // Surrounding double quotes
      expect(
        PromptBuilder.cleanResponse('"feat(ui): update dark mode theme"'),
        equals('feat(ui): update dark mode theme'),
      );

      // Already clean text
      expect(
        PromptBuilder.cleanResponse('refactor: streamline provider factory'),
        equals('refactor: streamline provider factory'),
      );
    });
  });
}
