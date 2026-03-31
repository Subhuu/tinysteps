import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _supabase = Supabase.instance.client;

  final _phoneCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String _fullName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final data = await _supabase
          .from('parents')
          .select('full_name, phone, emergency_contact_name, emergency_contact_phone')
          .eq('id', uid)
          .single();

      if (!mounted) return;
      setState(() {
        _fullName = data['full_name'] as String? ?? '';
        _email = _supabase.auth.currentUser?.email ?? '';
        _phoneCtrl.text = data['phone'] as String? ?? '';
        _emergencyNameCtrl.text = data['emergency_contact_name'] as String? ?? '';
        _emergencyPhoneCtrl.text = data['emergency_contact_phone'] as String? ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            'Failed to load profile. Pull to retry.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await _supabase.from('parents').update({
        'phone': _phoneCtrl.text.trim(),
        'emergency_contact_name': _emergencyNameCtrl.text.trim(),
        'emergency_contact_phone': _emergencyPhoneCtrl.text.trim(),
      }).eq('id', uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'Profile saved successfully!',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            'Save failed: ${e.message}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Personal Details', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Information', style: AppTextStyles.heading3),
                  const SizedBox(height: AppSpacing.md),

                  // Read-only fields (managed via auth, not editable)
                  _ReadOnlyField(label: 'Full Name', value: _fullName, icon: Icons.person_outline),
                  const SizedBox(height: AppSpacing.md),
                  _ReadOnlyField(label: 'Email Address', value: _email, icon: Icons.email_outlined),
                  const SizedBox(height: AppSpacing.md),

                  // Editable: phone
                  _buildEditableField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    hint: '+91XXXXXXXXXX',
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  Text('Emergency Contact', style: AppTextStyles.heading3),
                  Text(
                    'Who should we call if we can\'t reach you?',
                    style: AppTextStyles.bodyMuted,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildEditableField(
                    controller: _emergencyNameCtrl,
                    label: 'Contact Name',
                    icon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildEditableField(
                    controller: _emergencyPhoneCtrl,
                    label: 'Contact Phone',
                    icon: Icons.contact_phone_outlined,
                    keyboardType: TextInputType.phone,
                    hint: '+91XXXXXXXXXX',
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.buttonRadius),
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: AppColors.white, strokeWidth: 2),
                            )
                          : Text('Save Changes', style: AppTextStyles.buttonLabel),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      style: AppTextStyles.bodyLarge,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
      ),
    );
  }
}

// Read-only display field (name/email — set at registration)
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReadOnlyField({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.6),
        borderRadius: AppRadius.inputRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
