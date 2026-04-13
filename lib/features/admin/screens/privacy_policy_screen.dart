import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.heading3,
      ),
    );
  }

  Widget _sectionBody(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium,
      ),
    );
  }

  Widget _cardSection({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text("Privacy Policy"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🌟 HEADER
            Text(
              "Your Privacy Matters",
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppSpacing.sm),

            Text(
              "We are committed to protecting the privacy of every child, parent, teacher, and administrator using TinySteps.",
              style: AppTextStyles.bodyMedium,
            ),

            const SizedBox(height: AppSpacing.lg),

            // 🧾 WHO WE ARE
            _cardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Who We Are"),
                  _sectionBody(
                    "TinySteps is a secure daycare management platform designed to connect Parents, Teachers, and Administrators in one place. "
                    "It enables real-time tracking of attendance, daily activities, meals, and personalized child development insights for children aged 0–5 years.",
                  ),
                ],
              ),
            ),

            // 🧾 DATA COLLECTION
            _cardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("1. Information We Collect"),
                  _sectionBody(
                    "We collect essential data such as user details, child profiles, attendance logs, and activity updates. "
                    "Sensitive information like medical details is collected only when necessary and handled with strict security.",
                  ),
                ],
              ),
            ),

            // 🧾 DATA USAGE
            _cardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("2. How We Use Information"),
                  _sectionBody(
                    "Your data is used to provide core daycare services including attendance tracking, activity updates, personalized content, and secure communication between users.",
                  ),
                ],
              ),
            ),

            // 👨‍👩‍👧 PARENTS
            _cardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("3. Privacy for Parents"),
                  _sectionBody(
                    "Parents can only access their own child’s data. This includes attendance, meals, activities, and care updates. "
                    "No parent can view another child’s information under any circumstance.",
                  ),
                ],
              ),
            ),

            // 👩‍🏫 TEACHERS
            _cardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("4. Privacy for Teachers"),
                  _sectionBody(
                    "Teachers can access and update data only for children assigned to them. "
                    "They cannot access administrative controls or unrelated child records.",
                  ),
                ],
              ),
            ),

            // 🛡️ ADMINS
            _cardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("5. Privacy for Administrators"),
                  _sectionBody(
                    "Administrators manage user accounts, approvals, and system access. "
                    "They have controlled access to data strictly for operational purposes and are responsible for maintaining platform security.",
                  ),
                ],
              ),
            ),

            // 🔐 SECURITY
            _cardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("6. Data Security"),
                  _sectionBody(
                    "TinySteps uses secure cloud infrastructure, encryption, and role-based access control to protect all data. "
                    "Unauthorized access is strictly prevented through referral-based account creation.",
                  ),
                ],
              ),
            ),

            // 🚫 DATA SHARING
            _cardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("7. Data Sharing"),
                  _sectionBody(
                    "We do not sell, trade, or share your personal data with third parties. "
                    "All information is used only within TinySteps to provide core functionality.",
                  ),
                ],
              ),
            ),

            // 🧾 RIGHTS
            _cardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("8. User Rights"),
                  _sectionBody(
                    "Users can request updates or deletion of their data. Administrators can manage and ensure data accuracy within the system.",
                  ),
                ],
              ),
            ),

            // 🔄 UPDATES
            _cardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("9. Policy Updates"),
                  _sectionBody(
                    "This policy may be updated as TinySteps evolves. Users will be notified of any significant changes.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Center(
              child: Text(
                "Last updated: 2026",
                style: AppTextStyles.bodySmall,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}