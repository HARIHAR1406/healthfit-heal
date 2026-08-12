// ── Enums ─────────────────────────────────────────────────────────────────────

/// Processing status of a conversation.
enum ConversationStatus {
  active,
  archived,
  deleted,
}

/// AI coaching domain / persona.
enum CoachType {
  general,
  health,
  fitness,
  nutrition,
  lifestyle,
  habit,
}

extension CoachTypeX on CoachType {
  String get label => switch (this) {
        CoachType.general => 'AI Assistant',
        CoachType.health => 'Health Coach',
        CoachType.fitness => 'Fitness Coach',
        CoachType.nutrition => 'Nutrition Coach',
        CoachType.lifestyle => 'Lifestyle Coach',
        CoachType.habit => 'Habit Coach',
      };

  String get emoji => switch (this) {
        CoachType.general => '🤖',
        CoachType.health => '❤️',
        CoachType.fitness => '💪',
        CoachType.nutrition => '🥗',
        CoachType.lifestyle => '🌿',
        CoachType.habit => '✅',
      };

  String get systemPrompt => switch (this) {
        CoachType.general =>
          'You are a helpful AI health assistant for the HealthFit Heal app.',
        CoachType.health =>
          'You are a health coaching AI specialising in medical wellness, vital signs, and preventive care.',
        CoachType.fitness =>
          'You are a fitness coaching AI specialising in workout plans, exercise science, and athletic performance.',
        CoachType.nutrition =>
          'You are a nutrition coaching AI specialising in meal planning, macronutrients, and dietary advice.',
        CoachType.lifestyle =>
          'You are a lifestyle coaching AI specialising in sleep, stress management, and work-life balance.',
        CoachType.habit =>
          'You are a habit coaching AI specialising in behaviour change, goal setting, and daily routines.',
      };
}

// ── Entity ────────────────────────────────────────────────────────────────────

/// A conversation session with the AI assistant.
class ConversationEntity {
  const ConversationEntity({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.coachType = CoachType.general,
    this.status = ConversationStatus.active,
    this.isPinned = false,
    this.messageCount = 0,
  });

  final String id;
  final String title;
  final List<dynamic> messages; // List<MessageEntity> — avoid circular import
  final DateTime createdAt;
  final DateTime updatedAt;
  final CoachType coachType;
  final ConversationStatus status;
  final bool isPinned;
  final int messageCount;

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get isActive => status == ConversationStatus.active;
  bool get isArchived => status == ConversationStatus.archived;
  bool get isEmpty => messages.isEmpty;

  String get lastMessagePreview {
    if (messages.isEmpty) return 'No messages yet';
    final last = messages.last;
    final content = last.content as String;
    return content.length > 60 ? '${content.substring(0, 57)}…' : content;
  }

  // ── Copy ───────────────────────────────────────────────────────────────────

  ConversationEntity copyWith({
    String? title,
    List<dynamic>? messages,
    DateTime? updatedAt,
    ConversationStatus? status,
    bool? isPinned,
    int? messageCount,
  }) =>
      ConversationEntity(
        id: id,
        title: title ?? this.title,
        messages: messages ?? this.messages,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        coachType: coachType,
        status: status ?? this.status,
        isPinned: isPinned ?? this.isPinned,
        messageCount: messageCount ?? this.messageCount,
      );
}

