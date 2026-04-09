import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/features/parent/widgets/qr_display_sheet.dart'
    show buildQrToken;

// ── Attendance result states ────────────────────────────────────────────────
enum _ScanState { scanning, loading, checkedIn, checkedOut, alreadyOut, invalid, error, assigned, otherClass }

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  _ScanState _state = _ScanState.scanning;
  String _childName = '';
  String _message = '';
  String _timeLabel = '';

  bool _processing = false; // debounce — ignore duplicate scans while handling

  final _supabase = Supabase.instance.client;
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── QR scan handler ─────────────────────────────────────────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _state != _ScanState.scanning) return;
    _processing = true;

    final raw = capture.barcodes.first.rawValue;
    if (raw == null) {
      _processing = false;
      return;
    }

    // 1. Parse payload
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _ScanState.invalid);
      _processing = false;
      return;
    }

    final childId = payload['child_id'] as String?;
    final token = payload['token'] as String?;
    final expires = payload['expires'] as int?;

    if (childId == null || token == null || expires == null) {
      if (!mounted) return;
      setState(() { _state = _ScanState.invalid; _message = 'Unrecognised QR format.'; });
      _processing = false;
      return;
    }

    // 2. Validate expiry (client-side — no server round-trip)
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (nowSeconds > expires) {
      if (!mounted) return;
      setState(() { _state = _ScanState.invalid; _message = 'QR code has expired. Ask the parent to refresh.'; });
      _processing = false;
      return;
    }

    // 3. Validate token — recompute and compare
    final expectedToken = buildQrToken(childId);
    if (token != expectedToken) {
      if (!mounted) return;
      setState(() { _state = _ScanState.invalid; _message = 'QR code is invalid or has been tampered with.'; });
      _processing = false;
      return;
    }

    // 4. QR is valid — set loading and hit DB
    if (!mounted) return;
    setState(() => _state = _ScanState.loading);

    try {
      final teacherId = _supabase.auth.currentUser!.id;
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Fetch child info + classroom + today's attendance in parallel
      final results = await Future.wait([
        _supabase
            .from('children')
            .select('full_name, teacher_id, classroom_id, classrooms(name)')
            .eq('id', childId)
            .single(),
        _supabase
            .from('attendance')
            .select('id, checked_in_at, checked_out_at')
            .eq('child_id', childId)
            .eq('date', today)
            .maybeSingle(),
      ]);

      final childRow = results[0] as Map<String, dynamic>;
      final dynamic rawExisting = results[1];
      final existing = rawExisting as Map<String, dynamic>?;
      final name = childRow['full_name'] as String? ?? 'Child';
      final childTeacherId = childRow['teacher_id'] as String?;
      final childClassroomId = childRow['classroom_id'] as String?;
      final classroomMap = childRow['classrooms'] as Map<String, dynamic>?;
      final classroomName = classroomMap?['name'] as String? ?? 'Unknown';

      if (!mounted) return;

      // ── Case 1: Child belongs to ANOTHER teacher's classroom ──────────────
      if (childTeacherId != null && childTeacherId != teacherId) {
        setState(() {
          _state = _ScanState.otherClass;
          _childName = name;
          _message = 'This child belongs to classroom "$classroomName".';
        });
        _processing = false;
        return;
      }

      // ── Case 2: Child is UNASSIGNED — offer to assign ────────────────────
      if (childClassroomId == null || childTeacherId == null) {
        // Fetch the teacher's classroom(s)
        final teacherClassrooms = await _supabase
            .from('classrooms')
            .select('id, name')
            .eq('teacher_id', teacherId);

        if (!mounted) return;

        if (teacherClassrooms.isEmpty) {
          setState(() {
            _state = _ScanState.error;
            _message = 'You have no classroom assigned. Ask admin to assign one.';
          });
          _processing = false;
          return;
        }

        // Auto-assign to teacher's first classroom (or show picker if multiple)
        final targetClassroom = teacherClassrooms.first;
        final targetId = targetClassroom['id'] as String;
        final targetName = targetClassroom['name'] as String? ?? 'Classroom';

        await _supabase.from('children').update({
          'classroom_id': targetId,
          'teacher_id': teacherId,
        }).eq('id', childId);

        setState(() {
          _state = _ScanState.assigned;
          _childName = name;
          _message = 'Assigned to $targetName';
        });
        _processing = false;
        return;
      }

      // ── Case 3: Child belongs to THIS teacher — mark attendance ──────────
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final nowLocal = DateTime.now();
      final timeLabel =
          '${nowLocal.hour.toString().padLeft(2, '0')}:${nowLocal.minute.toString().padLeft(2, '0')}';

      if (existing == null || existing['checked_in_at'] == null) {
        // ── CHECK-IN ─────────────────────────────────────────────────────────
        await _supabase.from('attendance').upsert(
          {
            'child_id': childId,
            'date': today,
            'checked_in_at': nowUtc,
            'checked_in_by': teacherId,
            'method': 'qr',
            'qr_code_used': token,
          },
          onConflict: 'child_id, date',
        );
        if (!mounted) return;
        setState(() {
          _state = _ScanState.checkedIn;
          _childName = name;
          _timeLabel = timeLabel;
        });
      } else if (existing['checked_out_at'] == null) {
        // ── CHECK-OUT ────────────────────────────────────────────────────────
        await _supabase.from('attendance').update({
          'checked_out_at': nowUtc,
          'checked_out_by': teacherId,
        }).eq('id', existing['id'] as String);
        if (!mounted) return;
        setState(() {
          _state = _ScanState.checkedOut;
          _childName = name;
          _timeLabel = timeLabel;
        });
      } else {
        // Already checked out today
        if (!mounted) return;
        setState(() {
          _state = _ScanState.alreadyOut;
          _childName = name;
        });
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.error;
        _message = e.message;
      });
    } finally {
      _processing = false;
    }
  }

  void _reset() => setState(() {
        _state = _ScanState.scanning;
        _childName = '';
        _message = '';
        _timeLabel = '';
      });

  Future<void> _uploadFromGallery() async {
    // Check permission first as requested
    PermissionStatus status = await Permission.photos.request();
    
    // Fallback for Android below 13 if photos is permanently denied but storage is needed
    if (status.isPermanentlyDenied) {
      status = await Permission.storage.request();
    }

    if (status.isGranted || status.isLimited) {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        if (!mounted) return;
        setState(() {
          _state = _ScanState.loading;
        });

        final capture = await _controller.analyzeImage(image.path);
        
        if (capture != null && capture.barcodes.isNotEmpty) {
          setState(() {
            _state = _ScanState.scanning; // Reset so _onDetect processes it
          });
          _onDetect(capture);
        } else {
          setState(() {
            _state = _ScanState.invalid;
            _message = 'No valid QR code found in the image.';
          });
        }
      }
    } else {
      if (mounted) {
        _showPermissionDeniedDialog('Photo Gallery');
      }
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      // Re-initialize controller to regain camera access
      await _controller.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _controller.start();
      if (mounted) setState(() {});
    } else {
      if (mounted) {
        _showPermissionDeniedDialog('Camera');
      }
    }
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permissionName Permission Required', style: AppTextStyles.heading2),
        content: Text('Please grant $permissionName access in your app settings to use this feature.', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      )
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Attendance Scanner', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/teacher'),
        ),
      ),
      body: _state == _ScanState.scanning
          ? _buildScanner()
          : _buildResultView(),
    );
  }

  // ── Camera viewfinder ───────────────────────────────────────────────────────
  Widget _buildScanner() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Point camera at the parent\'s QR code',
          style: AppTextStyles.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Viewfinder
        Center(
          child: Container(
            width: 280,
            height: 280,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _requestCameraPermission,
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, color: Colors.white, size: 40),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Camera permission denied.',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Tap here to grant permission',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Corner markers visual hint
        Text(
          'Align the QR code inside the frame',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        
        // Upload from gallery button
        FilledButton.icon(
          onPressed: _uploadFromGallery,
          icon: const Icon(Icons.image_outlined, color: AppColors.textDark),
          label: const Text('Upload from gallery', style: TextStyle(color: AppColors.textDark)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.bgLight,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  // ── Result view (success / error / etc.) ────────────────────────────────────
  Widget _buildResultView() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildResultIcon(),
          const SizedBox(height: AppSpacing.xl),
          _buildResultText(),
          const SizedBox(height: AppSpacing.xxl),
          if (_state != _ScanState.loading)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Next'),
                onPressed: _reset,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.buttonRadius,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultIcon() {
    switch (_state) {
      case _ScanState.loading:
        return const CircularProgressIndicator(color: AppColors.primary);
      case _ScanState.checkedIn:
        return const Icon(Icons.login_rounded, size: 100, color: AppColors.success);
      case _ScanState.checkedOut:
        return const Icon(Icons.logout_rounded, size: 100, color: AppColors.secondary);
      case _ScanState.alreadyOut:
        return const Icon(Icons.info_outline, size: 100, color: AppColors.warning);
      case _ScanState.assigned:
        return const Icon(Icons.how_to_reg_rounded, size: 100, color: AppColors.success);
      case _ScanState.otherClass:
        return const Icon(Icons.block_rounded, size: 100, color: AppColors.warning);
      case _ScanState.invalid:
        return const Icon(Icons.qr_code_2, size: 100, color: AppColors.danger);
      case _ScanState.error:
        return const Icon(Icons.cloud_off_rounded, size: 100, color: AppColors.danger);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildResultText() {
    switch (_state) {
      case _ScanState.loading:
        return Text('Processing scan...', style: AppTextStyles.bodyMuted);

      case _ScanState.checkedIn:
        return Column(
          children: [
            Text(_childName, style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '✅ Checked In at $_timeLabel',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.success),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _ScanState.checkedOut:
        return Column(
          children: [
            Text(_childName, style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '👋 Checked Out at $_timeLabel',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _ScanState.alreadyOut:
        return Column(
          children: [
            Text(_childName, style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$_childName has already checked out today.',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _ScanState.invalid:
        return Column(
          children: [
            Text('Invalid QR Code', style: AppTextStyles.heading2.copyWith(color: AppColors.danger)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _message.isNotEmpty
                  ? _message
                  : 'This QR code is not recognised.',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _ScanState.error:
        return Column(
          children: [
            Text('Connection Error', style: AppTextStyles.heading2.copyWith(color: AppColors.danger)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _message.isNotEmpty ? _message : 'Please check your connection and try again.',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        );
      case _ScanState.assigned:
        return Column(
          children: [
            Text(_childName, style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '✅ $_message',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.success),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The child has been enrolled in your classroom.',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _ScanState.otherClass:
        return Column(
          children: [
            Text(_childName, style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _message,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.warning),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You can only mark attendance for children in your classroom.',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}