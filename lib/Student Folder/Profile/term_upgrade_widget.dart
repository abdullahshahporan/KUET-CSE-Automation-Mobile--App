import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../shared/profile_widgets.dart';

/// Utility helpers for term display and logic.
class TermUtils {
  /// Term order: 1-1 → 1-2 → 2-1 → 2-2 → 3-1 → 3-2 → 4-1 → 4-2
  static String? getNextTerm(String currentTerm) {
    final parts = currentTerm.split('-');
    final year = int.tryParse(parts[0]) ?? 1;
    final sem = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;

    if (sem == 1) return '$year-2';
    if (year < 4) return '${year + 1}-1';
    return null; // Already at 4-2 (max)
  }

  /// "3-2" → "3rd Year, 2nd Term"
  static String displayString(String term) {
    final parts = term.split('-');
    final y = int.tryParse(parts[0]) ?? 1;
    final s = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    const yearSuffix = {1: 'st', 2: 'nd', 3: 'rd', 4: 'th'};
    const semSuffix = {1: 'st', 2: 'nd'};
    return '${y}${yearSuffix[y]} Year, ${s}${semSuffix[s]} Term';
  }
}

/// A tile widget that shows "Upgrade Term" in the profile.
/// Handles the confirmation dialog and Supabase update.
class UpgradeTermTile extends StatelessWidget {
  final String currentTerm;
  final bool isDarkMode;

  /// Called after a successful upgrade so the parent can reload.
  final VoidCallback onUpgraded;

  const UpgradeTermTile({
    super.key,
    required this.currentTerm,
    required this.isDarkMode,
    required this.onUpgraded,
  });

  @override
  Widget build(BuildContext context) {
    final nextTerm = TermUtils.getNextTerm(currentTerm);

    return InkWell(
      onTap: nextTerm == null
          ? null
          : () => _showUpgradeDialog(context, nextTerm),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: nextTerm != null
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.upgrade_rounded,
                color: nextTerm != null ? Colors.orange[700] : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade Term',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextTerm != null
                        ? 'Move to ${TermUtils.displayString(nextTerm)}'
                        : 'You are at the final term',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (nextTerm != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.orange[700],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpgradeDialog(BuildContext context, String nextTerm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange[700], size: 28),
            const SizedBox(width: 10),
            Text(
              'Upgrade Term',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'You are about to upgrade your term:',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 14),
            // From → To badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _termBadge(TermUtils.displayString(currentTerm), Colors.blue),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward_rounded, color: Colors.orange[700]),
                const SizedBox(width: 12),
                _termBadge(TermUtils.displayString(nextTerm), Colors.green),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Once upgraded, you cannot go back to a previous term. '
              'Your schedule, courses, and other academic data will update accordingly.',
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Upgrade',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await SupabaseService.updateStudentTerm(nextTerm);
      if (context.mounted) {
        if (success) {
          onUpgraded();
          showResultSnackBar(
            context,
            success: true,
            message:
                'Term upgraded to ${TermUtils.displayString(nextTerm)}!',
          );
        } else {
          showResultSnackBar(
            context,
            success: false,
            message: 'Failed to upgrade term. Try again.',
          );
        }
      }
    }
  }

  Widget _termBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
