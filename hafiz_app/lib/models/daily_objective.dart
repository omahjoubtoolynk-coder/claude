enum ObjectiveType { learning, revision, listening, recitation }

class DailyObjective {
  final String id;
  final String date;
  final ObjectiveType type;
  final String title;
  final int target;
  final int completed;

  const DailyObjective({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    required this.target,
    required this.completed,
  });

  bool get isCompleted => completed >= target;
  double get progress => target > 0 ? (completed / target).clamp(0.0, 1.0) : 0;

  DailyObjective copyWith({int? completed}) => DailyObjective(
        id: id,
        date: date,
        type: type,
        title: title,
        target: target,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'type': type.index,
        'title': title,
        'target': target,
        'completed': completed,
      };

  factory DailyObjective.fromMap(Map<String, dynamic> map) => DailyObjective(
        id: map['id'],
        date: map['date'],
        type: ObjectiveType.values[map['type']],
        title: map['title'],
        target: map['target'],
        completed: map['completed'],
      );
}
