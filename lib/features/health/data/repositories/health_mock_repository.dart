import '../../domain/entities/bmi_entity.dart';
import '../../domain/entities/blood_pressure_entity.dart';
import '../../domain/entities/blood_sugar_entity.dart';
import '../../domain/entities/health_dashboard_entity.dart';
import '../../domain/entities/health_record_entity.dart';
import '../../domain/entities/heart_rate_entity.dart';
import '../../domain/entities/spo2_entity.dart';
import '../../domain/repositories/health_repository.dart';

/// In-memory mock repository with realistic clinical fixture data.
///
/// Swap for [HealthRepositoryImpl] (Dio-backed) when backend is ready.
class HealthMockRepository implements HealthRepository {
  // Track mutable readings so "Add Reading" works during the session.
  List<BpReading> _bpHistory = [];
  List<SugarReading> _sugarHistory = [];
  List<Spo2Reading> _spo2History = [];

  @override
  Future<HealthDashboardEntity> getDashboard() async {
    await Future.delayed(const Duration(milliseconds: 700));
    _initHistories();
    return _build();
  }

  @override
  Future<HealthDashboardEntity> refresh() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _build();
  }

  @override
  Future<HealthDashboardEntity> addBpReading({
    required int systolic,
    required int diastolic,
    int? pulse,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _bpHistory.insert(
      0,
      BpReading(
        id: 'bp_new_${DateTime.now().millisecondsSinceEpoch}',
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        timestamp: DateTime.now(),
        notes: notes,
      ),
    );
    return _build();
  }

  @override
  Future<HealthDashboardEntity> addSugarReading({
    required double value,
    required BloodSugarType type,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _sugarHistory.insert(
      0,
      SugarReading(
        id: 'sg_new_${DateTime.now().millisecondsSinceEpoch}',
        value: value,
        type: type,
        timestamp: DateTime.now(),
        notes: notes,
      ),
    );
    return _build();
  }

  @override
  Future<HealthDashboardEntity> addSpo2Reading({
    required int percentage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _spo2History.insert(
      0,
      Spo2Reading(
        id: 'sp_new_${DateTime.now().millisecondsSinceEpoch}',
        percentage: percentage,
        timestamp: DateTime.now(),
      ),
    );
    return _build();
  }

  // ── Initialiser ───────────────────────────────────────────────────────────

  void _initHistories() {
    if (_bpHistory.isNotEmpty) return; // Already initialised
    _bpHistory = _defaultBpHistory();
    _sugarHistory = _defaultSugarHistory();
    _spo2History = _defaultSpo2History();
  }

  // ── Builder ───────────────────────────────────────────────────────────────

  HealthDashboardEntity _build() {
    return HealthDashboardEntity(
      healthScore: 82,
      healthStatus: 'Good',
      bmi: _buildBmi(),
      heartRate: _buildHeartRate(),
      bloodPressure: _buildBloodPressure(),
      bloodSugar: _buildBloodSugar(),
      spo2: _buildSpo2(),
      recentRecords: _buildMedicalRecords().take(5).toList(),
      historyItems: _buildHistoryItems(),
      lastUpdated: DateTime.now(),
    );
  }

  // ── BMI ───────────────────────────────────────────────────────────────────

  BmiEntity _buildBmi() {
    const heightCm = 172.0;
    const weightKg = 70.0;
    final bmiValue = BmiEntity.calculateMetric(
      heightCm: heightCm,
      weightKg: weightKg,
    );
    final now = DateTime.now();

    return BmiEntity(
      id: 'bmi_001',
      value: bmiValue,
      heightCm: heightCm,
      weightKg: weightKg,
      category: BmiEntity.categoryForValue(bmiValue),
      measuredAt: now,
      history: [
        BmiHistoryEntry(
          value: 23.7,
          heightCm: heightCm,
          weightKg: 70.2,
          measuredAt: now.subtract(const Duration(days: 30)),
        ),
        BmiHistoryEntry(
          value: 24.1,
          heightCm: heightCm,
          weightKg: 71.3,
          measuredAt: now.subtract(const Duration(days: 60)),
        ),
        BmiHistoryEntry(
          value: 24.9,
          heightCm: heightCm,
          weightKg: 73.5,
          measuredAt: now.subtract(const Duration(days: 90)),
        ),
        BmiHistoryEntry(
          value: 25.3,
          heightCm: heightCm,
          weightKg: 74.8,
          measuredAt: now.subtract(const Duration(days: 120)),
        ),
      ],
    );
  }

  // ── Heart Rate ────────────────────────────────────────────────────────────

  HeartRateEntity _buildHeartRate() {
    final now = DateTime.now();
    final history = List.generate(
      14,
      (i) => HeartRateReading(
        bpm: 68 + (i % 5) * 2,
        timestamp: now.subtract(Duration(hours: i * 4)),
        context: HeartRateContext.resting,
      ),
    );

    return HeartRateEntity(
      id: 'hr_001',
      currentBpm: 72,
      context: HeartRateContext.resting,
      status: HeartRateEntity.statusForBpm(72),
      dailyAvg: 74,
      weeklyAvg: 71,
      history: history,
      weeklyData: const [
        HeartRateDailyAvg(dayLabel: 'Mon', avgBpm: 70),
        HeartRateDailyAvg(dayLabel: 'Tue', avgBpm: 73),
        HeartRateDailyAvg(dayLabel: 'Wed', avgBpm: 68),
        HeartRateDailyAvg(dayLabel: 'Thu', avgBpm: 75),
        HeartRateDailyAvg(dayLabel: 'Fri', avgBpm: 72),
        HeartRateDailyAvg(dayLabel: 'Sat', avgBpm: 69),
        HeartRateDailyAvg(dayLabel: 'Sun', avgBpm: 74),
      ],
      lastUpdated: now,
    );
  }

  // ── Blood Pressure ────────────────────────────────────────────────────────

  BloodPressureEntity _buildBloodPressure() {
    final history = _bpHistory.isNotEmpty ? _bpHistory : _defaultBpHistory();
    return BloodPressureEntity(
      id: 'bp_001',
      latestReading: history.first,
      history: history,
    );
  }

  List<BpReading> _defaultBpHistory() {
    final now = DateTime.now();
    return [
      BpReading(
        id: 'bp_01',
        systolic: 118,
        diastolic: 76,
        pulse: 72,
        timestamp: now,
      ),
      BpReading(
        id: 'bp_02',
        systolic: 122,
        diastolic: 78,
        pulse: 70,
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      BpReading(
        id: 'bp_03',
        systolic: 120,
        diastolic: 80,
        pulse: 74,
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      BpReading(
        id: 'bp_04',
        systolic: 125,
        diastolic: 82,
        pulse: 76,
        timestamp: now.subtract(const Duration(days: 3)),
      ),
      BpReading(
        id: 'bp_05',
        systolic: 119,
        diastolic: 77,
        pulse: 71,
        timestamp: now.subtract(const Duration(days: 4)),
      ),
      BpReading(
        id: 'bp_06',
        systolic: 117,
        diastolic: 75,
        pulse: 69,
        timestamp: now.subtract(const Duration(days: 5)),
      ),
      BpReading(
        id: 'bp_07',
        systolic: 121,
        diastolic: 79,
        pulse: 73,
        timestamp: now.subtract(const Duration(days: 6)),
      ),
    ];
  }

  // ── Blood Sugar ───────────────────────────────────────────────────────────

  BloodSugarEntity _buildBloodSugar() {
    final history =
        _sugarHistory.isNotEmpty ? _sugarHistory : _defaultSugarHistory();
    final fasting =
        history.where((r) => r.type == BloodSugarType.fasting).firstOrNull;
    final postMeal =
        history.where((r) => r.type == BloodSugarType.postMeal).firstOrNull;

    return BloodSugarEntity(
      id: 'sg_001',
      latestFasting: fasting,
      latestPostMeal: postMeal,
      history: history,
    );
  }

  List<SugarReading> _defaultSugarHistory() {
    final now = DateTime.now();
    return [
      SugarReading(
        id: 'sg_01',
        value: 92,
        type: BloodSugarType.fasting,
        timestamp: now,
      ),
      SugarReading(
        id: 'sg_02',
        value: 128,
        type: BloodSugarType.postMeal,
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      SugarReading(
        id: 'sg_03',
        value: 88,
        type: BloodSugarType.fasting,
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      SugarReading(
        id: 'sg_04',
        value: 135,
        type: BloodSugarType.postMeal,
        timestamp: now.subtract(const Duration(days: 1, hours: 4)),
      ),
      SugarReading(
        id: 'sg_05',
        value: 95,
        type: BloodSugarType.fasting,
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      SugarReading(
        id: 'sg_06',
        value: 122,
        type: BloodSugarType.postMeal,
        timestamp: now.subtract(const Duration(days: 2, hours: 3)),
      ),
      SugarReading(
        id: 'sg_07',
        value: 91,
        type: BloodSugarType.fasting,
        timestamp: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  // ── SpO2 ──────────────────────────────────────────────────────────────────

  Spo2Entity _buildSpo2() {
    final history =
        _spo2History.isNotEmpty ? _spo2History : _defaultSpo2History();
    return Spo2Entity(
      id: 'sp_001',
      currentPercentage: history.first.percentage,
      history: history,
    );
  }

  List<Spo2Reading> _defaultSpo2History() {
    final now = DateTime.now();
    return [
      Spo2Reading(id: 'sp_01', percentage: 98, timestamp: now),
      Spo2Reading(
        id: 'sp_02',
        percentage: 97,
        timestamp: now.subtract(const Duration(hours: 6)),
      ),
      Spo2Reading(
        id: 'sp_03',
        percentage: 98,
        timestamp: now.subtract(const Duration(hours: 12)),
      ),
      Spo2Reading(
        id: 'sp_04',
        percentage: 96,
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      Spo2Reading(
        id: 'sp_05',
        percentage: 99,
        timestamp: now.subtract(const Duration(days: 1, hours: 12)),
      ),
      Spo2Reading(
        id: 'sp_06',
        percentage: 97,
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      Spo2Reading(
        id: 'sp_07',
        percentage: 98,
        timestamp: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  // ── Medical Records ───────────────────────────────────────────────────────

  List<HealthRecordEntity> _buildMedicalRecords() {
    final now = DateTime.now();
    return [
      HealthRecordEntity(
        id: 'rec_01',
        title: 'Complete Blood Count (CBC)',
        type: HealthRecordType.labReport,
        date: now.subtract(const Duration(days: 7)),
        doctorName: 'Dr. Priya Sharma',
        hospitalName: 'Apollo Clinic',
        tags: ['Blood', 'Routine'],
        hasAttachment: true,
        notes: 'All values within normal range.',
      ),
      HealthRecordEntity(
        id: 'rec_02',
        title: 'Metformin 500mg Prescription',
        type: HealthRecordType.prescription,
        date: now.subtract(const Duration(days: 14)),
        doctorName: 'Dr. Rajesh Kumar',
        hospitalName: 'Fortis Hospital',
        tags: ['Diabetes', 'Medication'],
        hasAttachment: false,
        notes: 'Take once daily with breakfast.',
      ),
      HealthRecordEntity(
        id: 'rec_03',
        title: 'Chest X-Ray',
        type: HealthRecordType.imaging,
        date: now.subtract(const Duration(days: 30)),
        doctorName: 'Dr. Anita Menon',
        hospitalName: 'Manipal Hospital',
        tags: ['Chest', 'X-Ray'],
        hasAttachment: true,
      ),
      HealthRecordEntity(
        id: 'rec_04',
        title: 'Cardiology Consultation',
        type: HealthRecordType.consultation,
        date: now.subtract(const Duration(days: 45)),
        doctorName: 'Dr. Vikram Nair',
        hospitalName: 'Narayana Health',
        tags: ['Cardiology', 'Heart'],
        hasAttachment: false,
        notes: 'ECG normal. Follow up in 3 months.',
      ),
      HealthRecordEntity(
        id: 'rec_05',
        title: 'Lipid Profile Test',
        type: HealthRecordType.labReport,
        date: now.subtract(const Duration(days: 60)),
        doctorName: 'Dr. Priya Sharma',
        hospitalName: 'Apollo Clinic',
        tags: ['Cholesterol', 'Blood'],
        hasAttachment: true,
      ),
      HealthRecordEntity(
        id: 'rec_06',
        title: 'Influenza Vaccine',
        type: HealthRecordType.vaccination,
        date: now.subtract(const Duration(days: 90)),
        hospitalName: 'Primary Health Centre',
        tags: ['Vaccine', 'Flu'],
      ),
    ];
  }

  // ── Health History ─────────────────────────────────────────────────────────

  List<HealthHistoryItem> _buildHistoryItems() {
    final now = DateTime.now();
    return [
      HealthHistoryItem(
        id: 'h_01',
        type: HealthRecordType.labReport,
        title: 'Blood Pressure Recorded',
        value: '118/76',
        unit: 'mmHg',
        timestamp: now,
      ),
      HealthHistoryItem(
        id: 'h_02',
        type: HealthRecordType.labReport,
        title: 'Blood Sugar (Fasting)',
        value: '92',
        unit: 'mg/dL',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      HealthHistoryItem(
        id: 'h_03',
        type: HealthRecordType.labReport,
        title: 'SpO₂ Reading',
        value: '98',
        unit: '%',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      HealthHistoryItem(
        id: 'h_04',
        type: HealthRecordType.consultation,
        title: 'Heart Rate Check',
        value: '72',
        unit: 'bpm',
        timestamp: now.subtract(const Duration(hours: 8)),
      ),
      HealthHistoryItem(
        id: 'h_05',
        type: HealthRecordType.labReport,
        title: 'Blood Pressure Recorded',
        value: '122/78',
        unit: 'mmHg',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      HealthHistoryItem(
        id: 'h_06',
        type: HealthRecordType.labReport,
        title: 'Blood Sugar (Post-Meal)',
        value: '128',
        unit: 'mg/dL',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      HealthHistoryItem(
        id: 'h_07',
        type: HealthRecordType.labReport,
        title: 'BMI Calculated',
        value: '23.7',
        unit: 'kg/m²',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      HealthHistoryItem(
        id: 'h_08',
        type: HealthRecordType.labReport,
        title: 'Blood Pressure Recorded',
        value: '120/80',
        unit: 'mmHg',
        timestamp: now.subtract(const Duration(days: 2, hours: 4)),
      ),
    ];
  }
}
