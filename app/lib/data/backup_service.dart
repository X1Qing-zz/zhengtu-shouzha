import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/date_utils.dart';
import 'database.dart';
import 'models.dart';

class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupPackage {
  BackupPackage({
    required this.settings,
    required this.diaries,
    required this.tasks,
    required this.expenses,
    required this.images,
    required this.exportedAt,
    required this.appVersion,
  });

  final Map<String, Object?> settings;
  final List<Map<String, Object?>> diaries;
  final List<Map<String, Object?>> tasks;
  final List<Map<String, Object?>> expenses;
  final Map<String, Uint8List> images;
  final DateTime exportedAt;
  final String appVersion;

  int get diaryCount => diaries.length;
  int get taskCount => tasks.length;
  int get expenseCount => expenses.length;
  int get imageCount => images.length;
}

class RestoreResult {
  const RestoreResult({
    required this.diaries,
    required this.tasks,
    required this.expenses,
    required this.images,
    required this.settings,
  });

  final int diaries;
  final int tasks;
  final int expenses;
  final int images;
  final Map<String, Object?> settings;
}

class BackupService {
  static const String appId = 'zhengtu_shouzha';
  static const int formatVersion = 2;

  Future<File> export({
    required List<DiaryEntry> diaries,
    required List<TaskItem> tasks,
    required List<Expense> expenses,
    required Map<String, Object?> settings,
    required String appVersion,
  }) async {
    final archive = Archive();
    final serializedDiaries = <Map<String, Object?>>[];

    for (final diary in diaries) {
      final map = Map<String, Object?>.from(diary.toMap())..remove('id');
      final imageEntries = <String>[];
      for (var index = 0; index < diary.images.length; index++) {
        final source = File(diary.images[index]);
        if (!await source.exists()) continue;
        final extension = p.extension(source.path).toLowerCase();
        final safeExtension = extension.isEmpty ? '.jpg' : extension;
        final entryName = 'images/${ymd(diary.date)}_$index$safeExtension';
        final bytes = await source.readAsBytes();
        archive.addFile(ArchiveFile.bytes(entryName, bytes));
        imageEntries.add(entryName);
      }
      map['images'] = imageEntries.join('|');
      serializedDiaries.add(map);
    }

    final payload = <String, Object?>{
      'app': appId,
      'schema': formatVersion,
      'app_version': appVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'settings': settings,
      'diaries': serializedDiaries,
      'tasks': [for (final task in tasks) Map<String, Object?>.from(task.toMap())..remove('id')],
      'expenses': [
        for (final expense in expenses) Map<String, Object?>.from(expense.toMap())..remove('id'),
      ],
    };

    final jsonBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(payload));
    archive.addFile(ArchiveFile.bytes('data.json', jsonBytes));

    final zipBytes = ZipEncoder().encodeBytes(archive);
    final directory = await getTemporaryDirectory();
    final file = File(
      p.join(directory.path, 'zhengtu_backup_${fileDateStamp(DateTime.now())}.zip'),
    );
    await file.writeAsBytes(zipBytes, flush: true);
    return file;
  }

  Future<BackupPackage> read(File file) async {
    if (!await file.exists()) {
      throw BackupException('找不到这个备份文件');
    }
    final raw = await file.readAsBytes();
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(raw);
    } catch (_) {
      throw BackupException('备份文件损坏或不是有效的 ZIP');
    }

    ArchiveFile? dataFile;
    for (final entry in archive.files) {
      if (entry.name == 'data.json' && entry.isFile) {
        dataFile = entry;
        break;
      }
    }
    if (dataFile == null) {
      throw BackupException('备份里缺少 data.json');
    }

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(utf8.decode(dataFile.content)) as Map<String, dynamic>;
    } catch (_) {
      throw BackupException('备份内容无法读取');
    }

    if (payload['app'] != appId) {
      throw BackupException('这不是征途手札的备份文件');
    }

    final diaries = _readRecordList(payload['diaries'], '手札');
    final tasks = _readRecordList(payload['tasks'], '任务');
    final expenses = _readRecordList(payload['expenses'], '账目');

    final images = <String, Uint8List>{};
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      if (!entry.name.startsWith('images/')) continue;
      images[entry.name] = entry.content;
    }

    final settings = payload['settings'] is Map
        ? Map<String, Object?>.from(payload['settings'] as Map)
        : <String, Object?>{};
    final exportedAt = DateTime.tryParse(payload['exported_at'] as String? ?? '') ?? DateTime.now();
    final appVersion = payload['app_version'] as String? ?? 'unknown';

    return BackupPackage(
      settings: settings,
      diaries: diaries,
      tasks: tasks,
      expenses: expenses,
      images: images,
      exportedAt: exportedAt,
      appVersion: appVersion,
    );
  }

  List<Map<String, Object?>> _readRecordList(Object? raw, String label) {
    if (raw is! List) {
      throw BackupException('备份里的$label数据格式不正确');
    }
    final result = <Map<String, Object?>>[];
    for (final item in raw) {
      if (item is! Map) {
        throw BackupException('备份里的$label数据格式不正确');
      }
      result.add(Map<String, Object?>.from(item));
    }
    return result;
  }

  Future<RestoreResult> restore(BackupPackage package) async {
    final documents = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory(p.join(documents.path, 'diary_images'));
    await imageDirectory.create(recursive: true);

    final savedImages = <String, String>{};
    var imageIndex = 0;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (final entry in package.images.entries) {
      final extension = p.extension(entry.key).toLowerCase();
      final safeExtension = extension.isEmpty ? '.jpg' : extension;
      final target = File(
        p.join(imageDirectory.path, 'restored_${stamp}_${imageIndex++}$safeExtension'),
      );
      await target.writeAsBytes(entry.value, flush: true);
      savedImages[entry.key] = target.path;
    }

    final diaryRows = <Map<String, Object?>>[];
    for (final row in package.diaries) {
      final map = Map<String, Object?>.from(row)..remove('id');
      final imageKeys = (map['images'] as String? ?? '')
          .split('|')
          .where((key) => key.trim().isNotEmpty)
          .toList();
      final restoredImages = <String>[
        for (final key in imageKeys)
          if (savedImages[key] != null) savedImages[key]!,
      ];
      map['images'] = restoredImages.join('|');
      diaryRows.add(map);
    }

    final taskRows = [
      for (final row in package.tasks) Map<String, Object?>.from(row)..remove('id'),
    ];
    final expenseRows = [
      for (final row in package.expenses) Map<String, Object?>.from(row)..remove('id'),
    ];

    try {
      final db = await AppDatabase.instance.database;
      await db.transaction((txn) async {
        await txn.delete('diaries');
        await txn.delete('tasks');
        await txn.delete('expenses');
        await txn.delete('weather_cache');
        for (final row in diaryRows) {
          await txn.insert('diaries', row);
        }
        for (final row in taskRows) {
          await txn.insert('tasks', row);
        }
        for (final row in expenseRows) {
          await txn.insert('expenses', row);
        }
      });
    } catch (_) {
      throw BackupException('恢复失败，当前数据没有被替换');
    }

    return RestoreResult(
      diaries: diaryRows.length,
      tasks: taskRows.length,
      expenses: expenseRows.length,
      images: savedImages.length,
      settings: package.settings,
    );
  }
}
