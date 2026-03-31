import 'package:flutter/material.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

/// Shared across all roles — dark mode, language preferences.
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool darkMode = false;
  String language = 'English';

  final List<String> languages = ['English', 'Hindi', 'Spanish', 'French', 'Arabic'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('App Settings', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _buildCard([
          SwitchListTile(
            title: Row(
              children: [
                const Icon(Icons.dark_mode_outlined, color: AppColors.textMedium, size: 22),
                const SizedBox(width: AppSpacing.md),
                Text('Dark Mode', style: AppTextStyles.labelBold),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Switch to a darker theme (coming soon)', style: AppTextStyles.bodySmall),
            ),
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
            value: darkMode,
            onChanged: (_) {
              // TODO: Implement theme switching via Riverpod
            },
          ),
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.textMedium),
            title: Text('Language', style: AppTextStyles.labelBold),
            trailing: DropdownButton<String>(
              value: language,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
              items: languages
                  .map((l) => DropdownMenuItem(value: l, child: Text(l, style: AppTextStyles.bodyMedium)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => language = v);
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: children),
    );
  }
}
