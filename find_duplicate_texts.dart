import 'dart:io';

final RegExp doubleQuoteTextRegex = RegExp(r'"([^"]+)"');

/**
 * lib/main.dart
 * find_duplicate_texts.dart
 */
// dart run find_duplicate_texts.dart lib/


void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('⚠️  Vui lòng truyền đường dẫn thư mục hoặc file Dart.');
    return;
  }

  final path = arguments.first;
  final textCount = <String, int>{};
  final textLocations = <String, List<String>>{};

  void processFile(File file) {
    final lines = file.readAsLinesSync();

    for (var i = 0; i < lines.length; i++) {
      final matches = doubleQuoteTextRegex.allMatches(lines[i]);
      for (final match in matches) {
        final rawText = match.group(1)?.trim();
        final normalizedText = rawText?.toLowerCase();
        if (normalizedText != null && normalizedText.isNotEmpty) {
          textCount[normalizedText] = (textCount[normalizedText] ?? 0) + 1;
          textLocations.putIfAbsent(normalizedText, () => []).add('${file.path}:${i + 1}');
        }
      }
    }
  }

  final entityType = FileSystemEntity.typeSync(path);
  if (entityType == FileSystemEntityType.directory) {
    final dartFiles = Directory(path)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      processFile(file);
    }
  } else if (entityType == FileSystemEntityType.file) {
    processFile(File(path));
  } else {
    print('❌ Không tìm thấy file hoặc thư mục.');
    return;
  }

  final duplicates = textCount.entries.where((e) => e.value > 1);

  if (duplicates.isEmpty) {
    print('✅ Không có text nào bị trùng.');
  } else {
    print('🔁 Các text bị trùng (không phân biệt hoa thường):');
    for (final entry in duplicates) {
      print('- "${entry.key}" xuất hiện ${entry.value} lần tại:');
      for (final loc in textLocations[entry.key]!) {
        print('  + $loc');
      }
    }
  }
}
