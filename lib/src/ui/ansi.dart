import 'dart:io';

/// Terminal ANSI styling helpers.
class Ansi {
  static bool get isSupported =>
      stdout.hasTerminal && stdout.supportsAnsiEscapes;

  static String _style(String text, String code) =>
      isSupported ? '\x1B[${code}m$text\x1B[0m' : text;

  static String bold(String text) => _style(text, '1');
  static String dim(String text) => _style(text, '2');
  static String italic(String text) => _style(text, '3');
  static String underline(String text) => _style(text, '4');

  static String red(String text) => _style(text, '31');
  static String green(String text) => _style(text, '32');
  static String yellow(String text) => _style(text, '33');
  static String blue(String text) => _style(text, '34');
  static String magenta(String text) => _style(text, '35');
  static String cyan(String text) => _style(text, '36');
  static String gray(String text) => _style(text, '90');

  static String success(String text) => '${green('✓')} $text';
  static String info(String text) => '${cyan('ℹ')} $text';
  static String warning(String text) => '${yellow('⚠')} $text';
  static String error(String text) => '${red('✖')} $text';
}
