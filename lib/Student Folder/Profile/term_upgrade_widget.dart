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

/// A tile widget that shows "Upgrade Term" request in the profile.
/// Loads pending request status and handles the request dialog.
class UpgradeTermTile extends StatefulWidget {
  final String currentTerm;
  final bool isDarkMode;

  /// Called after a successful request so the parent can reload.
  final VoidCallback onUpgraded;

  const UpgradeTermTile({
    super.key,
    required this.currentTerm,
    required this.isDarkMode,
    required this.onUpgraded,
  });

  @override
  State<UpgradeTermTile> createState() => _UpgradeTermTileState();
}

class _UpgradeTermTileState extends State<UpgradeTermTile> {
  Map<String, dynamic>? _latestRequest;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequestStatus();
  }

  @override
  void didUpdateWidget(covariant UpgradeTermTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTerm != widget.currentTerm) {
      _loadRequestStatus();
    }
  }

  Future<void> _loadRequestStatus() async {
    final request = await SupabaseService.getLatestTermUpgradeRequest();
    if (mounted) setState(() { _latestRequest = request; _isLoading = false; });
  }

  /// Determine the effective status to show.
  /// If the latest request's `requested_term` doesn't match the next term
  /// (e.g. user was already upgraded past that), treat it as no-request.
  String? get _effectiveStatus {
    if (_latestRequest == null) return null;
    final nextTerm = TermUtils.getNextTerm(widget.currentTerm);
    if (nextTerm == null) return null;
    final reqTerm = _latestRequest!['requested_term'] as String?;
    if (reqTerm != nextTerm) return null; // stale request
    return _latestRequest!['status'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final nextTerm = TermUtils.getNextTerm(widget.currentTerm);
    final status = _effectiveStatus;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    // Already at max term
    if (nextTerm == null) {
      return _buildRow(
        icon: Icons.check_circle_outline,
        iconColor: Colors.grey,
        bgColor: Colors.grey,
        title: 'Upgrade Term',
        subtitle: 'You are at the final term',
        trailing: null,
        onTap: null,
      );
    }

    // Pending request
    if (status == 'pending') {
      return _buildRow(
        icon: Icons.hourglass_top_rounded,
        iconColor: Colors.amber[700]!,
        bgColor: Colors.amber,
        title: 'Upgrade Request Pending',
        subtitle: 'Awaiting admin approval for ${TermUtils.displayString(nextTerm)}',
        trailing: _statusChip('Pending', Colors.amber[700]!),
        onTap: null,
      );
    }

    // Rejected — allow re-request
    if (status == 'rejected') {
      final remarks = _latestRequest?['admin_remarks'] as String?;
      return _buildRow(
        icon: Icons.cancel_outlined,
        iconColor: Colors.red[600]!,
        bgColor: Colors.red,
        title: 'Request Rejected',
        subtitle: remarks != null && remarks.isNotEmpty
            ? 'Reason: $remarks'
            : 'Tap to send a new request',
        trailing: _statusChip('Rejected', Colors.red[600]!),
        onTap: () => _showRequestDialog(context, nextTerm),
      );
    }

    // No request or approved (approved means already upgraded by admin,
    // currentTerm will have changed so this is effectively "no request").
    return _buildRow(
      icon: Icons.upgrade_rounded,
      iconColor: Colors.orange[700]!,
      bgColor: Colors.orange,
      title: 'Request Term Upgrade',
      subtitle: 'Move to ${TermUtils.displayString(nextTerm)}',
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.orange[700]),
      onTap: () => _showRequestDialog(context, nextTerm),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required Widget? trailing,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Request Dialog
  // ---------------------------------------------------------------------------

  Future<void> _showRequestDialog(BuildContext context, String nextTerm) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.upgrade_rounded, color: Colors.orange[700], size: 28),
            const SizedBox(width: 10),
            Text(
              'Request Upgrade',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your request will be sent to an admin for approval.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'You are requesting to upgrade your term:',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 14),
              // From → To badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: _termBadge(TermUtils.displayString(widget.currentTerm), Colors.blue)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Flexible(child: _termBadge(TermUtils.displayString(nextTerm), Colors.green)),
                ],
              ),
              const SizedBox(height: 18),
              // Reason field (optional)
              Text(
                'Reason (optional):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Completed all exams for the current term',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: widget.isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange[700]!),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              // Caution
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Once approved, this action cannot be reversed. '
                        'Your schedule, courses, and academic data will update accordingly.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Send Request', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final reason = reasonController.text.trim();
      final success = await SupabaseService.submitTermUpgradeRequest(
        currentTerm: widget.currentTerm,
        requestedTerm: nextTerm,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (context.mounted) {
        if (success) {
          await _loadRequestStatus();
          widget.onUpgraded();
          showResultSnackBar(
            context,
            success: true,
            message: 'Upgrade request sent! Awaiting admin approval.',
          );
        } else {
          showResultSnackBar(
            context,
            success: false,
            message: 'Failed to send request. Try again.',
          );
        }
      }
    }

    reasonController.dispose();
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
