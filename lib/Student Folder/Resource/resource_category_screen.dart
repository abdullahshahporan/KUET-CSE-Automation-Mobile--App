import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/widgets/dot_grid_painter.dart';
import '../../theme/app_colors.dart';
import 'resource_detail_screen.dart';
import 'study_resources_data.dart';

enum _ResourceFilter { all, featured, recent, popular }

class ResourceCategoryScreen extends StatefulWidget {
  const ResourceCategoryScreen({super.key, required this.category});

  final StudyResourceCategory category;

  @override
  State<ResourceCategoryScreen> createState() => _ResourceCategoryScreenState();
}

class _ResourceCategoryScreenState extends State<ResourceCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  _ResourceFilter _selectedFilter = _ResourceFilter.all;

  List<StudyResourceItem> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();

    return widget.category.items.where((item) {
      final matchesQuery = query.isEmpty || item.searchIndex.contains(query);
      final matchesFilter = switch (_selectedFilter) {
        _ResourceFilter.all => true,
        _ResourceFilter.featured => item.isFeatured,
        _ResourceFilter.recent => item.isRecent,
        _ResourceFilter.popular => item.isPopular,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredItems = _filteredItems;

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
            top: -80,
            right: -40,
            child: _GlowOrb(
              color: widget.category.accentColor.withValues(alpha: 0.18),
              size: 220,
            ),
          ),
          Positioned(
            top: 180,
            left: -50,
            child: _GlowOrb(
              color: widget.category.gradientColors.last.withValues(alpha: 0.1),
              size: 180,
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
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
                                alpha: 0.2,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Hero(
                                  tag:
                                      'resource-category-${widget.category.id}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.16,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(
                                        widget.category.icon,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
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
                                    '${widget.category.totalItems} materials',
                                    style: GoogleFonts.ibmPlexMono(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              widget.category.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.category.summary,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.86),
                                fontSize: 14,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _MetricPill(
                                  label:
                                      '${widget.category.featuredCount} featured',
                                ),
                                _MetricPill(
                                  label:
                                      '${widget.category.recentCount} recently updated',
                                ),
                                ...widget.category.highlights
                                    .take(1)
                                    .map((text) => _MetricPill(label: text)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated(isDark),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.border(isDark)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.textSecondary(isDark),
                            ),
                            hintText: 'Search by course, topic, or tag',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary(isDark),
                            ),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildFilterChip(
                            label: 'All',
                            selected: _selectedFilter == _ResourceFilter.all,
                            onTap: () {
                              setState(() {
                                _selectedFilter = _ResourceFilter.all;
                              });
                            },
                            isDark: isDark,
                          ),
                          _buildFilterChip(
                            label: 'Featured',
                            selected:
                                _selectedFilter == _ResourceFilter.featured,
                            onTap: () {
                              setState(() {
                                _selectedFilter = _ResourceFilter.featured;
                              });
                            },
                            isDark: isDark,
                          ),
                          _buildFilterChip(
                            label: 'Recent',
                            selected: _selectedFilter == _ResourceFilter.recent,
                            onTap: () {
                              setState(() {
                                _selectedFilter = _ResourceFilter.recent;
                              });
                            },
                            isDark: isDark,
                          ),
                          _buildFilterChip(
                            label: 'Popular',
                            selected:
                                _selectedFilter == _ResourceFilter.popular,
                            onTap: () {
                              setState(() {
                                _selectedFilter = _ResourceFilter.popular;
                              });
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${filteredItems.length} resources available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap any item to open the full resource view.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (filteredItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: widget.category.accentColor.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_off_rounded,
                              size: 32,
                              color: widget.category.accentColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No study resources matched your search.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(isDark),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different course code, topic keyword, or filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary(isDark),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  sliver: SliverList.separated(
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ResourceDetailScreen(
                                category: widget.category,
                                item: item,
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'resource-item-${item.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated(isDark),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.border(isDark),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadow(
                                      isDark,
                                    ).withValues(alpha: isDark ? 0.18 : 0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: widget.category.accentColor
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                                              item.courseCode,
                                              style: GoogleFonts.ibmPlexMono(
                                                color:
                                                    widget.category.accentColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item.title,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary(
                                                  isDark,
                                                ),
                                                height: 1.2,
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
                                  const SizedBox(height: 14),
                                  Text(
                                    item.subtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.55,
                                      color: AppColors.textSecondary(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _ItemMetaChip(
                                        icon: Icons.view_agenda_rounded,
                                        label: item.formatLabel,
                                        isDark: isDark,
                                      ),
                                      _ItemMetaChip(
                                        icon: Icons.layers_rounded,
                                        label: item.sizeLabel,
                                        isDark: isDark,
                                      ),
                                      _ItemMetaChip(
                                        icon: Icons.school_rounded,
                                        label: item.termLabel,
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (item.isFeatured)
                                        _StatusBadge(
                                          label: 'Featured',
                                          color: widget.category.accentColor,
                                        ),
                                      if (item.isRecent)
                                        const _StatusBadge(
                                          label: 'Recent',
                                          color: AppColors.success,
                                        ),
                                      if (item.isPopular)
                                        const _StatusBadge(
                                          label: 'Popular',
                                          color: AppColors.warning,
                                        ),
                                      ...item.tags
                                          .take(2)
                                          .map(
                                            (tag) => _OutlineBadge(
                                              label: tag,
                                              isDark: isDark,
                                            ),
                                          ),
                                    ],
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? widget.category.accentColor
              : AppColors.surfaceElevated(isDark),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? widget.category.accentColor
                : AppColors.border(isDark),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary(isDark),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OutlineBadge extends StatelessWidget {
  const _OutlineBadge({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary(isDark),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ItemMetaChip extends StatelessWidget {
  const _ItemMetaChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.75)
            : const Color(0xFFF6FBFB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary(isDark)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
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
