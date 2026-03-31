import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

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
      final qrCode = DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
          _nameController.text.trim().hashCode.toRadixString(36);

      // Insert child row with qr_code in one atomic operation
      await _supabase
          .from('children')
          .insert({
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
          backgroundColor: AppColors.success,
          content: Text(
            '${_nameController.text.trim()} added successfully!',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
          ),
        ),
      );
      Navigator.pop(context, true); // true = child was added, parent should refresh
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            'Failed to add child: ${e.message}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
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
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Add Child', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
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
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.child_care_rounded,
                    color: AppColors.accent,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'Tell us about your child',
                  style: AppTextStyles.bodyMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Child Details', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.md),

              // Full Name
              TextFormField(
                controller: _nameController,
                style: AppTextStyles.bodyLarge,
                textCapitalization: TextCapitalization.words,
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Full name is required' : null,
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
                  label: 'Allergies (optional)',
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
                  label: 'Medical Notes (optional)',
                  icon: Icons.medical_information_outlined,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
              Text(
                'A classroom will be assigned by admin after submission.',
                style: AppTextStyles.caption,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.buttonRadius,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Add Child', style: AppTextStyles.buttonLabel),
                ),
              ),
            ],
          ),
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
