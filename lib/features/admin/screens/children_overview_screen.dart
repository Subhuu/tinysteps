import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

/// Admin Children Overview — all enrolled children with classroom + teacher info
class ChildrenOverviewScreen extends StatefulWidget {
  const ChildrenOverviewScreen({super.key});

  @override
  State<ChildrenOverviewScreen> createState() => _ChildrenOverviewScreenState();
}

class _ChildrenOverviewScreenState extends State<ChildrenOverviewScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<dynamic> _allChildren = [];
  List<dynamic> _filteredChildren = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch children with classroom and parent details, ordered by name from DB
      final data = await _supabase
          .from('children')
          .select(
          'id, full_name, date_of_birth, gender, status, classroom_id, teacher_id, '
              'classrooms(name, code), parents(full_name)')
          .order('full_name');

      if (mounted) {
        // Perform an explicit case-insensitive sort in Dart to ensure A-Z order
        data.sort((a, b) {
          final nameA = (a['full_name'] as String? ?? '').toLowerCase();
          final nameB = (b['full_name'] as String? ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        });

        setState(() {
          _allChildren = data;
          _filteredChildren = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredChildren = _allChildren;
      } else {
        // Search filter maintains the alphabetical order of _allChildren
        _filteredChildren = _allChildren.where((c) {
          final name = (c['full_name'] as String? ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('All Children', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ── Search Bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search child name...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // ── List Area ──────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
              const SizedBox(height: AppSpacing.sm),
              Text('Failed to load children', style: AppTextStyles.labelBold),
              const SizedBox(height: AppSpacing.xs),
              Text(_errorMessage!, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_allChildren.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care_outlined,
                size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text('No children enrolled', style: AppTextStyles.heading3),
          ],
        ),
      );
    }

    if (_filteredChildren.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text('No matches found', style: AppTextStyles.heading3),
            Text('Try a different search term', style: AppTextStyles.bodyMuted),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      itemCount: _filteredChildren.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final c = _filteredChildren[index] as Map<String, dynamic>;
        final classroom = c['classrooms'] as Map<String, dynamic>?;
        final parent = c['parents'] as Map<String, dynamic>?;
        final status = c['status'] as String? ?? 'active';

        final classroomLabel = classroom != null
            ? '${classroom['name']} (${classroom['code']})'
            : 'Unassigned';
        final parentName = parent?['full_name'] as String? ?? 'Unknown';

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: classroom != null
                    ? AppColors.primaryLight
                    : AppColors.warning.withValues(alpha: 0.15),
                child: Text(
                  (c['full_name'] as String? ?? 'C')[0].toUpperCase(),
                  style: AppTextStyles.labelBold.copyWith(
                    color: classroom != null
                        ? AppColors.primary
                        : AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['full_name'] ?? '—',
                        style: AppTextStyles.labelBold),
                    Text(
                      'Parent: $parentName',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      'Classroom: $classroomLabel',
                      style: AppTextStyles.caption.copyWith(
                        color: classroom != null
                            ? AppColors.textMuted
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: _statusLabel(status),
                color: _statusColor(status),
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(String s) => switch (s) {
    'active' => 'Active',
    'withdrawn' => 'Withdrawn',
    'waitlisted' => 'Waitlisted',
    'graduated' => 'Graduated',
    _ => s,
  };

  Color _statusColor(String s) => switch (s) {
    'active' => AppColors.success,
    'withdrawn' => AppColors.danger,
    'waitlisted' => AppColors.warning,
    'graduated' => AppColors.secondary,
    _ => AppColors.textMuted,
  };
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
