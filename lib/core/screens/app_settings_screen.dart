import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/provider/theme_provider.dart';

/// Shared across all roles — dark mode, language, display preferences.
/// Navigate here via context.push('/app-settings') from any settings screen.
class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  String _language = 'English';
  bool _compactMode = false;

  static const _languages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('App Settings', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Appearance ──────────────────────────────────────────
            _sectionLabel('Appearance'),
            _card([
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.textDark.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: const Icon(
                        Icons.dark_mode_outlined,
                        color: AppColors.textDark,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Dark Mode', style: AppTextStyles.labelBold),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md + AppSpacing.xs + 18,
                    top: 2,
                  ),
                  child: Text(
                    'Coming soon — stay tuned!',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLight,
                value: isDark,
                onChanged: (val) {
                  ref.read(themeProvider.notifier).state =
                      val; //for darkmode toggle button(on/off)
                },
                // TODO: Implement theme switching via Riverpod ThemeProvider
              ),
              const Divider(height: 1, color: AppColors.border),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: const Icon(
                        Icons.view_compact_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Compact Mode', style: AppTextStyles.labelBold),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md + AppSpacing.xs + 18,
                    top: 2,
                  ),
                  child: Text(
                    'Reduce spacing in lists',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLight,
                value: _compactMode,
                onChanged: (val) => setState(() => _compactMode = val),
              ),
            ]),

            const SizedBox(height: AppSpacing.lg),

            // ── Language ─────────────────────────────────────────────
            _sectionLabel('Language'),
            _card([
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Display Language',
                        style: AppTextStyles.labelBold,
                      ),
                    ),
                    DropdownButton<String>(
                      dropdownColor: AppColors.bgLight,
                      value: _language,
                      underline: const SizedBox(),
                      icon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.textMuted,
                      ),
                      style: AppTextStyles.bodyMedium,
                      items: _languages
                          .map(
                            (l) => DropdownMenuItem(
                              value: l,
                              child: Text(l, style: AppTextStyles.bodyMedium),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _language = v);
                      },
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: AppSpacing.xxl),

            // Version info
            Center(
              child: Text(
                'TinySteps v1.0.0 · Sunrise Edition',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      label.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textMuted,
      ),
    ),
  );

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadows.card,
    ),
    child: Column(children: children),
  );
}
