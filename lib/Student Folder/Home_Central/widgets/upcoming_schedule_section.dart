import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../services/upcoming_schedule_service.dart';

/// Widget that displays today's remaining classes and the next class day's
/// schedule, fetched from Supabase via [UpcomingScheduleService].
///
/// Shows a shimmer skeleton while loading, an empty-state when there are
/// no upcoming classes, and fully themed cards for each slot.
class UpcomingScheduleSection extends StatefulWidget {
  const UpcomingScheduleSection({super.key});

  @override
  State<UpcomingScheduleSection> createState() =>
      _UpcomingScheduleSectionState();
}

class _UpcomingScheduleSectionState extends State<UpcomingScheduleSection> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = UpcomingScheduleService.getUpcoming();
  }

  void _refresh() {
    setState(() {
      _future = UpcomingScheduleService.getUpcoming();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildShimmer(isDark);
        }

        final data = snap.data ?? UpcomingScheduleService.getUpcoming;
        final today = (snap.data?['today'] as List<UpcomingClass>?) ?? [];
        final tomorrow =
            (snap.data?['tomorrow'] as List<UpcomingClass>?) ?? [];
        final dayLabel = snap.data?['dayLabel'] as String? ?? 'Tomorrow';

        if (today.isEmpty && tomorrow.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section Header ---
            _sectionHeader('Upcoming Classes', isDark, onRefresh: _refresh),
            const SizedBox(height: 14),

            // --- Today ---
            if (today.isNotEmpty) ...[
              _subHeader('Today', Icons.today_rounded, AppColors.primary, isDark),
              const SizedBox(height: 10),
              ...today.map((c) => _ClassCard(item: c, isDark: isDark)),
              const SizedBox(height: 18),
            ],

            // --- Next class day ---
            if (tomorrow.isNotEmpty) ...[
              _subHeader(
                  dayLabel, Icons.event_rounded, AppColors.accent, isDark),
              const SizedBox(height: 10),
              ...tomorrow.map((c) => _ClassCard(item: c, isDark: isDark)),
            ],

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // ──────────────────── Sub-widgets ────────────────────

  Widget _sectionHeader(String title, bool isDark,
      {VoidCallback? onRefresh}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        if (onRefresh != null)
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                size: 20, color: AppColors.textSecondary(isDark)),
            onPressed: onRefresh,
            tooltip: 'Refresh',
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _subHeader(
      String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────── States ────────────────────

  Widget _buildEmptyState(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Upcoming Classes', isDark),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Icon(Icons.event_available_rounded,
                  size: 48,
                  color: AppColors.textSecondary(isDark).withOpacity(0.4)),
              const SizedBox(height: 10),
              Text(
                'No upcoming classes',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(isDark),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Upcoming Classes', isDark),
        const SizedBox(height: 14),
        ..._shimmerCards(3, isDark),
        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _shimmerCards(int count, bool isDark) {
    return List.generate(count, (_) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.surface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(isDark)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.border(isDark),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.border(isDark),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.border(isDark),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ════════════════════════════════════════════════════════
// Individual class card
// ════════════════════════════════════════════════════════

class _ClassCard extends StatelessWidget {
  final UpcomingClass item;
  final bool isDark;

  const _ClassCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _courseColor(item.courseCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isOngoing
              ? color.withOpacity(0.5)
              : AppColors.border(isDark),
          width: item.isOngoing ? 1.5 : 1,
        ),
        boxShadow: item.isOngoing
            ? [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Course icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              _isLab(item.courseCode) ? Icons.science_rounded : Icons.school_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.courseTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isOngoing)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.room} • ${item.teacher}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _shortTime(item.time),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show only the start time portion for compactness.
  String _shortTime(String fullTime) {
    // "10:00 AM - 11:00 AM" → "10:00 AM"
    final dash = fullTime.indexOf('-');
    if (dash > 0) return fullTime.substring(0, dash).trim();
    return fullTime;
  }

  /// Picks a hue based on course code hash.
  Color _courseColor(String code) {
    const palette = [
      Color(0xFF6366F1), // indigo
      Color(0xFF10B981), // emerald
      Color(0xFF8B5CF6), // violet
      Color(0xFF14B8A6), // teal
      Color(0xFFEF4444), // red
      Color(0xFFF59E0B), // amber
      Color(0xFF3B82F6), // blue
      Color(0xFFEC4899), // pink
    ];
    return palette[code.hashCode.abs() % palette.length];
  }

  bool _isLab(String code) {
    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return false;
    return int.parse(digits[digits.length - 1]).isEven;
  }
}
