import 'package:flutter/material.dart';
import '../data/static_data.dart';
import 'widgets/theory_result_card.dart';
import 'widgets/lab_result_card.dart';

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
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Results'),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black87,
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
                  colors: [Colors.indigo[600]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.3),
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
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No results available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Results for this semester will appear here once available.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
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
                  color: isDarkMode ? Colors.white : Colors.black87,
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
                  color: isDarkMode ? Colors.white : Colors.black87,
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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          DropdownButton<int>(
            value: value,
            dropdownColor: Colors.indigo[700],
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
                  ? (item == 1 ? 'st' : item == 2 ? 'nd' : item == 3 ? 'rd' : 'th')
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
