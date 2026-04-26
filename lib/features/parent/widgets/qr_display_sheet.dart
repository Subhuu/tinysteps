import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

// ── Public helper to show the QR sheet ────────────────────────────────────────
void showQRDisplaySheet(
  BuildContext context, {
  required String childId,
  required String childName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.transparent,
    builder: (_) => _QRDisplaySheet(childId: childId, childName: childName),
  );
}

// ── QR token helpers ───────────────────────────────────────────────────────────

/// Returns the 5-minute epoch window index for a given moment.
/// window = floor(unix_seconds / 300)
int _currentWindow([DateTime? at]) {
  final t = at ?? DateTime.now();
  return t.millisecondsSinceEpoch ~/ 1000 ~/ 300;
}

/// Returns Unix seconds when the current window expires (start of next window).
int _windowExpiry([DateTime? at]) => (_currentWindow(at) + 1) * 300;



/// HMAC-SHA256 token for this childId + window.
/// Both parent (generator) and teacher (validator) compute the same value.
String buildQrToken(String childId, {DateTime? at}) {
  final window = _currentWindow(at);
  final key = utf8.encode(
    childId,
  ); // deterministic key from child's permanent ID
  final msg = utf8.encode('$childId:$window');
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(msg);
  return digest.toString().substring(0, 16); // 16-char prefix is enough
}

/// Full JSON payload encoded into the QR image.
String buildQrPayload(String childId, {DateTime? at}) {
  final token = buildQrToken(childId, at: at);
  final expires = _windowExpiry(at);
  return jsonEncode({'child_id': childId, 'token': token, 'expires': expires});
}

// ── Sheet widget ───────────────────────────────────────────────────────────────
class _QRDisplaySheet extends StatefulWidget {
  final String childId;
  final String childName;

  const _QRDisplaySheet({required this.childId, required this.childName});

  @override
  State<_QRDisplaySheet> createState() => _QRDisplaySheetState();
}

class _QRDisplaySheetState extends State<_QRDisplaySheet> {
  late Timer _timer;
  int _secondsLeft = 0;
  late String _qrPayload;
  late int _currentWin;

  @override
  void initState() {
    super.initState();
    _currentWin = _currentWindow();
    _generateQR();
    _updateTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateTimer();
    });
  }

  void _updateTimer() {
    final now = DateTime.now();
    final win = _currentWindow(now);

    if (win != _currentWin) {
      _currentWin = win;
      _generateQR();
    }

    final nowEpoch = now.millisecondsSinceEpoch ~/ 1000;
    final expiry = _windowExpiry(now);

    setState(() {
      _secondsLeft = expiry - nowEpoch;
    });
  }

  /// ✅ NEW QR LOGIC (DIFFERENT PER CHILD + TIME)
  void _generateQR() {
    final now = DateTime.now().millisecondsSinceEpoch;

    _qrPayload = jsonEncode({
      'child_id': widget.childId,
      'child_name': widget.childName,
      'generated_at': now, // ensures QR is always unique
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color _timerColor() {
    if (_secondsLeft > 120) return context.colors.success;
    if (_secondsLeft > 60) return context.colors.warning;
    return context.colors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: context.colors.bgLight,
        borderRadius: AppRadius.sheetRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.border,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Text('Child Check-In QR', style: context.textStyles.heading2),
          const SizedBox(height: AppSpacing.xs),
          Text(widget.childName, style: context.textStyles.bodyMuted),

          const SizedBox(height: AppSpacing.xl),

          // 🔳 QR Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                // 👶 Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: context.colors.primaryLight.withValues(
                    alpha: 0.3,
                  ),
                  child: Text(
                    widget.childName[0],
                    style: context.textStyles.heading2.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // QR
                QrImageView(
                  data: _qrPayload,
                  size: 220,
                  backgroundColor: context.colors.bgSurface,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: context.colors.textDark,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: context.colors.textDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ⏱️ Timer (FIXED)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, size: 16, color: _timerColor()),
              const SizedBox(width: 6),
              Text('Refreshes in ', style: context.textStyles.bodySmall),
              Text(
                _formatTime(_secondsLeft),
                style: context.textStyles.labelBold.copyWith(color: _timerColor()),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),
          Text(
            'QR rotates every 5 minutes for security',
            style: context.textStyles.caption,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.lg),

          // ℹ️ Instruction
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: context.colors.primary,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Show this to the teacher at drop-off or pickup. '
                    'They will scan it to mark attendance.',
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Close button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.colors.border),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonRadius,
                ),
              ),
              child: Text(
                'Close',
                style: context.textStyles.labelBold.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
