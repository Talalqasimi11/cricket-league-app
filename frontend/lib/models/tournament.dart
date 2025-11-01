import 'package:hive/hive.dart';

part 'tournament.g.dart';

@HiveType(typeId: 2)
class Tournament extends HiveObject {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final String format; // group, knockout, round-robin
  @HiveField(4)
  final DateTime startDate;
  @HiveField(5)
  final DateTime? endDate;
  @HiveField(6)
  final String status; // draft, scheduled, live, completed, cancelled
  @HiveField(7)
  final String? location;
  @HiveField(8)
  final int? prizePool;
  @HiveField(9)
  final String creatorId;
  @HiveField(10)
  final DateTime createdAt;
  @HiveField(11)
  final DateTime updatedAt;

  Tournament({
    required this.id,
    required this.name,
    this.description,
    required this.format,
    required this.startDate,
    this.endDate,
    required this.status,
    this.location,
    this.prizePool,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      format: json['format'] as String? ?? 'round-robin',
      startDate:
          DateTime.tryParse(json['start_date'] as String? ?? '') ??
          DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      status: json['status'] as String? ?? 'draft',
      location: json['location'] as String?,
      prizePool: json['prize_pool'] as int?,
      creatorId: json['creator_id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'format': format,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'location': location,
      'prize_pool': prizePool,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Tournament copyWith({
    int? id,
    String? name,
    String? description,
    String? format,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? location,
    int? prizePool,
    String? creatorId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      format: format ?? this.format,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      location: location ?? this.location,
      prizePool: prizePool ?? this.prizePool,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLive => status == 'live';
  bool get isCompleted => status == 'completed';
  bool get isScheduled => status == 'scheduled';
  bool get isDraft => status == 'draft';

  @override
  String toString() {
    return 'Tournament(id: $id, name: $name, status: $status)';
  }
}
