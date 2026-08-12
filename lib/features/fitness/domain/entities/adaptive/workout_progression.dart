/// Long-term progression state across multiple sessions.
enum ProgressionState {
  improving,
  stable,
  needsAttention,
  insufficientData,
}

/// Analysis of user's progression over time.
class WorkoutProgression {
  const WorkoutProgression({
    required this.state,
    required this.metrics,
    required this.reasoning,
  });

  /// The overarching progression state.
  final ProgressionState state;

  /// Key metrics supporting this progression (e.g., {"Volume": "+5%", "Consistency": "High"}).
  final Map<String, String> metrics;

  /// Human-readable explanation.
  /// Example: "You've consistently increased total reps over the last 3 sessions."
  final String reasoning;

  factory WorkoutProgression.insufficientData() {
    return const WorkoutProgression(
      state: ProgressionState.insufficientData,
      metrics: {},
      reasoning: 'Not enough history to evaluate progression trends.',
    );
  }
}

