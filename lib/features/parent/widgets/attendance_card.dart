import 'package:flutter/material.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

class AttendanceCard extends StatelessWidget {
  final String childName;
  final String date;
  final String checkIn;
  final String checkOut;
  final String method;

  const AttendanceCard({
    super.key,
    required this.childName,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = checkOut != '—';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: child name + status badge
          Row(
            children: [
              Expanded(
                child: Text(childName, style: AppTextStyles.labelBold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isComplete ? 'Completed' : 'In Progress',
                  style: AppTextStyles.caption.copyWith(
                    color: isComplete ? AppColors.success : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(date, style: AppTextStyles.bodyMuted),
          const SizedBox(height: AppSpacing.md),

          // Check-in / check-out times
          Row(
            children: [
              Expanded(
                child: _TimeBlock(
                  label: 'Check-In',
                  time: checkIn,
                  icon: Icons.login_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _TimeBlock(
                  label: 'Check-Out',
                  time: checkOut,
                  icon: Icons.logout_rounded,
                  color: checkOut == '—' ? AppColors.textMuted : AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Method badge
              Column(
                children: [
                  Icon(
                    method == 'qr' ? Icons.qr_code : Icons.touch_app,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  Text(method.toUpperCase(), style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;

  const _TimeBlock({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: AppTextStyles.labelBold.copyWith(
            color: time == '—' ? AppColors.textMuted : color,
          ),
        ),
      ],
    );
  }
}
