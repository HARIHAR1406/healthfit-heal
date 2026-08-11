import 'package:flutter_test/flutter_test.dart';
import 'package:healthfit_heal/core/trust/health_rules/health_classification.dart';
import 'package:healthfit_heal/core/trust/health_rules/health_rule_engine.dart';
import 'package:healthfit_heal/core/trust/health_rules/rule_set_registry.dart';

void main() {
  const engine = HealthRuleEngine();

  // ── Heart Rate ─────────────────────────────────────────────────────────────

  group('Heart Rate', () {
    test('55 bpm → needsAttention (below normal)', () {
      final r = engine.classify(metricType: RuleSetRegistry.heartRate, value: 55);
      expect(r.level, HealthLevel.needsAttention);
    });

    test('60 bpm → normal (exact lower boundary)', () {
      final r = engine.classify(metricType: RuleSetRegistry.heartRate, value: 60);
      expect(r.level, HealthLevel.normal);
    });

    test('80 bpm → normal', () {
      final r = engine.classify(metricType: RuleSetRegistry.heartRate, value: 80);
      expect(r.level, HealthLevel.normal);
    });

    test('99 bpm → normal (upper boundary)', () {
      final r = engine.classify(metricType: RuleSetRegistry.heartRate, value: 99);
      expect(r.level, HealthLevel.normal);
    });

    test('100 bpm → normal (exactly 100)', () {
      // Range is [60, 100) so 100 should NOT be normal
      final r = engine.classify(metricType: RuleSetRegistry.heartRate, value: 100);
      expect(r.level, HealthLevel.needsAttention);
    });

    test('110 bpm → needsAttention', () {
      final r = engine.classify(metricType: RuleSetRegistry.heartRate, value: 110);
      expect(r.level, HealthLevel.needsAttention);
    });

    test('125 bpm → highRisk', () {
      final r = engine.classify(metricType: RuleSetRegistry.heartRate, value: 125);
      expect(r.level, HealthLevel.highRisk);
    });

    test('150 bpm → critical (exact boundary)', () {
      final r = engine.classify(metricType: RuleSetRegistry.heartRate, value: 150);
      expect(r.level, HealthLevel.critical);
    });

    test('200 bpm → critical', () {
      final r = engine.classify(metricType: RuleSetRegistry.heartRate, value: 200);
      expect(r.level, HealthLevel.critical);
    });

    test('39 bpm → critical (critically low)', () {
      final r = engine.classify(metricType: RuleSetRegistry.heartRate, value: 39);
      expect(r.level, HealthLevel.critical);
    });

    test('classification has unit "bpm"', () {
      final r = engine.classify(metricType: RuleSetRegistry.heartRate, value: 72);
      expect(r.unit, 'bpm');
    });

    test('classification has non-null message and actionGuidance', () {
      final r = engine.classify(metricType: RuleSetRegistry.heartRate, value: 72);
      expect(r.message, isNotEmpty);
      expect(r.actionGuidance, isNotEmpty);
    });
  });

  // ── Blood Pressure Systolic ────────────────────────────────────────────────

  group('Blood Pressure — Systolic', () {
    test('110 mmHg → normal', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.bloodPressureSystolic,
        value: 110,
      );
      expect(r.level, HealthLevel.normal);
    });

    test('120 mmHg → needsAttention (elevated)', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.bloodPressureSystolic,
        value: 120,
      );
      expect(r.level, HealthLevel.needsAttention);
    });

    test('135 mmHg → needsAttention (stage 1)', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.bloodPressureSystolic,
        value: 135,
      );
      expect(r.level, HealthLevel.needsAttention);
    });

    test('145 mmHg → highRisk (stage 2)', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.bloodPressureSystolic,
        value: 145,
      );
      expect(r.level, HealthLevel.highRisk);
    });

    test('180 mmHg → critical (crisis)', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.bloodPressureSystolic,
        value: 180,
      );
      expect(r.level, HealthLevel.critical);
      expect(r.requiresProfessionalConsultation, isTrue);
    });
  });

  // ── Blood Sugar Fasting ────────────────────────────────────────────────────

  group('Blood Sugar — Fasting', () {
    test('85 mg/dL → normal', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.bloodSugarFasting,
        value: 85,
      );
      expect(r.level, HealthLevel.normal);
    });

    test('100 mg/dL → needsAttention (pre-diabetes boundary)', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.bloodSugarFasting,
        value: 100,
      );
      expect(r.level, HealthLevel.needsAttention);
    });

    test('115 mg/dL → needsAttention (pre-diabetes)', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.bloodSugarFasting,
        value: 115,
      );
      expect(r.level, HealthLevel.needsAttention);
    });

    test('130 mg/dL → highRisk (diabetes range)', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.bloodSugarFasting,
        value: 130,
      );
      expect(r.level, HealthLevel.highRisk);
    });

    test('450 mg/dL → critical', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.bloodSugarFasting,
        value: 450,
      );
      expect(r.level, HealthLevel.critical);
      expect(r.requiresProfessionalConsultation, isTrue);
    });
  });

  // ── SpO₂ ──────────────────────────────────────────────────────────────────

  group('SpO₂', () {
    test('98% → normal', () {
      final r = engine.classify(metricType: RuleSetRegistry.spo2, value: 98);
      expect(r.level, HealthLevel.normal);
    });

    test('95% → normal (exact lower boundary)', () {
      final r = engine.classify(metricType: RuleSetRegistry.spo2, value: 95);
      expect(r.level, HealthLevel.normal);
    });

    test('94% → highRisk (below 95)', () {
      final r = engine.classify(metricType: RuleSetRegistry.spo2, value: 94);
      expect(r.level, HealthLevel.highRisk);
    });

    test('89% → critical (below 90)', () {
      final r = engine.classify(metricType: RuleSetRegistry.spo2, value: 89);
      expect(r.level, HealthLevel.critical);
      expect(r.requiresProfessionalConsultation, isTrue);
    });
  });

  // ── BMI ───────────────────────────────────────────────────────────────────

  group('BMI', () {
    test('17 kg/m² → needsAttention (underweight)', () {
      final r = engine.classify(metricType: RuleSetRegistry.bmi, value: 17);
      expect(r.level, HealthLevel.needsAttention);
    });

    test('22 kg/m² → normal', () {
      final r = engine.classify(metricType: RuleSetRegistry.bmi, value: 22);
      expect(r.level, HealthLevel.normal);
    });

    test('27 kg/m² → needsAttention (overweight)', () {
      final r = engine.classify(metricType: RuleSetRegistry.bmi, value: 27);
      expect(r.level, HealthLevel.needsAttention);
    });

    test('32 kg/m² → highRisk (obese class 1)', () {
      final r = engine.classify(metricType: RuleSetRegistry.bmi, value: 32);
      expect(r.level, HealthLevel.highRisk);
    });

    test('41 kg/m² → critical (severe obesity)', () {
      final r = engine.classify(metricType: RuleSetRegistry.bmi, value: 41);
      expect(r.level, HealthLevel.critical);
    });
  });

  // ── Daily Calories ────────────────────────────────────────────────────────

  group('Daily Calories', () {
    test('800 kcal → highRisk (very low)', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.dailyCalories,
        value: 800,
      );
      expect(r.level, HealthLevel.highRisk);
    });

    test('1200 kcal → needsAttention (low)', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.dailyCalories,
        value: 1200,
      );
      expect(r.level, HealthLevel.needsAttention);
    });

    test('2000 kcal → normal', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.dailyCalories,
        value: 2000,
      );
      expect(r.level, HealthLevel.normal);
    });

    test('4000 kcal → needsAttention (high)', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.dailyCalories,
        value: 4000,
      );
      expect(r.level, HealthLevel.needsAttention);
    });
  });

  // ── Unknown metric type ────────────────────────────────────────────────────

  group('Unknown metric type', () {
    test('unregistered metric → normal with "not registered" message', () {
      final r = engine.classify(
        metricType: 'unknownMetricXYZ',
        value: 100,
      );
      expect(r.level, HealthLevel.normal);
      expect(r.message, contains('unknownMetricXYZ'));
    });
  });

  // ── classifyAll ───────────────────────────────────────────────────────────

  group('classifyAll', () {
    test('multiple metrics classified at once', () {
      final results = engine.classifyAll({
        RuleSetRegistry.heartRate: 80,
        RuleSetRegistry.spo2: 97,
        RuleSetRegistry.bmi: 22,
      });
      expect(results.length, 3);
      expect(results[RuleSetRegistry.heartRate]!.level, HealthLevel.normal);
      expect(results[RuleSetRegistry.spo2]!.level, HealthLevel.normal);
      expect(results[RuleSetRegistry.bmi]!.level, HealthLevel.normal);
    });
  });

  // ── overallLevel ──────────────────────────────────────────────────────────

  group('overallLevel', () {
    test('all normal → normal', () {
      final classifications = [
        engine.classify(metricType: RuleSetRegistry.heartRate, value: 70),
        engine.classify(metricType: RuleSetRegistry.spo2, value: 98),
      ];
      expect(engine.overallLevel(classifications), HealthLevel.normal);
    });

    test('one highRisk, rest normal → highRisk', () {
      final classifications = [
        engine.classify(metricType: RuleSetRegistry.heartRate, value: 70),
        engine.classify(metricType: RuleSetRegistry.bloodPressureSystolic, value: 145),
      ];
      expect(engine.overallLevel(classifications), HealthLevel.highRisk);
    });

    test('critical present → critical wins', () {
      final classifications = [
        engine.classify(metricType: RuleSetRegistry.heartRate, value: 70),
        engine.classify(metricType: RuleSetRegistry.spo2, value: 85),
        engine.classify(metricType: RuleSetRegistry.bmi, value: 22),
      ];
      expect(engine.overallLevel(classifications), HealthLevel.critical);
    });

    test('empty list → normal', () {
      expect(engine.overallLevel([]), HealthLevel.normal);
    });
  });

  // ── Classification metadata ───────────────────────────────────────────────

  group('Classification metadata', () {
    test('critical heart rate → requiresProfessionalConsultation = true', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.heartRate,
        value: 200,
      );
      expect(r.requiresProfessionalConsultation, isTrue);
      expect(r.level.requiresSafetyNotice, isTrue);
    });

    test('normal → requiresProfessionalConsultation = false', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.heartRate,
        value: 72,
      );
      expect(r.requiresProfessionalConsultation, isFalse);
    });

    test('ruleId is non-null for matched rules', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.heartRate,
        value: 72,
      );
      expect(r.ruleId, isNotNull);
    });

    test('reference is non-null for health rules', () {
      final r = engine.classify(
        metricType: RuleSetRegistry.bloodPressureSystolic,
        value: 120,
      );
      expect(r.reference, isNotNull);
    });
  });
}
