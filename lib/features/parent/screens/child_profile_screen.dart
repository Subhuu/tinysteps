import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicalNotesController = TextEditingController();

  String _selectedGender = 'Male';
  DateTime _selectedDob = DateTime(2021, 1, 1);

  bool _isLoading = true;
  bool _isSaving = false;
  String _classroomName = 'Unassigned';

  @override
  void initState() {
    super.initState();
    _loadChildData();
  }

  // Allowed gender values — must match the dropdown items exactly
  static const _genderOptions = ['Male', 'Female', 'Other'];

  /// Normalises a gender string from the DB (e.g. 'male', 'FEMALE') to title
  /// case so it matches the dropdown items. Returns 'Male' as fallback.
  String _normaliseGender(String? raw) {
    if (raw == null || raw.isEmpty) return 'Male';
    final titleCase = '${raw[0].toUpperCase()}${raw.substring(1).toLowerCase()}';
    return _genderOptions.contains(titleCase) ? titleCase : 'Male';
  }

  Future<void> _loadChildData() async {
    try {
      // Fetch child details — only join classrooms (safe, always works)
      final data = await _supabase
          .from('children')
          .select(
              'full_name, date_of_birth, gender, allergies, medical_notes, '
              'classrooms(name)')
          .eq('id', widget.childId)
          .single();

      if (!mounted) return;

      setState(() {
        _nameController.text = data['full_name'] as String? ?? '';

        final dobStr = data['date_of_birth'] as String?;
        if (dobStr != null && dobStr.isNotEmpty) {
          try {
            _selectedDob = DateTime.parse(dobStr);
          } catch (_) {}
        }

        _selectedGender = _normaliseGender(data['gender'] as String?);
        _allergiesController.text = data['allergies'] as String? ?? '';
        _medicalNotesController.text = data['medical_notes'] as String? ?? '';

        final classroom = data['classrooms'] as Map<String, dynamic>?;
        _classroomName = classroom?['name'] as String? ?? 'Unassigned';

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            'Failed to load child details.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
          ),
        ),
      );
    }
  }

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

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await _supabase.from('children').update({
        'full_name': _nameController.text.trim(),
        'date_of_birth': _selectedDob.toIso8601String().substring(0, 10),
        'gender': _selectedGender.toLowerCase(),
        'allergies': _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
        'medical_notes': _medicalNotesController.text.trim().isEmpty
            ? null
            : _medicalNotesController.text.trim(),
      }).eq('id', widget.childId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved!')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            'Failed to save: ${e.message}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
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
                        widget.childName.isNotEmpty
                            ? widget.childName[0].toUpperCase()
                            : 'C',
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
                    value: _selectedGender,
                    decoration: _inputDecoration(label: 'Gender', icon: Icons.people_outline),
                    items: _genderOptions
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
                            Text('Classroom: $_classroomName', style: AppTextStyles.labelBold),
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
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text('Save Changes', style: AppTextStyles.buttonLabel),
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
