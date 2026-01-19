import 'package:flutter/material.dart';
import '../../Student Folder/data/teacher_static_data.dart';
import '../../theme/app_colors.dart';

/// Marks Overview screen with premium dark UI
class MarksOverviewScreen extends StatefulWidget {
  final TeacherCourse course;

  const MarksOverviewScreen({super.key, required this.course});

  @override
  State<MarksOverviewScreen> createState() => _MarksOverviewScreenState();
}

class _MarksOverviewScreenState extends State<MarksOverviewScreen> {
  String _selectedSection = 'A';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final grades = sampleTheoryGrades.where((g) {
      final rollNum = int.parse(g.roll.substring(4));
      return _selectedSection == 'A' ? rollNum <= 60 : rollNum > 60;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          '${widget.course.code} Overview',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated(isDarkMode),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.share_outlined, color: AppColors.textSecondary(isDarkMode), size: 20),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Export feature coming soon!'),
                  backgroundColor: AppColors.info,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Section Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(isDarkMode),
              border: Border(
                bottom: BorderSide(color: AppColors.border(isDarkMode)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Section:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                const SizedBox(width: 12),
                _buildSectionChip('A', isDarkMode),
                const SizedBox(width: 8),
                _buildSectionChip('B', isDarkMode),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${grades.length} Students',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Data Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    AppColors.surfaceElevated(isDarkMode),
                  ),
                  dataRowColor: MaterialStateProperty.all(
                    AppColors.surface(isDarkMode),
                  ),
                  border: TableBorder.all(
                    color: AppColors.border(isDarkMode),
                    width: 0.5,
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        'Roll',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'CT-1\n(20)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'CT-2\n(10)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Spot\n(5)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Assign\n(5)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Attend\n(10)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Total\n(50)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                      numeric: true,
                    ),
                  ],
                  rows: grades.map((grade) {
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          grade.roll.substring(grade.roll.length - 3),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(isDarkMode),
                          ),
                        )),
                        DataCell(_buildMarksCell(grade.ct1, 20)),
                        DataCell(_buildMarksCell(grade.ct2, 10)),
                        DataCell(_buildMarksCell(grade.spotTest, 5)),
                        DataCell(_buildMarksCell(grade.assignment, 5)),
                        DataCell(_buildMarksCell(grade.attendance, 10)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (grade.caTotal >= 40
                                      ? AppColors.success
                                      : grade.caTotal >= 30
                                          ? AppColors.warning
                                          : AppColors.danger)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              grade.caTotal.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: grade.caTotal >= 40
                                    ? AppColors.success
                                    : grade.caTotal >= 30
                                        ? AppColors.warning
                                        : AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface(isDarkMode),
              border: Border(
                top: BorderSide(color: AppColors.border(isDarkMode)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Average', _calculateAverage(grades), AppColors.primary, isDarkMode),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.border(isDarkMode),
                ),
                _buildSummaryItem('Highest', _calculateHighest(grades), AppColors.success, isDarkMode),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.border(isDarkMode),
                ),
                _buildSummaryItem('Lowest', _calculateLowest(grades), AppColors.danger, isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionChip(String section, bool isDarkMode) {
    final isSelected = _selectedSection == section;
    return GestureDetector(
      onTap: () => setState(() => _selectedSection = section),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated(isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border(isDarkMode),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          section,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary(isDarkMode),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMarksCell(double marks, double max) {
    final percentage = marks / max;
    return Text(
      marks.toStringAsFixed(1),
      style: TextStyle(
        color: percentage >= 0.8
            ? AppColors.success
            : percentage >= 0.5
                ? AppColors.warning
                : AppColors.danger,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color, bool isDarkMode) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  double _calculateAverage(List<TheoryGrades> grades) {
    if (grades.isEmpty) return 0;
    return grades.map((g) => g.caTotal).reduce((a, b) => a + b) / grades.length;
  }

  double _calculateHighest(List<TheoryGrades> grades) {
    if (grades.isEmpty) return 0;
    return grades.map((g) => g.caTotal).reduce((a, b) => a > b ? a : b);
  }

  double _calculateLowest(List<TheoryGrades> grades) {
    if (grades.isEmpty) return 0;
    return grades.map((g) => g.caTotal).reduce((a, b) => a < b ? a : b);
  }
}
