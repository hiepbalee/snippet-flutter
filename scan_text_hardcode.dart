import 'dart:io';

void main() async {
  // Using separate regexes for single quotes and double quotes to avoid escaping issues
  final singleQuoteRegex = RegExp(r"Text\s*\(\s*'([^']*)'");
  final doubleQuoteRegex = RegExp(r'Text\s*\(\s*"([^"]*)"');

  final dir = Directory('lib');

  print('🔍 Scanning Flutter files for Text widgets...\n');

  // Get all Dart files in the lib directory and subdirectories
  final files = await dir
      .list(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  print('📁 Found ${files.length} Dart files to analyze\n');

  int totalMatches = 0;

  for (final file in files) {
    try {
      final content = await file.readAsString();

      // Match both types of quotes
      final singleQuoteMatches = singleQuoteRegex.allMatches(content);
      final doubleQuoteMatches = doubleQuoteRegex.allMatches(content);

      final hasMatches = singleQuoteMatches.isNotEmpty || doubleQuoteMatches.isNotEmpty;

      if (hasMatches) {
        print('📄 ${file.path}:');

        // Process single quote matches
        for (final match in singleQuoteMatches) {
          final textContent = match.group(1);
          if (textContent != null) {
            print("  • '$textContent'");
            totalMatches++;
          }
        }

        // Process double quote matches
        for (final match in doubleQuoteMatches) {
          final textContent = match.group(1);
          if (textContent != null) {
            print('  • "$textContent"');
            totalMatches++;
          }
        }

        print(''); // Empty line for better readability
      }
    } catch (e) {
      print('❌ Error reading ${file.path}: $e');
    }
  }

  print('✅ Extraction complete! Found $totalMatches Text widgets across ${files.length} files.');
}