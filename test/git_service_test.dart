import 'package:gitmsgai/gitmsgai.dart';
import 'package:test/test.dart';

void main() {
  group('StagedFileInfo Tests', () {
    test('statusDisplay returns correct human-readable name', () {
      expect(
        const StagedFileInfo('A', 'new.dart').statusDisplay,
        equals('added'),
      );
      expect(
        const StagedFileInfo('M', 'lib.dart').statusDisplay,
        equals('modified'),
      );
      expect(
        const StagedFileInfo('D', 'old.dart').statusDisplay,
        equals('deleted'),
      );
      expect(
        const StagedFileInfo('R', 'renamed.dart').statusDisplay,
        equals('renamed'),
      );
      expect(
        const StagedFileInfo('U', 'conflict.dart').statusDisplay,
        equals('unmerged'),
      );
      expect(
        const StagedFileInfo('X', 'custom.dart').statusDisplay,
        equals('X'),
      );
    });
  });

  group('GitService Environment Tests', () {
    const gitService = GitService();

    test('isGitInstalled returns true on system with git', () async {
      final installed = await gitService.isGitInstalled();
      expect(installed, isTrue);
    });

    test('isInsideGitRepo returns true in current git workspace', () async {
      final isRepo = await gitService.isInsideGitRepo();
      expect(isRepo, isTrue);
    });

    test('hasWorkingTreeChanges returns a boolean in git workspace', () async {
      final hasChanges = await gitService.hasWorkingTreeChanges();
      expect(hasChanges, isA<bool>());
    });
  });
}
