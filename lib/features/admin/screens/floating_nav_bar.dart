import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

Widget buildFloatingNavBar({
  required int currentIndex,
  required Function(int) onTap,
}) {
  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(
          icon: Icons.home,
          label: "Dashboard",
          isActive: currentIndex == 0,
          onTap: () => onTap(0),
        ),
        _NavItem(
          icon: Icons.people,
          label: "Users",
          isActive: currentIndex == 1,
          onTap: () => onTap(1),
        ),
        _NavItem(
          icon: Icons.class_,
          label: "Classrooms",
          isActive: currentIndex == 2,
          onTap: () => onTap(2),
        ),
        _NavItem(
          icon: Icons.settings,
          label: "Settings",
          isActive: currentIndex == 3,
          onTap: () => onTap(3),
        ),
      ],
    ),
  );
}


class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primary : AppColors.gradientMid,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.primary : AppColors.gradientStart,
            ),
          ),
        ],
      ),
    );
  }
}