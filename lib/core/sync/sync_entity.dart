import 'package:equatable/equatable.dart';

/// Sync operation types for the offline queue.
enum SyncOperation {
  create,
  update,
  delete,
}

/// Status of a sync queue item.
enum SyncStatus {
  pending,
  inProgress,
  succeeded,
  failed,
  conflicted,
}

/// Conflict resolution strategy for data conflicts.
enum ConflictStrategy {
  /// Server data always wins.
  serverWins,

  /// Client data always wins (risky — use with care).
  clientWins,

  /// The most recently modified version wins.
  lastWriteWins,
}

/// A single pending sync operation.
class SyncQueueItem extends Equatable {
  const SyncQueueItem({
    required this.id,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.lastError,
    this.lastAttemptAt,
  });

  /// Unique ID for this queue item.
  final String id;

  /// The operation to perform on the backend.
  final SyncOperation operation;

  /// The type of entity being synced (e.g. 'health_metric', 'workout').
  final String entityType;

  /// The ID of the entity being synced.
  final String entityId;

  /// The serialized payload to send to the backend.
  final Map<String, dynamic> payload;

  /// When this item was enqueued.
  final DateTime createdAt;

  /// Current sync status.
  final SyncStatus status;

  /// Number of retry attempts so far.
  final int retryCount;

  /// Maximum retry attempts before marking as [SyncStatus.failed].
  final int maxRetries;

  /// Last error message if status is [SyncStatus.failed].
  final String? lastError;

  /// When the last sync attempt was made.
  final DateTime? lastAttemptAt;

  bool get canRetry => retryCount < maxRetries;

  bool get hasFailed => status == SyncStatus.failed;

  bool get isConflicted => status == SyncStatus.conflicted;

  SyncQueueItem copyWith({
    SyncStatus? status,
    int? retryCount,
    String? lastError,
    DateTime? lastAttemptAt,
  }) {
    return SyncQueueItem(
      id: id,
      operation: operation,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      createdAt: createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries,
      lastError: lastError ?? this.lastError,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation.name,
      'entityType': entityType,
      'entityId': entityId,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'lastError': lastError,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
    };
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as String,
      operation: SyncOperation.values.byName(json['operation'] as String),
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      payload: (json['payload'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: SyncStatus.values.byName(
        (json['status'] as String?) ?? 'pending',
      ),
      retryCount: (json['retryCount'] as int?) ?? 0,
      maxRetries: (json['maxRetries'] as int?) ?? 3,
      lastError: json['lastError'] as String?,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.tryParse(json['lastAttemptAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, operation, entityType, entityId, status];
}

/// Sync result from processing a single [SyncQueueItem].
class SyncResult {
  const SyncResult({
    required this.item,
    required this.success,
    this.error,
  });

  final SyncQueueItem item;
  final bool success;
  final String? error;
}
