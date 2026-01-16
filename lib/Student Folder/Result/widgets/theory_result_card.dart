import 'package:flutter/material.dart';
import '../../models/result_model.dart';

/// Card widget displaying theory course result
class TheoryResultCard extends StatelessWidget {
  final TheoryResult result;

  const TheoryResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.cyan[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.courseCode,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.courseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Tests
                Text(
                  'Class Tests',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (int i = 0; i < result.classTests.length; i++) ...[
                      Expanded(
                        child: _buildScoreBox(
                          'CT${i + 1}',
                          result.classTests[i],
                          20,
                          isDarkMode,
                        ),
                      ),
                      if (i < result.classTests.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Other scores
                Row(
                  children: [
                    Expanded(
                      child: _buildScoreBox(
                        'Attendance',
                        result.attendance,
                        10,
                        isDarkMode,
                      ),
                    ),
                    if (result.assignment != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildScoreBox(
                          'Assignment',
                          result.assignment!,
                          10,
                          isDarkMode,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Total CA
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Continuous Assessment',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${result.continuousAssessment.toStringAsFixed(1)}/90',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBox(String label, double score, double max, bool isDarkMode) {
    final percentage = score / max;
    Color color;
    if (percentage >= 0.8) {
      color = Colors.green;
    } else if (percentage >= 0.6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '/${max.toInt()}',
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
