import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// UNIT SYSTEM
// ══════════════════════════════════════════════════════════════════════════════

enum UnitSystem {
  metric('Metric', 'kg / cm'),
  imperial('Imperial', 'lb / ft');

  const UnitSystem(this.label, this.abbreviation);
  final String label;
  final String abbreviation;
}

// ══════════════════════════════════════════════════════════════════════════════
// APP THEME PREFERENCE
// ══════════════════════════════════════════════════════════════════════════════

enum AppThemePreference {
  system('System Default', Icons.brightness_auto_rounded),
  light('Light', Icons.light_mode_rounded),
  dark('Dark', Icons.dark_mode_rounded);

  const AppThemePreference(this.label, this.icon);
  final String label;
  final IconData icon;
}

// ══════════════════════════════════════════════════════════════════════════════
// GENDER
// ══════════════════════════════════════════════════════════════════════════════

enum Gender {
  male('Male', '♂'),
  female('Female', '♀'),
  nonBinary('Non-binary', '⚧'),
  preferNotToSay('Prefer not to say', '•');

  const Gender(this.label, this.symbol);
  final String label;
  final String symbol;
}

// ══════════════════════════════════════════════════════════════════════════════
// ACTIVITY LEVEL
// ══════════════════════════════════════════════════════════════════════════════

enum ActivityLevel {
  sedentary('Sedentary', 'Little or no exercise', 1.2),
  lightlyActive('Lightly Active', '1–3 days/week', 1.375),
  moderatelyActive('Moderately Active', '3–5 days/week', 1.55),
  veryActive('Very Active', '6–7 days/week', 1.725),
  extraActive('Extra Active', 'Very intense daily exercise', 1.9);

  const ActivityLevel(this.label, this.description, this.multiplier);
  final String label;
  final String description;
  final double multiplier;
}

// ══════════════════════════════════════════════════════════════════════════════
// HEALTH GOALS
// ══════════════════════════════════════════════════════════════════════════════

class HealthGoals {
  const HealthGoals({
    required this.dailyCaloriesTarget,
    required this.dailyWaterMlTarget,
    required this.dailyStepsTarget,
    required this.weeklyWorkoutsTarget,
    required this.targetWeightKg,
    required this.sleepHoursTarget,
  });

  final double dailyCaloriesTarget;
  final double dailyWaterMlTarget;
  final int dailyStepsTarget;
  final int weeklyWorkoutsTarget;
  final double targetWeightKg;
  final double sleepHoursTarget;

  HealthGoals copyWith({
    double? dailyCaloriesTarget,
    double? dailyWaterMlTarget,
    int? dailyStepsTarget,
    int? weeklyWorkoutsTarget,
    double? targetWeightKg,
    double? sleepHoursTarget,
  }) =>
      HealthGoals(
        dailyCaloriesTarget: dailyCaloriesTarget ?? this.dailyCaloriesTarget,
        dailyWaterMlTarget: dailyWaterMlTarget ?? this.dailyWaterMlTarget,
        dailyStepsTarget: dailyStepsTarget ?? this.dailyStepsTarget,
        weeklyWorkoutsTarget: weeklyWorkoutsTarget ?? this.weeklyWorkoutsTarget,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
        sleepHoursTarget: sleepHoursTarget ?? this.sleepHoursTarget,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION PREFERENCES
// ══════════════════════════════════════════════════════════════════════════════

class NotificationPrefs {
  const NotificationPrefs({
    this.workoutReminders = true,
    this.mealReminders = true,
    this.waterReminders = true,
    this.medicationReminders = true,
    this.aiInsights = true,
    this.weeklyReports = false,
    this.reminderHour = 8,
    this.reminderMinute = 0,
  });

  final bool workoutReminders;
  final bool mealReminders;
  final bool waterReminders;
  final bool medicationReminders;
  final bool aiInsights;
  final bool weeklyReports;
  final int reminderHour;
  final int reminderMinute;

  NotificationPrefs copyWith({
    bool? workoutReminders,
    bool? mealReminders,
    bool? waterReminders,
    bool? medicationReminders,
    bool? aiInsights,
    bool? weeklyReports,
    int? reminderHour,
    int? reminderMinute,
  }) =>
      NotificationPrefs(
        workoutReminders: workoutReminders ?? this.workoutReminders,
        mealReminders: mealReminders ?? this.mealReminders,
        waterReminders: waterReminders ?? this.waterReminders,
        medicationReminders: medicationReminders ?? this.medicationReminders,
        aiInsights: aiInsights ?? this.aiInsights,
        weeklyReports: weeklyReports ?? this.weeklyReports,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// APP SETTINGS
// ══════════════════════════════════════════════════════════════════════════════

class AppSettings {
  const AppSettings({
    this.themePreference = AppThemePreference.system,
    this.unitSystem = UnitSystem.metric,
    this.notificationPrefs = const NotificationPrefs(),
    this.useBiometricAuth = false,
    this.shareAnonymousData = true,
    this.appVersion = '1.0.0',
  });

  final AppThemePreference themePreference;
  final UnitSystem unitSystem;
  final NotificationPrefs notificationPrefs;
  final bool useBiometricAuth;
  final bool shareAnonymousData;
  final String appVersion;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    UnitSystem? unitSystem,
    NotificationPrefs? notificationPrefs,
    bool? useBiometricAuth,
    bool? shareAnonymousData,
  }) =>
      AppSettings(
        themePreference: themePreference ?? this.themePreference,
        unitSystem: unitSystem ?? this.unitSystem,
        notificationPrefs: notificationPrefs ?? this.notificationPrefs,
        useBiometricAuth: useBiometricAuth ?? this.useBiometricAuth,
        shareAnonymousData: shareAnonymousData ?? this.shareAnonymousData,
        appVersion: appVersion,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// USER PROFILE ENTITY
// ══════════════════════════════════════════════════════════════════════════════

class UserProfileEntity {
  const UserProfileEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goals,
    required this.settings,
    required this.joinedAt,
    this.avatarUrl,
    this.phone,
    this.bio,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime dateOfBirth;
  final Gender gender;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final HealthGoals goals;
  final AppSettings settings;
  final DateTime joinedAt;
  final String? avatarUrl;
  final String? phone;
  final String? bio;

  // ── Computed ──────────────────────────────────────────────────────────────

  String get fullName => '$firstName $lastName';

  int get age {
    final now = DateTime.now();
    var a = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      a--;
    }
    return a;
  }

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiLabel {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }

  Color get bmiColor {
    final b = bmi;
    if (b < 18.5) return const Color(0xFF00B4D8);
    if (b < 25) return const Color(0xFF00C896);
    if (b < 30) return const Color(0xFFFFBF00);
    return const Color(0xFFFF6B6B);
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  /// Estimated TDEE (Total Daily Energy Expenditure) in kcal.
  double get tdee {
    // Mifflin-St Jeor BMR
    double bmr;
    if (gender == Gender.male) {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
    return bmr * activityLevel.multiplier;
  }

  UserProfileEntity copyWith({
    String? firstName,
    String? lastName,
    String? email,
    DateTime? dateOfBirth,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    HealthGoals? goals,
    AppSettings? settings,
    String? avatarUrl,
    String? phone,
    String? bio,
  }) =>
      UserProfileEntity(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        goals: goals ?? this.goals,
        settings: settings ?? this.settings,
        joinedAt: joinedAt,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phone: phone ?? this.phone,
        bio: bio ?? this.bio,
      );
}

