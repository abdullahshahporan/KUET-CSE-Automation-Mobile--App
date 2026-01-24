import 'package:flutter/material.dart';
import '../data/static_data.dart';
import 'widgets/theory_result_card.dart';
import 'widgets/lab_result_card.dart';
import '../../theme/app_colors.dart';

/// Main Result screen displaying student marks
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _selectedYear = 3;
  int _selectedTerm = 2;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          'Results',
          style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Semester selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Academic Results',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currentStudent.formattedBatch,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          'Year',
                          _selectedYear,
                          [1, 2, 3, 4],
                          (value) => setState(() => _selectedYear = value!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          'Term',
                          _selectedTerm,
                          [1, 2],
                          (value) => setState(() => _selectedTerm = value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Check if data available
            if (_selectedYear != 3 || _selectedTerm != 2) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 64,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No results available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Results for this semester will appear here once available.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Theory Results
              Text(
                'Theory Courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
              const SizedBox(height: 16),
              ...sampleTheoryResults.map(
                (result) => TheoryResultCard(result: result),
              ),

              const SizedBox(height: 24),

              // Lab Results
              Text(
                'Lab Courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
              const SizedBox(height: 16),
              ...sampleLabResults.map(
                (result) => LabResultCard(result: result),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    int value,
    List<int> items,
    void Function(int?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          DropdownButton<int>(
            value: value,
            dropdownColor: AppColors.primary,
            underline: const SizedBox(),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            items: items.map((item) {
              final suffix = label == 'Year'
                  ? (item == 1
                        ? 'st'
                        : item == 2
                        ? 'nd'
                        : item == 3
                        ? 'rd'
                        : 'th')
                  : (item == 1 ? 'st' : 'nd');
              return DropdownMenuItem(
                value: item,
                child: Text('$item$suffix $label'),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
