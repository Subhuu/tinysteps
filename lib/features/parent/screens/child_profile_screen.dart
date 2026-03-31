import 'package:flutter/material.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

class ChildProfileScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const ChildProfileScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final _nameController = TextEditingController(text: 'Leo Smith');
  final _allergiesController = TextEditingController(text: 'Peanuts');
  final _medicalNotesController = TextEditingController(text: 'Mild asthma');

  String _selectedGender = 'Male';
  DateTime _selectedDob = DateTime(2021, 4, 12);

  @override
  void dispose() {
    _nameController.dispose();
    _allergiesController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(widget.childName, style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  widget.childName[0].toUpperCase(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Child Details', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.md),

            // Full Name
            TextFormField(
              controller: _nameController,
              style: AppTextStyles.bodyLarge,
              decoration: _inputDecoration(
                label: 'Full Name',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Date of Birth
            GestureDetector(
              onTap: () => _pickDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  style: AppTextStyles.bodyLarge,
                  decoration: _inputDecoration(
                    label: 'Date of Birth',
                    icon: Icons.cake_outlined,
                  ),
                  controller: TextEditingController(
                    text:
                        '${_selectedDob.day}/${_selectedDob.month}/${_selectedDob.year}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Gender
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedGender),
              initialValue: _selectedGender,
              decoration: _inputDecoration(label: 'Gender', icon: Icons.people_outline),
              items: ['Male', 'Female', 'Other']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedGender = val!),
            ),
            const SizedBox(height: AppSpacing.md),

            // Allergies
            TextFormField(
              controller: _allergiesController,
              style: AppTextStyles.bodyLarge,
              decoration: _inputDecoration(
                label: 'Allergies',
                icon: Icons.warning_amber_outlined,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Medical Notes
            TextFormField(
              controller: _medicalNotesController,
              maxLines: 3,
              style: AppTextStyles.bodyLarge,
              decoration: _inputDecoration(
                label: 'Medical Notes',
                icon: Icons.medical_information_outlined,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Read-only classroom info
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Classroom: Sunshine Room', style: AppTextStyles.labelBold),
                      Text('Teacher: Ms. Sarah', style: AppTextStyles.bodyMuted),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              'Classroom assignment is managed by admin.',
              style: AppTextStyles.caption,
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Call Supabase update for this child
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Changes saved!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: Text('Save Changes', style: AppTextStyles.buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.labelMedium,
      prefixIcon: Icon(icon, color: AppColors.secondary),
      filled: true,
      fillColor: AppColors.bgSurface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
