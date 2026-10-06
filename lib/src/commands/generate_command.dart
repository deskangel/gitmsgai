import 'dart:io';
import '../config/app_config.dart';
import '../git/git_service.dart';
import '../providers/ai_provider.dart';
import '../providers/provider_factory.dart';
import '../ui/ansi.dart';
import '../ui/terminal_ui.dart';

/// Handles git commit message generation and the commit workflow.
class GenerateCommand {
  final AppConfig config;
  final GitService gitService;
  final bool printOnly;
  final bool autoCommit;
  final String? initialHint;

  GenerateCommand({
    required this.config,
    GitService? gitService,
    this.printOnly = false,
    this.autoCommit = false,
    this.initialHint,
  }) : gitService = gitService ?? const GitService();

  Future<int> execute() async {
    // 1. Verify Git availability
    final isInstalled = await gitService.isGitInstalled();
    if (!isInstalled) {
      stderr.writeln(Ansi.error('Git is not installed or not in system PATH.'));
      return 1;
    }

    // 2. Verify inside Git repository
    final isRepo = await gitService.isInsideGitRepo();
    if (!isRepo) {
      stderr.writeln(Ansi.error('Current directory is not a Git repository.'));
      return 1;
    }

    // 3. Check staged files
    var stagedFiles = await gitService.getStagedFiles();
    if (stagedFiles.isEmpty) {
      final hasChanges = await gitService.hasWorkingTreeChanges();
      if (!hasChanges) {
        stdout.writeln(
          Ansi.warning(
            'No changes detected in repository (working tree clean).',
          ),
        );
        return 0;
      }

      stdout.writeln(Ansi.warning('No staged changes found.'));
      final shouldStageAll = TerminalUi.promptConfirm(
        prompt: 'Do you want to stage all files now? (git add -A)',
        defaultValue: true,
      );

      if (!shouldStageAll) {
        stdout.writeln(
          Ansi.dim(
            'Use "git add <files>" to stage files before running gitmsgai.',
          ),
        );
        return 0;
      }

      final addResult = await gitService.stageAll();
      if (addResult.exitCode != 0) {
        stderr.writeln(Ansi.error('Failed to stage files:'));
        stderr.writeln(addResult.stderr.toString());
        return addResult.exitCode;
      }

      stagedFiles = await gitService.getStagedFiles();
      if (stagedFiles.isEmpty) {
        stdout.writeln(Ansi.warning('No changes found to stage.'));
        return 0;
      }
    }

    // 4. Fetch diff
    final diff = await gitService.getPreparedDiff(
      maxLines: config.maxDiffLines,
    );
    if (diff.trim().isEmpty) {
      stdout.writeln(Ansi.warning('Staged changes contain no textual diff.'));
      return 0;
    }

    if (!printOnly) {
      TerminalUi.printStagedFiles(stagedFiles);
    }

    // 5. Instantiate Provider
    AiProvider provider;
    try {
      provider = ProviderFactory.create(config.defaultProvider, config);
    } catch (e) {
      stderr.writeln(Ansi.error(e.toString()));
      return 1;
    }

    // 6. Message Generation Loop
    String? currentHint = initialHint;
    String? commitMessage;

    while (true) {
      final promptContext = CommitPromptContext(
        diff: diff,
        stagedFiles: stagedFiles,
        language: config.language,
        emoji: config.emoji,
        detailed: config.detailed,
        hint: currentHint,
      );

      final providerName = provider.name;
      final modelName = provider.config.model;

      try {
        if (printOnly) {
          commitMessage = await provider.generateCommitMessage(promptContext);
        } else {
          commitMessage = await TerminalUi.withSpinner<String>(
            message: 'Generating with $providerName ($modelName)',
            task: () => provider.generateCommitMessage(promptContext),
          );
        }
      } on AiException catch (e) {
        stderr.writeln(Ansi.error(e.toString()));
        return 1;
      } catch (e) {
        stderr.writeln(Ansi.error('Unexpected error: $e'));
        return 1;
      }

      if (commitMessage.isEmpty) {
        stderr.writeln(Ansi.error('AI generated an empty commit message.'));
        return 1;
      }

      // 7. If print-only mode, output and exit immediately
      if (printOnly) {
        stdout.writeln(commitMessage);
        return 0;
      }

      // Display the generated message
      TerminalUi.printCommitMessage(commitMessage);

      // Auto commit if requested
      if (autoCommit) {
        return await _doCommit(commitMessage);
      }

      // 8. Interactive action prompt
      final action = TerminalUi.promptAction();
      switch (action) {
        case 'commit':
          return await _doCommit(commitMessage);
        case 'edit':
          final edited = TerminalUi.promptEditMessage(commitMessage);
          TerminalUi.printCommitMessage(edited);
          return await _doCommit(edited);
        case 'regenerate':
          currentHint = TerminalUi.promptRegenerateHint() ?? currentHint;
          print('');
          continue; // Loop again
        case 'cancel':
          stdout.writeln(Ansi.gray('Commit canceled.'));
          return 0;
      }
    }
  }

  Future<int> _doCommit(String message) async {
    final result = await gitService.commit(message);
    if (result.exitCode == 0) {
      stdout.writeln(Ansi.success('Committed successfully!'));
      if (result.stdout.toString().trim().isNotEmpty) {
        stdout.writeln(Ansi.dim(result.stdout.toString().trim()));
      }
      return 0;
    } else {
      stderr.writeln(Ansi.error('Git commit failed:'));
      stderr.writeln(result.stderr.toString());
      return result.exitCode;
    }
  }
}
