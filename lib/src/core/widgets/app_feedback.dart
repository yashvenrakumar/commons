import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum FeedbackTone { success, info, warning, error }

class AppFeedback {
  static void showToast(
    BuildContext context, {
    required String message,
    FeedbackTone tone = FeedbackTone.info,
    IconData? icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final (Color bg, Color fg, IconData ic) = switch (tone) {
      FeedbackTone.success => (
        cs.primary.withValues(alpha: 0.92),
        cs.onPrimary,
        icon ?? CupertinoIcons.check_mark_circled_solid,
      ),
      FeedbackTone.info => (
        cs.secondary.withValues(alpha: 0.92),
        cs.onSecondary,
        icon ?? CupertinoIcons.info_circle_fill,
      ),
      FeedbackTone.warning => (
        const Color(0xFFF59E0B),
        Colors.white,
        icon ?? CupertinoIcons.exclamationmark_triangle_fill,
      ),
      FeedbackTone.error => (
        cs.error.withValues(alpha: 0.92),
        cs.onError,
        icon ?? CupertinoIcons.xmark_octagon_fill,
      ),
    };

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        backgroundColor: bg,
        duration: const Duration(milliseconds: 1800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(ic, color: fg, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

