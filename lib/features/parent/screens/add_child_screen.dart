import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicalNotesController = TextEditingController();

  String _selectedGender = 'Male';
  DateTime? _selectedDob;
  bool _isLoading = false;

  final _supabase = Supabase.instance.client;

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
      initialDate: DateTime(2021),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date of birth.')),
      );
      return;
    }

    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      // Generate a UUID for qr_code upfront
      final qrCode =
          DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
          _nameController.text.trim().hashCode.toRadixString(36);

      // Insert child row with qr_code in one atomic operation
      await _supabase.from('children').insert({
        'full_name': _nameController.text.trim(),
        'date_of_birth': _selectedDob!.toIso8601String().substring(0, 10),
        'gender': _selectedGender,
        'allergies': _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
        'medical_notes': _medicalNotesController.text.trim().isEmpty
            ? null
            : _medicalNotesController.text.trim(),
        'parent_id': uid,
        'status': 'active',
        'qr_code': qrCode,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colors.success,
          content: Text(
            '${_nameController.text.trim()} added successfully!',
            style: context.textStyles.bodySmall.copyWith(color: context.colors.white),
          ),
        ),
      );
      Navigator.pop(
        context,
        true,
      ); // true = child was added, parent should refresh
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colors.danger,
          duration: const Duration(seconds: 5),
          content: Text(
            'Failed to add child: ${e.message}\nCode: ${e.code}',
            style: context.textStyles.bodySmall.copyWith(color: context.colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgLight,
      appBar: AppBar(
        title: Text('Add Child', style: context.textStyles.heading2),
        backgroundColor: context.colors.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header icon
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: context.colors.accent.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.child_care_rounded,
                    color: context.colors.accent,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'Tell us about your child',
                  style: context.textStyles.bodyMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Child Details', style: context.textStyles.heading3),
              const SizedBox(height: AppSpacing.md),

              // Full Name
              TextFormField(
                controller: _nameController,
                style: context.textStyles.bodyLarge,
                textCapitalization: TextCapitalization.words,
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Full name is required'
                    : null,
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
                    style: context.textStyles.bodyLarge,
                    decoration: _inputDecoration(
                      label: 'Date of Birth',
                      icon: Icons.cake_outlined,
                    ),
                    controller: TextEditingController(
                      text: _selectedDob == null
                          ? ''
                          : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Gender
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedGender),
                initialValue: _selectedGender,
                decoration: _inputDecoration(
                  label: 'Gender',
                  icon: Icons.people_outline,
                ),
                dropdownColor: AppColors.bgSurface,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textDark,
                ),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedGender = val!),
              ),
              const SizedBox(height: AppSpacing.md),

              // Allergies
              TextFormField(
                controller: _allergiesController,
                style: context.textStyles.bodyLarge,
                decoration: _inputDecoration(
                  label: 'Allergies (optional)',
                  icon: Icons.warning_amber_outlined,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Medical Notes
              TextFormField(
                controller: _medicalNotesController,
                maxLines: 3,
                style: context.textStyles.bodyLarge,
                decoration: _inputDecoration(
                  label: 'Medical Notes (optional)',
                  icon: Icons.medical_information_outlined,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
              Text(
                'A classroom will be assigned by admin after submission.',
                style: context.textStyles.caption,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(

                    backgroundColor: context.colors.primary,
                    disabledBackgroundColor: context.colors.primary.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.buttonRadius,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: context.colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Add Child', style: context.textStyles.buttonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: context.textStyles.labelMedium,
      prefixIcon: Icon(icon, color: context.colors.secondary),
      filled: true,
      fillColor: context.colors.bgSurface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: context.colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: context.colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: context.colors.primary, width: 2),
      ),
    );
  }
}

