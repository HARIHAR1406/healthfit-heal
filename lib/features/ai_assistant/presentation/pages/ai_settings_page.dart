import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../providers/ai_providers.dart';
import '../providers/ai_state.dart';

/// AI Settings page — provider, temperature, response length,
/// voice, streaming, history, data privacy, and danger zone.
class AISettingsPage extends ConsumerWidget {
  const AISettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(aiSettingsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          'AI Settings',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── AI Provider ──────────────────────────────────────────────────
          _SectionCard(
            isDark: isDark,
            title: '🤖 AI Provider',
            children: [
              _DropdownTile<AIProviderOption>(
                label: 'Provider',
                subtitle:
                    settings.provider.requiresApiKey ? 'API key required' : 'No API key needed',
                value: settings.provider,
                items: AIProviderOption.values,
                itemLabel: (p) => p.label,
                onChanged: (p) =>
                    ref.read(aiSettingsProvider.notifier).setProvider(p!),
                isDark: isDark,
              ),
              if (settings.provider.requiresApiKey)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Configure your API key in .env to use ${settings.provider.label}.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Response Settings ─────────────────────────────────────────────
          _SectionCard(
            isDark: isDark,
            title: '⚙️ Response Settings',
            children: [
              // Temperature
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Creativity (Temperature)',
                          style: AppTypography.titleSmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          settings.temperature.toStringAsFixed(1),
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Lower = more precise, Higher = more creative',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    Slider(
                      value: settings.temperature,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          ref.read(aiSettingsProvider.notifier).setTemperature(v),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Response length
              _DropdownTile<ResponseLength>(
                label: 'Response Length',
                subtitle: 'How detailed should responses be?',
                value: settings.responseLength,
                items: ResponseLength.values,
                itemLabel: (l) => l.label,
                onChanged: (l) => ref
                    .read(aiSettingsProvider.notifier)
                    .setResponseLength(l!),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Features ─────────────────────────────────────────────────────
          _SectionCard(
            isDark: isDark,
            title: '✨ Features',
            children: [
              _SwitchTile(
                label: 'Streaming Responses',
                subtitle: 'Show responses word by word',
                value: settings.streamingEnabled,
                onChanged: (v) =>
                    ref.read(aiSettingsProvider.notifier).toggleStreaming(),
                isDark: isDark,
                icon: Icons.stream_rounded,
                iconColor: const Color(0xFF6C63FF),
              ),
              const Divider(height: 1),
              _SwitchTile(
                label: 'Voice Input',
                subtitle: 'Speak your questions (coming soon)',
                value: settings.voiceEnabled,
                onChanged: null, // Disabled until implemented
                isDark: isDark,
                icon: Icons.mic_rounded,
                iconColor: const Color(0xFFFF6BB5),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Soon',
                      style: AppTypography.captionText.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Data & Privacy ────────────────────────────────────────────────
          _SectionCard(
            isDark: isDark,
            title: '🔒 Data & Privacy',
            children: [
              _SwitchTile(
                label: 'Save Chat History',
                subtitle: 'Keep conversations between sessions',
                value: settings.saveHistory,
                onChanged: (_) =>
                    ref.read(aiSettingsProvider.notifier).toggleSaveHistory(),
                isDark: isDark,
                icon: Icons.history_rounded,
                iconColor: const Color(0xFF00B4D8),
              ),
              const Divider(height: 1),
              _SwitchTile(
                label: 'Share Data for Improvement',
                subtitle: 'Help improve AI responses (anonymous)',
                value: settings.shareData,
                onChanged: (_) =>
                    ref.read(aiSettingsProvider.notifier).toggleShareData(),
                isDark: isDark,
                icon: Icons.share_rounded,
                iconColor: const Color(0xFF4CAF50),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── About ─────────────────────────────────────────────────────────
          _SectionCard(
            isDark: isDark,
            title: 'ℹ️ About',
            children: [
              _InfoTile(
                label: 'AI Module Version',
                value: '1.0.0',
                isDark: isDark,
              ),
              const Divider(height: 1),
              _InfoTile(
                label: 'Architecture',
                value: 'Provider-agnostic (swap-ready)',
                isDark: isDark,
              ),
              const Divider(height: 1),
              _InfoTile(
                label: 'Future Providers',
                value: 'Gemini · OpenAI · Vertex AI · Azure',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Danger Zone ───────────────────────────────────────────────────
          _SectionCard(
            isDark: isDark,
            title: '⚠️ Danger Zone',
            borderColor: AppColors.error.withOpacity(0.3),
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded,
                    color: AppColors.error),
                title: Text(
                  'Clear All Chat History',
                  style: AppTypography.titleSmall
                      .copyWith(color: AppColors.error),
                ),
                subtitle: Text(
                  'Permanently delete all conversations',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                onTap: () => _confirmClearAll(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
            'This will delete all conversations permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(conversationListProvider.notifier).clearAll();
            },
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.children,
    this.borderColor,
  });

  final bool isDark;
  final String title;
  final List<Widget> children;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.xs, bottom: AppSpacing.xs),
          child: Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: borderColor ??
                  (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.15)),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
    required this.icon,
    required this.iconColor,
    this.trailing,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label, style: AppTypography.titleSmall),
      subtitle: trailing != null
          ? Row(children: [
              Expanded(
                child: Text(subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    )),
              ),
              trailing!,
            ])
          : Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  const _DropdownTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.isDark,
  });

  final String label;
  final String subtitle;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    )),
                Text(subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    )),
              ],
            ),
          ),
          DropdownButton<T>(
            value: value,
            items: items
                .map((i) => DropdownMenuItem<T>(
                      value: i,
                      child: Text(itemLabel(i),
                          style: AppTypography.bodySmall),
                    ))
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox.shrink(),
            dropdownColor:
                isDark ? const Color(0xFF1A1F3A) : Colors.white,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.isDark,
  });
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: AppTypography.titleSmall),
      trailing: Text(
        value,
        style: AppTypography.bodySmall.copyWith(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
