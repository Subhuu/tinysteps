import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    final name = user?.userMetadata?['full_name'] ?? 'Admin';
    final email = user?.email ?? 'No Email';
    final phone = user?.userMetadata?['phone'] ?? '+91 XXXXXXXX';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [

            // 🔵 PROFILE IMAGE
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.person, size: 50),
            ),

            const SizedBox(height: AppSpacing.md),

            // 👤 NAME
            Text(
              name,
              style: AppTextStyles.heading2,
            ),

            const SizedBox(height: 4),

            // 📧 EMAIL
            Text(
              email,
              style: AppTextStyles.bodyMuted,
            ),

            const SizedBox(height: 4),

            // 📱 PHONE
            Text(
              phone,
              style: AppTextStyles.bodyMuted,
            ),

            const SizedBox(height: AppSpacing.xl),

            // 🔹 OPTIONS LIST
            _buildOptionTile(
              icon: Icons.edit,
              title: 'Edit Profile',
              onTap: () {},
            ),

            _buildOptionTile(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {},
            ),

            _buildOptionTile(
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {},
            ),

            _buildOptionTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {},
            ),

            const SizedBox(height: AppSpacing.lg),

            // 🔴 LOGOUT BUTTON
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 COMMON TILE WIDGET
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}