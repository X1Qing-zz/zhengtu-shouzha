import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../core/date_utils.dart';
import 'database.dart';
import 'models.dart';

class DiaryRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<List<DiaryEntry>> all() async {
    final rows = await (await _db).query('diaries', orderBy: 'date DESC');
    return rows.map(DiaryEntry.fromMap).toList();
  }

  Future<DiaryEntry?> findByDate(DateTime date) async {
    final rows = await (await _db).query(
      'diaries',
      where: 'date = ?',
      whereArgs: [ymd(date)],
      limit: 1,
    );
    return rows.isEmpty ? null : DiaryEntry.fromMap(rows.first);
  }

  Future<DiaryEntry> upsert(DiaryEntry entry) async {
    final db = await _db;
    if (entry.id != null) {
      final rows = await db.query(
        'diaries',
        where: 'id = ?',
        whereArgs: [entry.id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final original = DiaryEntry.fromMap(rows.first);
        final merged = entry.copyWith(createdAt: original.createdAt);
        await db.update(
          'diaries',
          merged.toMap(),
          where: 'id = ?',
          whereArgs: [entry.id],
        );
        return merged;
      }
    }
    final existing = await findByDate(entry.date);
    if (existing == null) {
      final id = await db.insert('diaries', entry.toMap());
      return entry.copyWith(id: id);
    }
    final merged = entry.copyWith(id: existing.id, createdAt: existing.createdAt);
    await db.update(
      'diaries',
      merged.toMap(),
      where: 'id = ?',
      whereArgs: [existing.id],
    );
    return merged;
  }

  Future<void> delete(int id) async {
    await (await _db).delete('diaries', where: 'id = ?', whereArgs: [id]);
  }
}

class TaskRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<List<TaskItem>> all() async {
    final rows = await (await _db).query(
      'tasks',
      orderBy: 'done ASC, due_date IS NULL, due_date ASC, created_at DESC',
    );
    return rows.map(TaskItem.fromMap).toList();
  }

  Future<TaskItem> insert(TaskItem task) async {
    final id = await (await _db).insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  Future<void> update(TaskItem task) async {
    if (task.id == null) return;
    await (await _db).update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> setDone(int id, bool done) async {
    await (await _db).update(
      'tasks',
      {
        'done': done ? 1 : 0,
        'completed_at': done ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    await (await _db).delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}

class ExpenseRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<List<Expense>> all() async {
    final rows = await (await _db).query(
      'expenses',
      orderBy: 'spent_at DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<Expense> insert(Expense expense) async {
    final id = await (await _db).insert('expenses', expense.toMap());
    return expense.copyWith(id: id);
  }

  Future<void> update(Expense expense) async {
    if (expense.id == null) return;
    await (await _db).update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> delete(int id) async {
    await (await _db).delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}

class WeatherRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<WeatherSnapshot?> findByDate(DateTime date) async {
    final rows = await (await _db).query(
      'weather_cache',
      where: 'date = ?',
      whereArgs: [ymd(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final payload = jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
      return WeatherSnapshot.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(WeatherSnapshot snapshot) async {
    await (await _db).insert(
      'weather_cache',
      {
        'date': ymd(snapshot.date),
        'payload': jsonEncode(snapshot.toJson()),
        'updated_at': snapshot.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
