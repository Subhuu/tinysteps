import 'package:flutter/material.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool attendanceAlerts = true;
  bool emergencyAlerts = true;
  bool announcements = true;
  bool paymentReminders = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Notifications', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage what notifications you receive.', style: AppTextStyles.bodyMuted),
            const SizedBox(height: AppSpacing.xl),

            _buildCard([
              _buildSwitch(
                title: 'Attendance Alerts',
                subtitle: 'Get notified when your child checks in or out',
                value: attendanceAlerts,
                onChanged: (v) => setState(() => attendanceAlerts = v),
              ),
              _divider(),
              _buildSwitch(
                title: 'Emergency Alerts',
                subtitle: 'Critical safety and health notifications',
                value: emergencyAlerts,
                onChanged: (v) => setState(() => emergencyAlerts = v),
              ),
              _divider(),
              _buildSwitch(
                title: 'Announcements',
                subtitle: 'Events, news and updates from the daycare',
                value: announcements,
                onChanged: (v) => setState(() => announcements = v),
              ),
              _divider(),
              _buildSwitch(
                title: 'Payment Reminders',
                subtitle: 'Reminders about upcoming or missed payments',
                value: paymentReminders,
                onChanged: (v) => setState(() => paymentReminders = v),
              ),
            ]),
          ],
        ),
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

  Widget _divider() => const Divider(height: 1, color: AppColors.border);

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: AppTextStyles.labelBold),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: AppTextStyles.bodySmall),
      ),
      activeThumbColor: AppColors.primary,
      activeTrackColor: AppColors.primaryLight,
      value: value,
      onChanged: onChanged,
    );
  }
}
