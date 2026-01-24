import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class FacultyInfoScreen extends StatelessWidget {
  const FacultyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary(isDarkMode),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Faculty Information',
          style: TextStyle(
            color: AppColors.textPrimary(isDarkMode),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Head of Department
          _buildSectionHeader('Head of the Department', isDarkMode),
          _buildFacultyCard(
            name: 'Dr. Al-Mahmud',
            designation: 'Professor',
            email: 'mahmud@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 24),

          // Professors
          _buildSectionHeader('Professors', isDarkMode),
          _buildFacultyCard(
            name: 'Dr. M.M.A. Hashem',
            designation: 'Professor',
            email: 'hashem@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Dr. K. M. Azharul Hasan',
            designation: 'Professor',
            email: 'az@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Dr. Kazi Md. Rokibul Alam',
            designation: 'Professor',
            email: 'rokib@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Dr. Muhammad Sheikh Sadi',
            designation: 'Professor',
            email: 'sadi@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Dr. Muhammad Aminul Haque Akhand',
            designation: 'Professor',
            email: 'akhand@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Dr. Pintu Chandra Shill',
            designation: 'Professor',
            email: 'pintu@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 24),

          // Assistant Professors
          _buildSectionHeader('Assistant Professors', isDarkMode),
          _buildFacultyCard(
            name: 'Md. Abdus Salim Mollah',
            designation: 'Assistant Professor',
            email: 'salim9326@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Dr. Md. Milon Islam',
            designation: 'Assistant Professor',
            email: 'milonislam@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Dola Das',
            designation: 'Assistant Professor',
            email: 'dola.das@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Kazi Saeed Alam',
            designation: 'Assistant Professor',
            email: 'saeed.alam@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Md. Repon Islam',
            designation: 'Assistant Professor',
            email: 'repon@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Md. Sakhawat Hossain',
            designation: 'Assistant Professor',
            email: 'sakhawat@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 24),

          // Lecturers
          _buildSectionHeader('Lecturers', isDarkMode),
          _buildFacultyCard(
            name: 'Md Nazirulhasan Shawon',
            designation: 'Lecturer',
            email: 'shawon@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Md. Badiuzzaman Shuvo',
            designation: 'Lecturer',
            email: 'badiuzzaman@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Most. Kaniz Fatema Isha',
            designation: 'Lecturer',
            email: 'isha@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Safin Ahmmed',
            designation: 'Lecturer',
            email: 'safinahmmed@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Md Mehrab Hossain Opi',
            designation: 'Lecturer',
            email: 'opi@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Md Tajmilur Rahman',
            designation: 'Lecturer',
            email: 'tajmilur@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 24),

          // Faculty on Leave
          _buildSectionHeader('Faculty on Leave', isDarkMode),
          _buildFacultyCard(
            name: 'Mehanuma Tabassum Omar',
            designation: 'Assistant Professor',
            email: 'tabassum@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Jakaria Rabbi',
            designation: 'Assistant Professor',
            email: 'jakaria_rabbi@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Md. Abdul Awal',
            designation: 'Assistant Professor',
            email: 'awal@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Mohammad Insanur Rahman Shuvo',
            designation: 'Assistant Professor',
            email: 'insan_shuvo@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Animesh Kumar Paul',
            designation: 'Assistant Professor',
            email: 'animesh.paul@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
          _buildFacultyCard(
            name: 'Abdul Aziz',
            designation: 'Assistant Professor',
            email: 'abdulaziz@cse.kuet.ac.bd',
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary(isDarkMode),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFacultyCard({
    required String name,
    required String designation,
    required String email,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(isDarkMode),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  designation,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
