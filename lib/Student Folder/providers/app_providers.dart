import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuet_cse_automation/Student%20Folder/models/app_models.dart';

// Notices Provider — sample static data (to be migrated to Supabase later)
final noticesProvider = Provider<List<Notice>>((ref) {
  return [
    Notice(
      id: '1',
      title: 'Mid-Term Exam Schedule Published',
      description:
          'The mid-term examination schedule for Spring 2026 semester has been published. Please check your respective class groups.',
      date: 'January 12, 2026',
      category: 'Exam',
      isImportant: true,
    ),
    Notice(
      id: '2',
      title: 'Department Seminar on AI',
      description:
          'A seminar on "Recent Advances in Artificial Intelligence" will be held on January 20, 2026 at 3:00 PM in the seminar hall.',
      date: 'January 10, 2026',
      category: 'Event',
      isImportant: false,
    ),
    Notice(
      id: '3',
      title: 'Lab Report Submission Deadline',
      description:
          'All pending lab reports must be submitted by January 25, 2026. Late submissions will not be accepted.',
      date: 'January 8, 2026',
      category: 'Academic',
      isImportant: true,
    ),
    Notice(
      id: '4',
      title: 'University Closed - National Holiday',
      description:
          'The university will remain closed on January 26, 2026 due to national holiday.',
      date: 'January 5, 2026',
      category: 'Holiday',
      isImportant: false,
    ),
    Notice(
      id: '5',
      title: 'Project Proposal Submission',
      description:
          'Final year students are requested to submit their project proposals by February 1, 2026.',
      date: 'January 3, 2026',
      category: 'Project',
      isImportant: true,
    ),
  ];
});
