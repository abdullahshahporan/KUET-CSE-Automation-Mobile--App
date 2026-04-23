import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/widgets/dot_grid_painter.dart';
import '../../theme/app_colors.dart';
import 'study_resources_data.dart';

class ResourceDetailScreen extends StatefulWidget {
  const ResourceDetailScreen({
    super.key,
    required this.category,
    required this.item,
  });

  final StudyResourceCategory category;
  final StudyResourceItem item;

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  bool _isSaved = false;

  void _showStatusMessage(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label for "${widget.item.title}" is coming soon.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final relatedItems = widget.category.items
        .where((candidate) => candidate.id != widget.item.id)
        .take(2)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        foregroundColor: AppColors.textPrimary(isDark),
        title: Text(
          widget.category.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: _isSaved ? 'Remove bookmark' : 'Save resource',
            onPressed: () {
              setState(() {
                _isSaved = !_isSaved;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isSaved
                        ? 'Saved to your study list.'
                        : 'Removed from your study list.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isSaved
                  ? widget.category.accentColor
                  : AppColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: DotGridPainter(
                dotColor: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: isDark ? 0.05 : 0.035,
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -60,
            child: _GlowOrb(
              color: widget.category.accentColor.withValues(alpha: 0.18),
              size: 220,
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: _GlowOrb(
              color: widget.category.gradientColors.last.withValues(alpha: 0.1),
              size: 180,
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'resource-item-${widget.item.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.category.gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: widget.category.accentColor.withValues(
                              alpha: 0.24,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  widget.item.courseCode,
                                  style: GoogleFonts.ibmPlexMono(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  widget.category.icon,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            widget.item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.item.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _MetaPill(
                                icon: Icons.category_rounded,
                                label: widget.item.formatLabel,
                              ),
                              _MetaPill(
                                icon: Icons.layers_rounded,
                                label: widget.item.sizeLabel,
                              ),
                              _MetaPill(
                                icon: Icons.schedule_rounded,
                                label: widget.item.updatedLabel,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            widget.item.contributor,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showStatusMessage('Preview'),
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('Open Preview'),
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.category.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showStatusMessage('Download'),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary(isDark),
                          side: BorderSide(color: AppColors.border(isDark)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Overview',
                  icon: Icons.menu_book_rounded,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: widget.item.tags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.category.accentColor.withValues(
                                    alpha: isDark ? 0.18 : 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: widget.category.accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'What It Covers',
                  icon: Icons.checklist_rounded,
                  isDark: isDark,
                  child: Column(
                    children: widget.item.coverage
                        .map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: widget.category.accentColor
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.done_rounded,
                                    size: 14,
                                    color: widget.category.accentColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: AppColors.textPrimary(isDark),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Quick Facts',
                  icon: Icons.insights_rounded,
                  isDark: isDark,
                  child: Column(
                    children: [
                      _FactRow(
                        label: 'Category',
                        value: widget.category.title,
                        isDark: isDark,
                      ),
                      _FactRow(
                        label: 'Term',
                        value: widget.item.termLabel,
                        isDark: isDark,
                      ),
                      _FactRow(
                        label: 'Format',
                        value: widget.item.formatLabel,
                        isDark: isDark,
                      ),
                      _FactRow(
                        label: 'Maintained by',
                        value: widget.item.contributor,
                        isDark: isDark,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                if (relatedItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Related Materials',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: relatedItems
                        .map(
                          (related) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ResourceDetailScreen(
                                      category: widget.category,
                                      item: related,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated(isDark),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.border(isDark),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: widget.category.accentColor
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        widget.category.icon,
                                        color: widget.category.accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            related.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary(
                                                isDark,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            related.subtitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.textSecondary(
                                                isDark,
                                              ),
                                              fontSize: 12,
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: AppColors.textSecondary(isDark),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.child,
  });

  final String title;
  final IconData icon;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isDark;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: AppColors.border(isDark)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
