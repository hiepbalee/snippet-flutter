import 'dart:io';

final RegExp quotedTextRegex = RegExp(r'''(["'])(.*?)\1''');

bool isJustSymbol(String text) {
  return RegExp(r'^[\W_]+$').hasMatch(text);
}

bool isNonUserFacingText(String text) {
  return text.startsWith('package:') ||
      text.startsWith('dart:') ||
      text.startsWith('http') ||
      text.endsWith('.dart') ||
      text.contains('/') ||
      text.endsWith('.png') ||
      text.endsWith('.jpg') ||
      text.endsWith('.svg') ||
      text.endsWith('.json') ||
      text.contains('_repository') ||
      text.length < 3;
}

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
      final matches = quotedTextRegex.allMatches(lines[i]);
      for (final match in matches) {
        final rawText = match.group(2)?.trim();
        final normalizedText = rawText?.toLowerCase();
        if (normalizedText != null &&
            normalizedText.isNotEmpty &&
            !isJustSymbol(normalizedText) &&
            !isNonUserFacingText(normalizedText)) {
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
    print('🔁 Các text bị trùng (không phân biệt hoa thường, đã lọc các chuỗi kỹ thuật):');
    for (final entry in duplicates) {
      print('- "${entry.key}" xuất hiện ${entry.value} lần tại:');
      for (final loc in textLocations[entry.key]!) {
        print('  + $loc');
      }
    }
  }
}
