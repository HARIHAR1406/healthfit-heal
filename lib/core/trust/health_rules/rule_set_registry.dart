import 'health_classification.dart';
import 'health_rule.dart';

/// Centralized registry of all health classification rules.
///
/// Rules are grouped by metric type and ordered from most severe (critical)
/// to least severe (normal). The [HealthRuleEngine] evaluates them in this
/// order — first matching rule wins.
///
/// ── Sources ───────────────────────────────────────────────────────────────────
/// • Heart Rate: AHA Adult Resting Heart Rate guidelines
/// • Blood Pressure: AHA 2017 Hypertension Guidelines
/// • Blood Sugar: ADA 2023 Standards of Care (fasting glucose)
/// • SpO₂: WHO / NHS Pulse Oximetry guidelines
/// • BMI: WHO BMI Classification
/// • Calorie Intake: General population dietary reference values (DRI)
///
/// ── Updating guidelines ───────────────────────────────────────────────────────
/// To update or add rules, edit this file ONLY.
/// Do not modify [HealthRuleEngine] or any calling code.
///
/// ── Important note ───────────────────────────────────────────────────────────
/// These are GENERAL adult population ranges. They do not account for age,
/// sex, medical history, medications, or individual variation.
/// Always display the standard classification disclaimer.
abstract final class RuleSetRegistry {
  // ── Metric Type Keys ────────────────────────────────────────────────────────
  // These must match the keys used in [HealthRuleEngine.classify].

  static const String heartRate = 'heartRate';
  static const String bloodPressureSystolic = 'bloodPressureSystolic';
  static const String bloodPressureDiastolic = 'bloodPressureDiastolic';
  static const String bloodSugarFasting = 'bloodSugarFasting';
  static const String bloodSugarPostMeal = 'bloodSugarPostMeal';
  static const String spo2 = 'spo2';
  static const String bmi = 'bmi';
  static const String dailyCalories = 'dailyCalories';
  static const String sodiumIntake = 'sodiumIntake';
  static const String fiberIntake = 'fiberIntake';

  // ── All rules by metric ─────────────────────────────────────────────────────

  /// Returns all rules for [metricType], ordered most-severe → least-severe.
  ///
  /// Returns an empty list if the metric type is not registered.
  static List<HealthRule> rulesFor(String metricType) =>
      _rules[metricType] ?? const [];

  /// Returns all registered metric type keys.
  static Set<String> get registeredMetrics => _rules.keys.toSet();

  // ── Rule Definitions ────────────────────────────────────────────────────────

  static final Map<String, List<HealthRule>> _rules = {
    // ── Heart Rate (resting, adult) ─────────────────────────────────────────
    heartRate: [
      const HealthRule(
        id: 'hr_critical_high',
        metricType: heartRate,
        minValue: 150,
        maxValue: double.infinity,
        level: HealthLevel.critical,
        message: 'Heart rate is critically elevated.',
        actionGuidance:
            'Stop activity immediately. If you feel chest pain, dizziness, '
            'or shortness of breath, call emergency services.',
        unit: 'bpm',
        reference: 'AHA Adult Heart Rate Guidelines',
      ),
      const HealthRule(
        id: 'hr_critical_low',
        metricType: heartRate,
        minValue: double.negativeInfinity,
        maxValue: 40,
        level: HealthLevel.critical,
        message: 'Heart rate is critically low.',
        actionGuidance:
            'If you feel faint, dizzy, or short of breath, seek immediate medical care.',
        unit: 'bpm',
        reference: 'AHA Adult Heart Rate Guidelines',
      ),
      const HealthRule(
        id: 'hr_high_risk',
        metricType: heartRate,
        minValue: 120,
        maxValue: 150,
        level: HealthLevel.highRisk,
        message: 'Heart rate is significantly elevated.',
        actionGuidance:
            'Rest and monitor. If this persists at rest, consult your doctor.',
        unit: 'bpm',
        reference: 'AHA Adult Heart Rate Guidelines',
      ),
      const HealthRule(
        id: 'hr_low_risk',
        metricType: heartRate,
        minValue: 40,
        maxValue: 60,
        level: HealthLevel.needsAttention,
        message: 'Heart rate is below the typical resting range.',
        actionGuidance:
            'A resting rate below 60 bpm may be normal for athletes. '
            'Monitor for symptoms such as fatigue or dizziness.',
        unit: 'bpm',
        reference: 'AHA Adult Heart Rate Guidelines',
      ),
      const HealthRule(
        id: 'hr_attention_high',
        metricType: heartRate,
        minValue: 100,
        maxValue: 120,
        level: HealthLevel.needsAttention,
        message: 'Heart rate is above the resting normal range.',
        actionGuidance:
            'Resting heart rate above 100 bpm (tachycardia) is worth monitoring. '
            'Reduce caffeine, manage stress, and consult your doctor if persistent.',
        unit: 'bpm',
        reference: 'AHA Adult Heart Rate Guidelines',
      ),
      const HealthRule(
        id: 'hr_normal',
        metricType: heartRate,
        minValue: 60,
        maxValue: 100,
        level: HealthLevel.normal,
        message: 'Heart rate is within the normal resting range.',
        actionGuidance: 'Keep up healthy habits: regular exercise, hydration, and sleep.',
        unit: 'bpm',
        reference: 'AHA Adult Heart Rate Guidelines',
      ),
    ],

    // ── Blood Pressure — Systolic (AHA 2017) ─────────────────────────────────
    bloodPressureSystolic: [
      const HealthRule(
        id: 'bp_sys_crisis',
        metricType: bloodPressureSystolic,
        minValue: 180,
        maxValue: double.infinity,
        level: HealthLevel.critical,
        message: 'Systolic blood pressure indicates hypertensive crisis.',
        actionGuidance:
            'Seek immediate emergency medical care if accompanied by '
            'chest pain, severe headache, visual changes, or difficulty breathing.',
        unit: 'mmHg',
        reference: 'AHA 2017 Hypertension Guidelines',
      ),
      const HealthRule(
        id: 'bp_sys_stage2',
        metricType: bloodPressureSystolic,
        minValue: 140,
        maxValue: 180,
        level: HealthLevel.highRisk,
        message: 'Systolic blood pressure — Stage 2 Hypertension.',
        actionGuidance:
            'Consult your doctor promptly. Lifestyle changes and/or medication may be required.',
        unit: 'mmHg',
        reference: 'AHA 2017 Hypertension Guidelines',
      ),
      const HealthRule(
        id: 'bp_sys_stage1',
        metricType: bloodPressureSystolic,
        minValue: 130,
        maxValue: 140,
        level: HealthLevel.needsAttention,
        message: 'Systolic blood pressure — Stage 1 Hypertension.',
        actionGuidance:
            'Reduce sodium intake, increase physical activity, and monitor regularly. '
            'Speak with your doctor about your risk factors.',
        unit: 'mmHg',
        reference: 'AHA 2017 Hypertension Guidelines',
      ),
      const HealthRule(
        id: 'bp_sys_elevated',
        metricType: bloodPressureSystolic,
        minValue: 120,
        maxValue: 130,
        level: HealthLevel.needsAttention,
        message: 'Systolic blood pressure is elevated.',
        actionGuidance:
            'Lifestyle changes — diet, exercise, and stress reduction — '
            'can help bring blood pressure into the normal range.',
        unit: 'mmHg',
        reference: 'AHA 2017 Hypertension Guidelines',
      ),
      const HealthRule(
        id: 'bp_sys_normal',
        metricType: bloodPressureSystolic,
        minValue: double.negativeInfinity,
        maxValue: 120,
        level: HealthLevel.normal,
        message: 'Systolic blood pressure is normal.',
        actionGuidance:
            'Maintain a heart-healthy diet and regular physical activity.',
        unit: 'mmHg',
        reference: 'AHA 2017 Hypertension Guidelines',
      ),
    ],

    // ── Blood Pressure — Diastolic (AHA 2017) ────────────────────────────────
    bloodPressureDiastolic: [
      const HealthRule(
        id: 'bp_dia_crisis',
        metricType: bloodPressureDiastolic,
        minValue: 120,
        maxValue: double.infinity,
        level: HealthLevel.critical,
        message: 'Diastolic blood pressure indicates hypertensive crisis.',
        actionGuidance: 'Seek immediate emergency medical care.',
        unit: 'mmHg',
        reference: 'AHA 2017 Hypertension Guidelines',
      ),
      const HealthRule(
        id: 'bp_dia_stage2',
        metricType: bloodPressureDiastolic,
        minValue: 90,
        maxValue: 120,
        level: HealthLevel.highRisk,
        message: 'Diastolic blood pressure — Stage 2 Hypertension.',
        actionGuidance:
            'Consult your doctor promptly. Medication may be required.',
        unit: 'mmHg',
        reference: 'AHA 2017 Hypertension Guidelines',
      ),
      const HealthRule(
        id: 'bp_dia_stage1',
        metricType: bloodPressureDiastolic,
        minValue: 80,
        maxValue: 90,
        level: HealthLevel.needsAttention,
        message: 'Diastolic blood pressure — Stage 1 Hypertension.',
        actionGuidance:
            'Monitor regularly. Lifestyle modifications recommended.',
        unit: 'mmHg',
        reference: 'AHA 2017 Hypertension Guidelines',
      ),
      const HealthRule(
        id: 'bp_dia_normal',
        metricType: bloodPressureDiastolic,
        minValue: double.negativeInfinity,
        maxValue: 80,
        level: HealthLevel.normal,
        message: 'Diastolic blood pressure is normal.',
        actionGuidance: 'Maintain a healthy lifestyle to keep it that way.',
        unit: 'mmHg',
        reference: 'AHA 2017 Hypertension Guidelines',
      ),
    ],

    // ── Blood Sugar — Fasting (ADA 2023, mg/dL) ──────────────────────────────
    bloodSugarFasting: [
      const HealthRule(
        id: 'bs_fast_critical',
        metricType: bloodSugarFasting,
        minValue: 400,
        maxValue: double.infinity,
        level: HealthLevel.critical,
        message: 'Fasting blood sugar is critically high.',
        actionGuidance:
            'Seek immediate medical attention. This level may indicate '
            'diabetic ketoacidosis or hyperglycaemic crisis.',
        unit: 'mg/dL',
        reference: 'ADA Standards of Care 2023',
      ),
      const HealthRule(
        id: 'bs_fast_diabetes',
        metricType: bloodSugarFasting,
        minValue: 126,
        maxValue: 400,
        level: HealthLevel.highRisk,
        message: 'Fasting blood sugar is in the diabetes range.',
        actionGuidance:
            'Consult your doctor promptly. A single elevated reading does not '
            'confirm a diagnosis — but it warrants clinical evaluation.',
        unit: 'mg/dL',
        reference: 'ADA Standards of Care 2023',
      ),
      const HealthRule(
        id: 'bs_fast_prediabetes',
        metricType: bloodSugarFasting,
        minValue: 100,
        maxValue: 126,
        level: HealthLevel.needsAttention,
        message: 'Fasting blood sugar is in the pre-diabetes range.',
        actionGuidance:
            'Diet modifications and regular exercise can reduce your risk. '
            'Discuss next steps with your healthcare provider.',
        unit: 'mg/dL',
        reference: 'ADA Standards of Care 2023',
      ),
      const HealthRule(
        id: 'bs_fast_normal',
        metricType: bloodSugarFasting,
        minValue: double.negativeInfinity,
        maxValue: 100,
        level: HealthLevel.normal,
        message: 'Fasting blood sugar is within the normal range.',
        actionGuidance:
            'A balanced diet low in refined carbohydrates helps maintain healthy blood sugar.',
        unit: 'mg/dL',
        reference: 'ADA Standards of Care 2023',
      ),
    ],

    // ── Blood Sugar — Post-Meal 2h (ADA 2023) ────────────────────────────────
    bloodSugarPostMeal: [
      const HealthRule(
        id: 'bs_post_critical',
        metricType: bloodSugarPostMeal,
        minValue: 400,
        maxValue: double.infinity,
        level: HealthLevel.critical,
        message: 'Post-meal blood sugar is critically high.',
        actionGuidance: 'Seek immediate medical attention.',
        unit: 'mg/dL',
        reference: 'ADA Standards of Care 2023',
      ),
      const HealthRule(
        id: 'bs_post_diabetes',
        metricType: bloodSugarPostMeal,
        minValue: 200,
        maxValue: 400,
        level: HealthLevel.highRisk,
        message: 'Post-meal blood sugar is in the diabetes range.',
        actionGuidance:
            'Consult your doctor. Consider reviewing meal composition '
            'and carbohydrate intake.',
        unit: 'mg/dL',
        reference: 'ADA Standards of Care 2023',
      ),
      const HealthRule(
        id: 'bs_post_prediabetes',
        metricType: bloodSugarPostMeal,
        minValue: 140,
        maxValue: 200,
        level: HealthLevel.needsAttention,
        message: 'Post-meal blood sugar is elevated.',
        actionGuidance:
            'Consider reducing refined carbohydrate intake and taking a '
            'short walk after meals to help lower blood sugar.',
        unit: 'mg/dL',
        reference: 'ADA Standards of Care 2023',
      ),
      const HealthRule(
        id: 'bs_post_normal',
        metricType: bloodSugarPostMeal,
        minValue: double.negativeInfinity,
        maxValue: 140,
        level: HealthLevel.normal,
        message: 'Post-meal blood sugar is within the healthy range.',
        actionGuidance: 'Balanced meals with fibre and protein help maintain this.',
        unit: 'mg/dL',
        reference: 'ADA Standards of Care 2023',
      ),
    ],

    // ── SpO₂ (WHO / NHS) ─────────────────────────────────────────────────────
    spo2: [
      const HealthRule(
        id: 'spo2_critical',
        metricType: spo2,
        minValue: double.negativeInfinity,
        maxValue: 90,
        level: HealthLevel.critical,
        message: 'Oxygen saturation is critically low.',
        actionGuidance:
            'Seek immediate emergency medical care. '
            'Low SpO₂ can indicate a serious medical emergency.',
        unit: '%',
        reference: 'WHO / NHS Pulse Oximetry Guidelines',
      ),
      const HealthRule(
        id: 'spo2_low',
        metricType: spo2,
        minValue: 90,
        maxValue: 95,
        level: HealthLevel.highRisk,
        message: 'Oxygen saturation is below the normal range.',
        actionGuidance:
            'Rest in a well-ventilated area. If this reading persists '
            'or you have breathing difficulty, seek medical attention.',
        unit: '%',
        reference: 'WHO / NHS Pulse Oximetry Guidelines',
      ),
      const HealthRule(
        id: 'spo2_normal',
        metricType: spo2,
        minValue: 95,
        maxValue: double.infinity,
        level: HealthLevel.normal,
        message: 'Oxygen saturation is within the normal range.',
        actionGuidance: 'Maintain good respiratory health with regular exercise.',
        unit: '%',
        reference: 'WHO / NHS Pulse Oximetry Guidelines',
      ),
    ],

    // ── BMI (WHO Classification) ──────────────────────────────────────────────
    bmi: [
      const HealthRule(
        id: 'bmi_obese_3',
        metricType: bmi,
        minValue: 40,
        maxValue: double.infinity,
        level: HealthLevel.critical,
        message: 'BMI indicates severe (Class III) obesity.',
        actionGuidance:
            'Consult a healthcare provider for a comprehensive weight management plan. '
            'Medical and nutritional support is strongly recommended.',
        unit: 'kg/m²',
        reference: 'WHO BMI Classification',
      ),
      const HealthRule(
        id: 'bmi_obese_2',
        metricType: bmi,
        minValue: 35,
        maxValue: 40,
        level: HealthLevel.highRisk,
        message: 'BMI indicates Class II obesity.',
        actionGuidance:
            'Discuss weight management with your doctor. '
            'A structured diet and exercise plan can significantly improve health outcomes.',
        unit: 'kg/m²',
        reference: 'WHO BMI Classification',
      ),
      const HealthRule(
        id: 'bmi_obese_1',
        metricType: bmi,
        minValue: 30,
        maxValue: 35,
        level: HealthLevel.highRisk,
        message: 'BMI indicates Class I obesity.',
        actionGuidance:
            'Focus on sustainable dietary changes and regular physical activity. '
            'Healthcare guidance is recommended.',
        unit: 'kg/m²',
        reference: 'WHO BMI Classification',
      ),
      const HealthRule(
        id: 'bmi_overweight',
        metricType: bmi,
        minValue: 25,
        maxValue: 30,
        level: HealthLevel.needsAttention,
        message: 'BMI indicates overweight.',
        actionGuidance:
            'A modest caloric deficit and increased physical activity '
            'can help move BMI into the healthy range.',
        unit: 'kg/m²',
        reference: 'WHO BMI Classification',
      ),
      const HealthRule(
        id: 'bmi_underweight',
        metricType: bmi,
        minValue: double.negativeInfinity,
        maxValue: 18.5,
        level: HealthLevel.needsAttention,
        message: 'BMI is below the healthy range.',
        actionGuidance:
            'Consider increasing nutrient-dense food intake and consulting '
            'a healthcare provider if weight loss is unintentional.',
        unit: 'kg/m²',
        reference: 'WHO BMI Classification',
      ),
      const HealthRule(
        id: 'bmi_normal',
        metricType: bmi,
        minValue: 18.5,
        maxValue: 25,
        level: HealthLevel.normal,
        message: 'BMI is within the healthy range.',
        actionGuidance: 'Maintain your healthy weight with a balanced diet and regular activity.',
        unit: 'kg/m²',
        reference: 'WHO BMI Classification',
      ),
    ],

    // ── Daily Calorie Intake (General DRI reference) ──────────────────────────
    dailyCalories: [
      const HealthRule(
        id: 'cal_very_low',
        metricType: dailyCalories,
        minValue: double.negativeInfinity,
        maxValue: 1000,
        level: HealthLevel.highRisk,
        message: 'Daily calorie intake is very low.',
        actionGuidance:
            'Intake below 1000 kcal/day risks nutritional deficiencies. '
            'Consult a registered dietitian before continuing a very low calorie diet.',
        unit: 'kcal',
        reference: 'General Dietary Reference Intakes (DRI)',
      ),
      const HealthRule(
        id: 'cal_low',
        metricType: dailyCalories,
        minValue: 1000,
        maxValue: 1500,
        level: HealthLevel.needsAttention,
        message: 'Daily calorie intake is below typical recommendations.',
        actionGuidance:
            'Ensure you are meeting your nutritional needs. '
            'A slight calorie deficit is appropriate for weight loss, '
            'but ensure adequate protein and micronutrient intake.',
        unit: 'kcal',
        reference: 'General Dietary Reference Intakes (DRI)',
      ),
      const HealthRule(
        id: 'cal_high',
        metricType: dailyCalories,
        minValue: 3500,
        maxValue: double.infinity,
        level: HealthLevel.needsAttention,
        message: 'Daily calorie intake is higher than typical recommendations.',
        actionGuidance:
            'High caloric intake over time may contribute to weight gain. '
            'Review meal choices and consider portion control.',
        unit: 'kcal',
        reference: 'General Dietary Reference Intakes (DRI)',
      ),
      const HealthRule(
        id: 'cal_normal',
        metricType: dailyCalories,
        minValue: 1500,
        maxValue: 3500,
        level: HealthLevel.normal,
        message: 'Daily calorie intake is within a reasonable range.',
        actionGuidance:
            'Focus on food quality as well as quantity — '
            'prioritise whole foods, vegetables, and lean proteins.',
        unit: 'kcal',
        reference: 'General Dietary Reference Intakes (DRI)',
      ),
    ],

    // ── Sodium Intake (AHA recommendation, mg/day) ────────────────────────────
    sodiumIntake: [
      const HealthRule(
        id: 'sodium_very_high',
        metricType: sodiumIntake,
        minValue: 5000,
        maxValue: double.infinity,
        level: HealthLevel.highRisk,
        message: 'Daily sodium intake is very high.',
        actionGuidance:
            'Significantly exceeds recommended intake. High sodium is linked to '
            'hypertension and cardiovascular risk. Reduce processed food consumption.',
        unit: 'mg',
        reference: 'AHA Dietary Sodium Guidelines',
      ),
      const HealthRule(
        id: 'sodium_high',
        metricType: sodiumIntake,
        minValue: 2300,
        maxValue: 5000,
        level: HealthLevel.needsAttention,
        message: 'Daily sodium intake exceeds recommendations.',
        actionGuidance:
            'AHA recommends < 2300 mg/day. Choose low-sodium options '
            'and reduce processed, packaged, and restaurant foods.',
        unit: 'mg',
        reference: 'AHA Dietary Sodium Guidelines',
      ),
      const HealthRule(
        id: 'sodium_normal',
        metricType: sodiumIntake,
        minValue: double.negativeInfinity,
        maxValue: 2300,
        level: HealthLevel.normal,
        message: 'Daily sodium intake is within recommended limits.',
        actionGuidance: 'Good job keeping sodium in check!',
        unit: 'mg',
        reference: 'AHA Dietary Sodium Guidelines',
      ),
    ],

    // ── Fiber Intake (DRI, g/day) ─────────────────────────────────────────────
    fiberIntake: [
      const HealthRule(
        id: 'fiber_low',
        metricType: fiberIntake,
        minValue: double.negativeInfinity,
        maxValue: 15,
        level: HealthLevel.needsAttention,
        message: 'Daily fiber intake is below recommendations.',
        actionGuidance:
            'Aim for 25–38 g/day (DRI). Add more vegetables, legumes, '
            'whole grains, and fruits to your diet.',
        unit: 'g',
        reference: 'Dietary Reference Intakes (DRI) — Fiber',
      ),
      const HealthRule(
        id: 'fiber_normal',
        metricType: fiberIntake,
        minValue: 15,
        maxValue: double.infinity,
        level: HealthLevel.normal,
        message: 'Daily fiber intake is meeting general recommendations.',
        actionGuidance:
            'Good fiber intake supports digestive health and blood sugar control.',
        unit: 'g',
        reference: 'Dietary Reference Intakes (DRI) — Fiber',
      ),
    ],
  };
}

