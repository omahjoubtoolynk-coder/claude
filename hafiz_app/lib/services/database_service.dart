import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/learning_progress.dart';
import '../models/daily_objective.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();
  Database? _db;

  Future<void> initDatabase() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'hafiz.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE progress (
            surah_number INTEGER PRIMARY KEY,
            verses_learned INTEGER,
            last_verse_number INTEGER,
            last_reviewed TEXT,
            mastery_level INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE objectives (
            id TEXT PRIMARY KEY,
            date TEXT,
            type INTEGER,
            title TEXT,
            target INTEGER,
            completed INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            verses_count INTEGER
          )
        ''');
      },
    );
  }

  Future<List<LearningProgress>> getAllProgress() async {
    final maps = await _db!.query('progress');
    return maps.map(LearningProgress.fromMap).toList();
  }

  Future<void> saveProgress(LearningProgress progress) async {
    await _db!.insert('progress', progress.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await _recordSession();
  }

  Future<List<DailyObjective>> getTodayObjectives() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final maps =
        await _db!.query('objectives', where: 'date = ?', whereArgs: [dateStr]);
    return maps.map(DailyObjective.fromMap).toList();
  }

  Future<void> saveObjectives(List<DailyObjective> objectives) async {
    final batch = _db!.batch();
    for (final obj in objectives) {
      batch.insert('objectives', obj.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit();
  }

  Future<void> updateObjective(DailyObjective objective) async {
    await _db!.update('objectives', objective.toMap(),
        where: 'id = ?', whereArgs: [objective.id]);
  }

  Future<void> _recordSession() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final existing = await _db!
        .query('sessions', where: 'date = ?', whereArgs: [dateStr]);
    if (existing.isEmpty) {
      await _db!.insert('sessions', {'date': dateStr, 'verses_count': 1});
    } else {
      await _db!.update(
        'sessions',
        {'verses_count': (existing.first['verses_count'] as int) + 1},
        where: 'date = ?',
        whereArgs: [dateStr],
      );
    }
  }

  Future<int> calculateStreak() async {
    final sessions = await _db!.query('sessions', orderBy: 'date DESC');
    if (sessions.isEmpty) return 0;
    int streak = 0;
    DateTime current = DateTime.now();
    for (final session in sessions) {
      final sessionDate = DateTime.parse(session['date'] as String);
      final diff = DateTime(current.year, current.month, current.day)
          .difference(
              DateTime(sessionDate.year, sessionDate.month, sessionDate.day))
          .inDays;
      if (diff <= 1) {
        streak++;
        current = sessionDate;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final now = DateTime.now();
    final stats = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final sessions = await _db!
          .query('sessions', where: 'date = ?', whereArgs: [dateStr]);
      stats.add({
        'date': dateStr,
        'verses': sessions.isEmpty ? 0 : sessions.first['verses_count'],
        'weekday': date.weekday,
      });
    }
    return stats;
  }
}
