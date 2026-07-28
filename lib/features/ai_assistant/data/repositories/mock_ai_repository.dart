import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/ai_insight_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/suggested_prompt_entity.dart';
import '../../domain/repositories/ai_repository.dart';
import '../templates/prompt_templates.dart';

/// In-memory mock implementation of [AIRepository].
///
/// Produces realistic simulated responses with variable delay.
/// Replace with [GeminiRepository] / [OpenAIRepository] later — zero UI changes.
class MockAIRepository implements AIRepository {
  MockAIRepository();

  final _random = Random();
  final _conversations = <String, ConversationEntity>{};
  final _messages = <String, List<MessageEntity>>{};
  final _readInsights = <String>{};

  // ── Internal helpers ───────────────────────────────────────────────────────

  String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      _random.nextInt(9999).toString().padLeft(4, '0');

  Duration get _thinkingDelay =>
      Duration(milliseconds: 600 + _random.nextInt(900));

  // ── Mock response bank ─────────────────────────────────────────────────────

  static const Map<CoachType, List<String>> _responses = {
    CoachType.general: [
      '''Great question! Here's what you need to know:

**Key Points:**
- Your body is a complex system that responds to consistent habits
- Small, sustainable changes outperform drastic short-term measures
- Track your progress weekly rather than daily for accurate trends

**My Recommendation:**
Start with one change at a time. Whether it's nutrition, sleep, or exercise — **consistency over intensity** is the winning formula.

*Would you like me to create a personalised action plan?*''',
      '''I've analysed your question carefully. Here's my take:

The science is clear — **lifestyle factors** account for up to 80% of your long-term health outcomes. Genetics play a role, but your daily choices matter far more.

**Three steps to start:**
1. Establish a consistent sleep schedule
2. Move your body for at least 30 minutes daily
3. Eat whole foods 80% of the time

What area would you like to focus on first?''',
      '''Excellent! This is something many people wonder about.

**The Research Says:**
Regular health tracking can improve health outcomes by up to **30%**. Awareness is the first step to change.

Here's a simple framework:
- Morning: Check weight and mood (1 min)
- Midday: Log lunch and movement (2 min)
- Evening: Reflect on energy and sleep quality (2 min)

**Remember:** You don't need to be perfect — progress over perfection always wins. 💪''',
    ],

    CoachType.health: [
      '''As your Health Coach, I want to give you an evidence-based answer.

**Understanding Your Vitals:**
Your resting heart rate, blood pressure, and SpO2 levels are windows into your cardiovascular health. Here's what to aim for:

| Metric | Optimal Range |
|--------|--------------|
| Resting Heart Rate | 60–80 bpm |
| Blood Pressure | <120/80 mmHg |
| SpO2 | 95–100% |
| BMI | 18.5–24.9 |

**Action Plan:**
- Log your metrics daily at the same time
- Look for **trends** over 2 weeks, not single readings
- Consult your doctor if any value is consistently out of range

How are your current readings looking?''',
      '''Great health question! Let me break this down medically:

**What Your Body Is Telling You:**

Many health symptoms we dismiss as "normal" are actually signals worth paying attention to. Fatigue, poor sleep, and low energy are often linked to:

1. **Nutritional deficiencies** (iron, B12, Vitamin D)
2. **Hormonal imbalances** (thyroid, cortisol)
3. **Poor sleep architecture** (less deep sleep)
4. **Sedentary lifestyle** reducing circulation

**Immediate Steps:**
- Get a comprehensive blood panel (ask for CBC, thyroid, vitamins)
- Track sleep quality with your device
- Increase daily steps by 2,000 this week

Would you like me to help you prepare questions for your doctor?''',
      '''Here's your health coaching insight:

**Prevention Is Power** ❤️

The most impactful health decisions happen in your 20s–40s, but it's never too late to make positive changes.

**Daily non-negotiables:**
- Sleep 7–9 hours consistently
- Drink at least 2–3 litres of water
- Move for 30+ minutes (walking counts!)
- Eat 5+ servings of vegetables/fruits
- Manage stress with 5 minutes of deep breathing

**The 1% Rule:**
Improve just 1% in each area per week. In one year, you'll be 37× better.

Ready to start tracking? I can help you set up a monitoring plan!''',
    ],

    CoachType.fitness: [
      '''As your Fitness Coach, here's your personalised plan:

**Beginner Strength Programme (4 Weeks)**

**Week 1–2: Foundation**
- Monday: Upper body (3×8 push-ups, 3×10 dumbbell rows)
- Wednesday: Lower body (3×12 squats, 3×10 lunges)
- Friday: Full body (3×10 deadlifts, 3×8 overhead press)

**Week 3–4: Progression**
- Increase weight by 5% or add 2 reps per set
- Add 1 cardio session (20 min moderate intensity)

**Recovery Protocol:**
- 48 hours rest between muscle groups
- Stretch for 10 minutes post-workout
- Prioritise sleep — **muscle grows during rest, not training** 💪

Track your lifts in the Fitness module. Shall I create a full 8-week progression?''',
      '''Let me coach you through this properly:

**Fat Loss & Muscle Retention — The Science:**

Many people make the mistake of crash dieting, which causes muscle loss. Here's how to avoid that:

**Golden Rules:**
1. **Calorie deficit**: 300–500 kcal/day below maintenance
2. **Protein**: 1.6–2.2g per kg of body weight daily
3. **Resistance training**: 3–4× per week minimum
4. **Cardio**: 2–3× per week LISS (low-intensity steady state)

**Weekly Split Example:**
- Mon: Strength (Upper)
- Tue: LISS cardio 35 min
- Wed: Strength (Lower)
- Thu: Rest or yoga
- Fri: Strength (Full body)
- Sat: HIIT 20 min
- Sun: Rest

Need me to calculate your specific macros?''',
      '''Your Fitness Coaching update:

**This Week's Focus: Progressive Overload** 📈

Progressive overload is the #1 principle for continuous improvement. Here's how to apply it:

**3 Ways to Progress:**
1. **More weight** (add 2.5–5kg when you hit the top of your rep range)
2. **More reps** (if you can do 12 reps easily, add more)
3. **Less rest** (reduce rest from 90 sec to 60 sec)

**Track This Week:**
- Record every set, rep, and weight used
- Rate your RPE (Rate of Perceived Exertion) 1–10
- Note sleep quality — it directly affects performance

**Motivational Insight:**
Gym consistency beats gym intensity. Showing up 3× per week for a year beats 6× per week for 2 months. 🏆''',
    ],

    CoachType.nutrition: [
      '''Nutrition Coach here! Let's talk about **optimising your diet**:

**Your Daily Macro Blueprint:**

Based on general activity guidelines, here's a starting point:

| Macro | Amount | Calories |
|-------|--------|---------|
| Protein | 150g | 600 kcal |
| Carbohydrates | 200g | 800 kcal |
| Fat | 65g | 585 kcal |
| **Total** | — | **~1985 kcal** |

**Best Food Sources:**
- **Protein**: Chicken, fish, eggs, Greek yoghurt, legumes
- **Carbs**: Oats, sweet potato, brown rice, quinoa, fruits
- **Fats**: Avocado, nuts, olive oil, salmon

**Timing Tips:**
- Pre-workout: Carbs + moderate protein (1–2 hrs before)
- Post-workout: Protein within 30–60 min
- Before bed: Casein protein or cottage cheese

Want a sample meal plan for your calorie goal?''',
      '''Great nutrition question! Here's evidence-based advice:

**Hydration Guide 💧**

Water needs vary based on:
- Body weight (baseline: 35ml per kg)
- Exercise level (add 500ml per hour of training)
- Climate (hot weather = more needed)
- Diet (high sodium = more water)

**For a 70kg person exercising 1hr:**
- Baseline: 2.45L
- Exercise addition: 0.5L
- **Target: ~3L per day**

**Hydration Signs:**
- ✅ Pale yellow urine = well hydrated
- ⚠️ Dark yellow = drink more water
- 🚫 Brown/orange = severely dehydrated

**Pro Tips:**
1. Drink a full glass upon waking
2. Keep a water bottle visible at your desk
3. Eat water-rich foods (cucumber, watermelon, celery)

Use the Water Tracker to log your intake!''',
      '''**7-Day High-Protein Meal Plan** 🥗

**Daily target: 150g protein, ~1800 kcal**

**Monday:**
- Breakfast: Scrambled eggs (4) + oats with protein powder
- Lunch: Chicken breast salad with quinoa
- Dinner: Salmon fillet with roasted vegetables
- Snack: Greek yoghurt with berries

**Tuesday:**
- Breakfast: Protein smoothie (protein powder, banana, almond milk)
- Lunch: Turkey wrap with avocado
- Dinner: Lean beef stir-fry with brown rice
- Snack: Hard-boiled eggs + almonds

**Wednesday–Sunday:** Rotating similar meals with variation.

**Shopping List Essentials:**
Chicken breast, salmon, eggs, Greek yoghurt, oats, brown rice, sweet potato, broccoli, spinach, almonds

*Log these meals in the Nutrition module for accurate tracking!*''',
    ],

    CoachType.lifestyle: [
      '''Welcome to your Lifestyle Coaching session! 🌿

**Building Your Perfect Morning Routine:**

The first 60 minutes of your day set the tone for everything else. Here's a research-backed routine:

**6:00 — Wake & Hydrate**
Drink 500ml of water immediately. Your body is dehydrated after 8 hours.

**6:05 — Movement (10 min)**
Stretching, yoga, or a short walk. Activate your body, not your phone.

**6:15 — Mindfulness (5 min)**
Box breathing: inhale 4s → hold 4s → exhale 4s → hold 4s. Repeat 4 times.

**6:20 — Nourish (10 min)**
A high-protein breakfast. Avoid sugar spikes in the morning.

**6:30 — Plan Your Day (5 min)**
Write 3 priorities. Know your "big rock" task for today.

**6:35 — Learn (15 min)**
Read, podcast, or course — 15 minutes daily = 91 hours per year.

Would you like me to help personalise this to your schedule?''',
      '''**Lifestyle Coaching: Habit Stacking** ✅

Habit stacking is the most powerful strategy for building new habits — and it's backed by neuroscience.

**The Formula:**
`After [CURRENT HABIT], I will [NEW HABIT]`

**Examples for Your Health Goals:**
- "After I brew my morning coffee, I will drink a full glass of water."
- "After I sit at my desk, I will do 2 minutes of stretching."
- "After I brush my teeth at night, I will log tomorrow's workout."
- "After dinner, I will take a 10-minute walk."

**Why It Works:**
Your brain creates neural pathways by linking new behaviours to existing ones. No willpower needed — just repetition.

**Your 7-Day Challenge:**
Pick ONE habit stack from above and do it every single day this week. Just one. Mastery beats multitasking.

Ready to commit to one?''',
      '''**Work-Life Health Balance Guide** 🏡

Many of us sacrifice health for productivity. Here's how to reclaim both:

**The Energy Management Framework:**

**Physical Energy (Body)**
- Sleep: Protect 7–8 hours like a meeting you cannot miss
- Move: Micro-workouts during the day (2-min walk per hour)
- Fuel: Prep meals on Sunday to avoid stress eating

**Mental Energy (Mind)**
- Deep work blocks: 90 minutes of focused work, then 20 min break
- Digital sunset: No screens after 9pm
- Nature time: 20 minutes outdoors daily reduces cortisol by 20%

**Social Energy (Connection)**
- Schedule social activities like work appointments
- Say no to draining commitments guilt-free
- Invest in 2–3 deep relationships

**The Rule:** Your health IS your productivity. You cannot pour from an empty cup. 💚''',
    ],

    CoachType.habit: [
      '''**Habit Coaching: Your Behaviour Change Blueprint** ✅

Building habits is a skill, not a talent. Here's the science:

**The Habit Loop (James Clear):**
`Cue → Craving → Response → Reward`

**Breaking It Down:**
1. **Cue**: What triggers the habit? (time, place, person, emotion)
2. **Craving**: What do you want? (energy, comfort, progress)
3. **Response**: The actual habit (exercise, eating, journaling)
4. **Reward**: What you get (endorphins, satisfaction, data)

**Your 4-Week Habit Formula:**

**Week 1**: Start stupidly small. 2-minute versions only.
**Week 2**: Add implementation intention ("When X happens, I will Y")
**Week 3**: Add environment design (make good habits obvious, easy)
**Week 4**: Track your streak and reward milestones

**Remember:** You don't rise to your goals — you fall to your systems.

What habit are we building today?''',
      '''**30-Day Habit Tracking System** 📊

Here's a science-backed system that actually works:

**The Three-Column Method:**
| Day | Did I do it? | Quality (1–5) |
|-----|-------------|---------------|
| Day 1 | ✅ | 4 |
| Day 2 | ✅ | 3 |
| Day 3 | ❌ | — |
| Day 4 | ✅ | 4 |

**Key Rules:**
- **Never miss twice** — one miss is an accident, two is a pattern
- **Measure effort**, not perfection
- **Celebrate** small wins immediately

**Identity-Based Habits:**
Instead of "I want to work out more" → "I am someone who prioritises their health."

Every time you exercise, you cast a vote for the identity of a healthy person. After enough votes, that **becomes** who you are.

**This Week's Action:**
Choose ONE habit. Set a 21-day streak goal. Start today. 🎯''',
    ],
  };

  String _getRandomResponse(CoachType coachType) {
    final list = _responses[coachType] ?? _responses[CoachType.general]!;
    return list[_random.nextInt(list.length)];
  }

  // ── AIRepository Implementation ────────────────────────────────────────────

  @override
  Future<String> sendMessage(
    List<MessageEntity> history,
    String userMessage, {
    CoachType coachType = CoachType.general,
  }) async {
    await Future.delayed(_thinkingDelay);
    return _getRandomResponse(coachType);
  }

  @override
  Future<Stream<String>> sendMessageStream(
    List<MessageEntity> history,
    String userMessage, {
    CoachType coachType = CoachType.general,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final response = _getRandomResponse(coachType);
    final words = response.split(' ');

    return Stream.fromIterable(words).asyncMap((word) async {
      await Future.delayed(Duration(milliseconds: 35 + _random.nextInt(40)));
      return '$word ';
    });
  }

  @override
  Future<String> generateTitle(List<MessageEntity> messages) async {
    if (messages.isEmpty) return 'New Conversation';
    final first = messages
        .firstWhere((m) => m.isUser, orElse: () => messages.first)
        .content;
    final words = first.split(' ').take(6).join(' ');
    return words.length > 40 ? '${words.substring(0, 37)}…' : words;
  }

  // ── Conversations ──────────────────────────────────────────────────────────

  @override
  Future<List<ConversationEntity>> getConversations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _conversations.values
        .where((c) => c.status != ConversationStatus.deleted)
        .toList()
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  @override
  Future<ConversationEntity?> getConversation(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final convo = _conversations[id];
    if (convo == null) return null;
    final msgs = _messages[id] ?? [];
    return convo.copyWith(messages: msgs);
  }

  @override
  Future<ConversationEntity> createConversation({
    String? title,
    CoachType coachType = CoachType.general,
  }) async {
    final id = _generateId();
    final now = DateTime.now();
    final convo = ConversationEntity(
      id: id,
      title: title ?? 'New Conversation',
      messages: [],
      createdAt: now,
      updatedAt: now,
      coachType: coachType,
    );
    _conversations[id] = convo;
    _messages[id] = [];
    return convo;
  }

  @override
  Future<void> updateConversation(ConversationEntity conversation) async {
    _conversations[conversation.id] = conversation;
  }

  @override
  Future<void> deleteConversation(String id) async {
    final existing = _conversations[id];
    if (existing != null) {
      _conversations[id] = existing.copyWith(
        status: ConversationStatus.deleted,
      );
    }
  }

  @override
  Future<void> clearAllConversations() async {
    _conversations.clear();
    _messages.clear();
  }

  // ── Prompts ────────────────────────────────────────────────────────────────

  @override
  Future<List<SuggestedPromptEntity>> getSuggestedPrompts({
    PromptCategory? category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return category == null
        ? PromptTemplates.all
        : PromptTemplates.byCategory(category);
  }

  // ── Insights ───────────────────────────────────────────────────────────────

  @override
  Future<List<AIInsightEntity>> getInsights() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _buildInsights();
  }

  @override
  Future<void> markInsightRead(String insightId) async {
    _readInsights.add(insightId);
  }

  List<AIInsightEntity> _buildInsights() {
    final now = DateTime.now();
    return [
      AIInsightEntity(
        id: 'ins_sleep_01',
        title: 'Your sleep has been declining',
        body:
            'You\'ve averaged **6.2 hours** this week, below your 7.5-hour goal. '
            'Consistent sleep below 7 hours is linked to higher cortisol, '
            'reduced muscle recovery, and increased appetite. '
            'Try going to bed 30 minutes earlier tonight.',
        type: InsightType.sleep,
        priority: InsightPriority.high,
        timestamp: now.subtract(const Duration(hours: 2)),
        metric: 'Avg Sleep',
        metricValue: '6.2',
        metricUnit: 'hrs',
        trend: InsightTrend.down,
        actionLabel: 'View Sleep Data',
        actionRoute: '/health/sleep',
      ),
      AIInsightEntity(
        id: 'ins_hr_01',
        title: 'Resting heart rate improving',
        body:
            'Your resting heart rate has dropped from **78 bpm** to **72 bpm** '
            'over the past 3 weeks. This indicates improving cardiovascular fitness. '
            'Keep up your current workout routine — it\'s working!',
        type: InsightType.heartRate,
        priority: InsightPriority.low,
        timestamp: now.subtract(const Duration(hours: 5)),
        metric: 'Resting HR',
        metricValue: '72',
        metricUnit: 'bpm',
        trend: InsightTrend.down,
        actionLabel: 'View Heart Rate',
        actionRoute: '/health/heart-rate',
      ),
      AIInsightEntity(
        id: 'ins_water_01',
        title: 'Hydration needs attention',
        body:
            'You\'ve only reached your water goal on **2 out of 7 days** this week. '
            'Dehydration by just 2% reduces cognitive performance by 10% and '
            'physical performance by up to 20%. '
            'Set hourly reminders to drink 200ml.',
        type: InsightType.water,
        priority: InsightPriority.medium,
        timestamp: now.subtract(const Duration(hours: 1)),
        metric: 'Hydration Goal',
        metricValue: '29',
        metricUnit: '%',
        trend: InsightTrend.stable,
        actionLabel: 'Log Water',
        actionRoute: '/nutrition/water',
      ),
      AIInsightEntity(
        id: 'ins_workout_01',
        title: 'Workout streak: 5 days!',
        body:
            'Amazing consistency — you\'ve worked out **5 days in a row**! '
            'Your progressive overload is on track. Consider a light recovery '
            'session today (yoga or walking) to avoid overtraining.',
        type: InsightType.achievement,
        priority: InsightPriority.low,
        timestamp: now.subtract(const Duration(minutes: 30)),
        metric: 'Workout Streak',
        metricValue: '5',
        metricUnit: 'days',
        trend: InsightTrend.up,
        actionLabel: 'View Workouts',
        actionRoute: '/workouts',
      ),
      AIInsightEntity(
        id: 'ins_nutrition_01',
        title: 'Protein intake below target',
        body:
            'Your average protein intake this week is **98g/day**, below your '
            '**150g goal**. Low protein slows muscle recovery and increases hunger. '
            'Add a Greek yoghurt snack and an extra serving of chicken or eggs daily.',
        type: InsightType.nutrition,
        priority: InsightPriority.medium,
        timestamp: now.subtract(const Duration(hours: 3)),
        metric: 'Avg Protein',
        metricValue: '98',
        metricUnit: 'g',
        trend: InsightTrend.stable,
        actionLabel: 'View Nutrition',
        actionRoute: '/nutrition',
      ),
      AIInsightEntity(
        id: 'ins_weekly_01',
        title: 'Weekly summary: Strong week!',
        body:
            'This week you completed **4 workouts**, hit your calorie goal '
            '**5/7 days**, and walked an average of **8,240 steps/day**. '
            'Your nutrition score improved by **12 points**. '
            'Focus area for next week: improve sleep consistency.',
        type: InsightType.weekly,
        priority: InsightPriority.low,
        timestamp: now.subtract(const Duration(days: 1)),
        trend: InsightTrend.up,
        actionLabel: 'Full Report',
        actionRoute: '/workouts/analytics',
      ),
      AIInsightEntity(
        id: 'ins_alert_01',
        title: 'Elevated resting heart rate detected',
        body:
            'Your resting heart rate was **94 bpm** this morning, significantly '
            'above your baseline. This can indicate stress, illness, dehydration, '
            'or overtraining. Consider a rest day and ensure adequate hydration.',
        type: InsightType.alert,
        priority: InsightPriority.critical,
        timestamp: now.subtract(const Duration(minutes: 10)),
        metric: 'Resting HR',
        metricValue: '94',
        metricUnit: 'bpm',
        trend: InsightTrend.up,
        actionLabel: 'Check Heart Rate',
        actionRoute: '/health/heart-rate',
      ),
      AIInsightEntity(
        id: 'ins_achieve_01',
        title: '🏆 10kg weight loss milestone!',
        body:
            'Congratulations! You\'ve lost **10kg** since starting HealthFit Heal. '
            'This is a remarkable achievement that reflects weeks of discipline '
            'in both training and nutrition. Your BMI has moved from 28.4 to 25.1. '
            'Keep this momentum going!',
        type: InsightType.achievement,
        priority: InsightPriority.low,
        timestamp: now.subtract(const Duration(days: 2)),
        metric: 'Weight Lost',
        metricValue: '10',
        metricUnit: 'kg',
        trend: InsightTrend.down,
        actionLabel: 'View Progress',
        actionRoute: '/nutrition/weight',
      ),
    ];
  }

  // ── Seed demo conversations ────────────────────────────────────────────────

  /// Populates a few demo conversations for first-run UX.
  void seedDemoData() {
    if (_conversations.isNotEmpty) return;

    final now = DateTime.now();

    // Demo conversation 1
    final id1 = 'demo_01';
    _conversations[id1] = ConversationEntity(
      id: id1,
      title: 'Beginner strength training plan',
      messages: [],
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(days: 2)),
      coachType: CoachType.fitness,
      isPinned: true,
      messageCount: 4,
    );
    _messages[id1] = [
      MessageEntity(
        id: 'm1_01',
        conversationId: id1,
        role: MessageRole.user,
        content: 'Design a 4-week beginner strength training plan for me.',
        timestamp: now.subtract(const Duration(days: 2, hours: 2)),
      ),
      MessageEntity(
        id: 'm1_02',
        conversationId: id1,
        role: MessageRole.assistant,
        content: _responses[CoachType.fitness]![0],
        timestamp: now.subtract(const Duration(days: 2, hours: 1, minutes: 58)),
      ),
    ];

    // Demo conversation 2
    final id2 = 'demo_02';
    _conversations[id2] = ConversationEntity(
      id: id2,
      title: 'How much protein do I need daily?',
      messages: [],
      createdAt: now.subtract(const Duration(hours: 8)),
      updatedAt: now.subtract(const Duration(hours: 8)),
      coachType: CoachType.nutrition,
      messageCount: 2,
    );
    _messages[id2] = [
      MessageEntity(
        id: 'm2_01',
        conversationId: id2,
        role: MessageRole.user,
        content: 'How much protein do I need to build muscle effectively?',
        timestamp: now.subtract(const Duration(hours: 8)),
      ),
      MessageEntity(
        id: 'm2_02',
        conversationId: id2,
        role: MessageRole.assistant,
        content: _responses[CoachType.nutrition]![0],
        timestamp: now.subtract(const Duration(hours: 7, minutes: 58)),
      ),
    ];

    // Demo conversation 3
    final id3 = 'demo_03';
    _conversations[id3] = ConversationEntity(
      id: id3,
      title: 'Morning routine tips',
      messages: [],
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now.subtract(const Duration(hours: 1)),
      coachType: CoachType.lifestyle,
      messageCount: 2,
    );
    _messages[id3] = [
      MessageEntity(
        id: 'm3_01',
        conversationId: id3,
        role: MessageRole.user,
        content: 'How do I build a consistent morning routine?',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      MessageEntity(
        id: 'm3_02',
        conversationId: id3,
        role: MessageRole.assistant,
        content: _responses[CoachType.lifestyle]![0],
        timestamp: now.subtract(const Duration(minutes: 58)),
      ),
    ];
  }
}
