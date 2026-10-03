import 'dart:async';
import 'dart:io';
import '../git/git_service.dart';
import 'ansi.dart';

/// Interactive UI helpers for terminal.
class TerminalUi {
  /// Displays the list of staged files with color highlights.
  static void printStagedFiles(List<StagedFileInfo> files) {
    print(Ansi.bold('Staged files (${files.length}):'));
    for (final file in files) {
      final statusBadge = switch (file.status) {
        'A' => Ansi.green('[A]'),
        'M' => Ansi.yellow('[M]'),
        'D' => Ansi.red('[D]'),
        'R' => Ansi.cyan('[R]'),
        _ => Ansi.gray('[${file.status}]'),
      };
      print('  $statusBadge ${file.path}');
    }
    print('');
  }

  /// Displays the generated commit message inside a clean border.
  static void printCommitMessage(String message) {
    const width = 60;
    final border = '─' * width;
    print(Ansi.cyan('┌$border┐'));
    print(
      Ansi.cyan('│') +
          Ansi.bold(' Proposed Commit Message:'.padRight(width)) +
          Ansi.cyan('│'),
    );
    print(Ansi.cyan('├$border┤'));
    for (final line in message.split('\n')) {
      print('${Ansi.cyan('│')} ${Ansi.green(line)}');
    }
    print(Ansi.cyan('└$border┘'));
    print('');
  }

  /// Runs an async task while showing an animated terminal spinner.
  static Future<T> withSpinner<T>({
    required String message,
    required Future<T> Function() task,
  }) async {
    if (!stdout.hasTerminal) {
      stdout.writeln('$message...');
      return await task();
    }

    const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    int frameIndex = 0;
    Timer? timer;

    stdout.write('\x1B[?25l'); // Hide cursor
    timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final frame = Ansi.cyan(frames[frameIndex % frames.length]);
      stdout.write('\r$frame $message');
      frameIndex++;
    });

    try {
      final result = await task();
      timer.cancel();
      stdout.write('\r\x1B[2K'); // Clear line
      stdout.writeln(Ansi.success(message));
      return result;
    } catch (e) {
      timer.cancel();
      stdout.write('\r\x1B[2K');
      stdout.writeln(Ansi.error('$message failed'));
      rethrow;
    } finally {
      stdout.write('\x1B[?25h'); // Restore cursor
    }
  }

  /// Prompts the user with interactive options.
  /// Returns one of: 'commit', 'edit', 'regenerate', 'print', 'cancel'.
  static String promptAction() {
    if (!stdin.hasTerminal) {
      return 'commit';
    }

    while (true) {
      stdout.write(
        'Action: [${Ansi.bold('y')}]es, commit | [${Ansi.bold('e')}]dit | [${Ansi.bold('r')}]egenerate | [${Ansi.bold('n')}]o, cancel\n'
        'Choice [y/e/r/n] (default: y): ',
      );
      final input = stdin.readLineSync()?.trim().toLowerCase();

      if (input == null || input.isEmpty || input == 'y' || input == 'yes') {
        return 'commit';
      }
      if (input == 'e' || input == 'edit') {
        return 'edit';
      }
      if (input == 'r' || input == 'retry' || input == 'regenerate') {
        return 'regenerate';
      }
      if (input == 'n' || input == 'no' || input == 'q' || input == 'cancel') {
        return 'cancel';
      }

      print(Ansi.yellow('Invalid option. Please enter y, e, r, or n.\n'));
    }
  }

  /// Prompts user to edit the message interactively.
  static String promptEditMessage(String current) {
    print(Ansi.dim('Current message: $current'));
    stdout.write('Enter new commit message (leave empty to keep current): ');
    final input = stdin.readLineSync()?.trim();
    if (input != null && input.isNotEmpty) {
      return input;
    }
    return current;
  }

  /// Prompts for optional regeneration hint.
  static String? promptRegenerateHint() {
    stdout.write(
      'Optional hint for regeneration (e.g. "make it more concise", leave empty to skip): ',
    );
    final input = stdin.readLineSync()?.trim();
    if (input != null && input.isNotEmpty) {
      return input;
    }
    return null;
  }
}
