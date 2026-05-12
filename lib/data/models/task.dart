class Task {
  final String id;
  final String name;
  final int position;
  final String createdAt;

  // Reminder fields — null means no reminder set for this task
  final String? reminderTime;   // "HH:mm" 24-hour, e.g. "07:30"
  final bool reminderEnabled;

  Task({
    required this.id,
    required this.name,
    required this.position,
    required this.createdAt,
    this.reminderTime,
    this.reminderEnabled = false,
  });

  Task copyWith({
    String? id,
    String? name,
    int? position,
    String? createdAt,
    String? reminderTime,
    bool? reminderEnabled,
    bool clearReminderTime = false,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      reminderTime: clearReminderTime ? null : (reminderTime ?? this.reminderTime),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      name: map['name'] as String,
      position: map['position'] as int,
      createdAt: map['created_at'] as String,
      reminderTime: map['reminder_time'] as String?,
      reminderEnabled: (map['reminder_enabled'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'created_at': createdAt,
      'reminder_time': reminderTime,
      'reminder_enabled': reminderEnabled ? 1 : 0,
    };
  }
}
