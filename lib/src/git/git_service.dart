import 'dart:io';

/// Information about a staged file.
class StagedFileInfo {
  final String status; // 'M', 'A', 'D', 'R', etc.
  final String path;

  const StagedFileInfo(this.status, this.path);

  String get statusDisplay {
    return switch (status) {
      'A' => 'added',
      'M' => 'modified',
      'D' => 'deleted',
      'R' => 'renamed',
      'C' => 'copied',
      'U' => 'unmerged',
      _ => status,
    };
  }
}

/// Service to interact with the local Git command line.
class GitService {
  final String? workingDirectory;

  const GitService({this.workingDirectory});

  Future<ProcessResult> _run(List<String> args) async {
    return Process.run(
      'git',
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
  }

  /// Checks if git command is installed and accessible.
  Future<bool> isGitInstalled() async {
    try {
      final res = await _run(['--version']);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Checks if current directory is inside a Git repository.
  Future<bool> isInsideGitRepo() async {
    final res = await _run(['rev-parse', '--is-inside-work-tree']);
    return res.exitCode == 0 && res.stdout.toString().trim() == 'true';
  }

  /// Returns list of staged files with their status.
  Future<List<StagedFileInfo>> getStagedFiles() async {
    final res = await _run(['diff', '--cached', '--name-status']);
    if (res.exitCode != 0) return [];
    final output = res.stdout.toString().trim();
    if (output.isEmpty) return [];

    final lines = output.split('\n');
    final files = <StagedFileInfo>[];
    for (final line in lines) {
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        files.add(StagedFileInfo(parts[0], parts.sublist(1).join(' ')));
      }
    }
    return files;
  }

  /// Returns git diff summary (`git diff --cached --stat`).
  Future<String> getStagedStat() async {
    final res = await _run(['diff', '--cached', '--stat']);
    if (res.exitCode != 0) return '';
    return res.stdout.toString().trim();
  }

  /// Returns raw cached diff.
  Future<String> getRawStagedDiff() async {
    final res = await _run(['diff', '--cached', '--no-color', '--no-ext-diff']);
    if (res.exitCode != 0) return '';
    return res.stdout.toString().trim();
  }

  /// Returns prepared diff for AI, with smart truncation if diff is too large.
  Future<String> getPreparedDiff({int maxLines = 800}) async {
    final rawDiff = await getRawStagedDiff();
    if (rawDiff.isEmpty) return '';

    final lines = rawDiff.split('\n');
    if (lines.length <= maxLines) {
      return rawDiff;
    }

    final stat = await getStagedStat();
    final truncatedDiff = lines.take(maxLines).join('\n');
    final buffer = StringBuffer();
    if (stat.isNotEmpty) {
      buffer.writeln('# Staged Changes Summary:');
      buffer.writeln(stat);
      buffer.writeln();
    }
    buffer.writeln('# Staged Diff (Truncated to first $maxLines lines):');
    buffer.writeln(truncatedDiff);
    buffer.writeln(
      '\n[Diff truncated: total ${lines.length} lines, showing first $maxLines lines]',
    );
    return buffer.toString();
  }

  /// Executes git commit with given message.
  Future<ProcessResult> commit(String message, {bool amend = false}) async {
    final args = ['commit', '-m', message];
    if (amend) {
      args.add('--amend');
    }
    return _run(args);
  }
}
