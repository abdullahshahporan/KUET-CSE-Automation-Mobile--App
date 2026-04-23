import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class StudyResourceCategory {
  const StudyResourceCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    required this.highlights,
    required this.items,
  });

  final String id;
  final String title;
  final String subtitle;
  final String summary;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final List<String> highlights;
  final List<StudyResourceItem> items;

  int get totalItems => items.length;

  int get featuredCount => items.where((item) => item.isFeatured).length;

  int get recentCount => items.where((item) => item.isRecent).length;

  String get searchIndex {
    final itemText = items.map((item) => item.searchIndex).join(' ');
    return '$title $subtitle $summary ${highlights.join(' ')} $itemText'
        .toLowerCase();
  }
}

class StudyResourceItem {
  const StudyResourceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.courseCode,
    required this.contributor,
    required this.termLabel,
    required this.formatLabel,
    required this.sizeLabel,
    required this.updatedLabel,
    required this.description,
    required this.tags,
    required this.coverage,
    this.isFeatured = false,
    this.isRecent = false,
    this.isPopular = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String courseCode;
  final String contributor;
  final String termLabel;
  final String formatLabel;
  final String sizeLabel;
  final String updatedLabel;
  final String description;
  final List<String> tags;
  final List<String> coverage;
  final bool isFeatured;
  final bool isRecent;
  final bool isPopular;

  String get searchIndex {
    return [
      title,
      subtitle,
      courseCode,
      contributor,
      termLabel,
      formatLabel,
      sizeLabel,
      updatedLabel,
      description,
      ...tags,
      ...coverage,
    ].join(' ').toLowerCase();
  }
}

const studyResourceCategories = <StudyResourceCategory>[
  StudyResourceCategory(
    id: 'lecture-notes',
    title: 'Lecture Notes',
    subtitle: 'Curated notes for core theory courses',
    summary:
        'Condensed lecture packs, concept maps, and revision sheets prepared by faculty and senior students.',
    icon: Icons.description_rounded,
    accentColor: AppColors.primary,
    gradientColors: [Color(0xFF009688), Color(0xFF00695C)],
    highlights: ['Revision friendly', 'Semester sorted', 'Faculty approved'],
    items: [
      StudyResourceItem(
        id: 'ln-3107-networking',
        title: 'Computer Networks Layer Guide',
        subtitle: 'OSI, TCP/IP, routing, and subnetting shortcuts',
        courseCode: 'CSE 3107',
        contributor: 'Prepared by Prof. M. Rahman',
        termLabel: '3-1',
        formatLabel: 'PDF notes',
        sizeLabel: '42 pages',
        updatedLabel: 'Updated 2 days ago',
        description:
            'A compact theory set covering layered communication, addressing, switching, and transport-layer design with common exam questions.',
        tags: ['Featured', 'Networking', 'Exam prep', 'Theory'],
        coverage: [
          'OSI vs TCP/IP mapping',
          'Subnetting drills and routing basics',
          'Transport protocols and congestion control',
        ],
        isFeatured: true,
        isRecent: true,
        isPopular: true,
      ),
      StudyResourceItem(
        id: 'ln-3201-os',
        title: 'Operating Systems Process Notes',
        subtitle: 'Process states, scheduling, deadlocks, and memory',
        courseCode: 'CSE 3201',
        contributor: 'Compiled by Batch 19 study group',
        termLabel: '3-2',
        formatLabel: 'Slide digest',
        sizeLabel: '28 slides',
        updatedLabel: 'Updated this week',
        description:
            'A revision-focused pack that turns the full OS slide deck into digestible summaries with tables and quick comparisons.',
        tags: ['Recent', 'OS', 'Slides', 'Revision'],
        coverage: [
          'CPU scheduling comparison table',
          'Deadlock conditions and prevention',
          'Paging, segmentation, and memory allocation',
        ],
        isRecent: true,
        isPopular: true,
      ),
      StudyResourceItem(
        id: 'ln-2105-dbms',
        title: 'DBMS Midterm Notebook',
        subtitle: 'Relational algebra, normalization, and transactions',
        courseCode: 'CSE 2105',
        contributor: 'Prepared by Lecturer Tasnia Karim',
        termLabel: '2-1',
        formatLabel: 'Annotated PDF',
        sizeLabel: '36 pages',
        updatedLabel: 'Updated 1 week ago',
        description:
            'Semester-ready notes with solved examples on ER modeling, relational algebra, normal forms, and concurrency control.',
        tags: ['DBMS', 'Solved examples', 'Midterm'],
        coverage: [
          'Entity relationship modeling rules',
          'Normalization workflow with examples',
          'ACID properties and transaction schedules',
        ],
      ),
      StudyResourceItem(
        id: 'ln-2203-dsa',
        title: 'Data Structures Revision Sheets',
        subtitle: 'Trees, graphs, complexity, and sorting at a glance',
        courseCode: 'CSE 2203',
        contributor: 'Senior mentor archive',
        termLabel: '2-2',
        formatLabel: 'Quick sheets',
        sizeLabel: '18 pages',
        updatedLabel: 'Updated 10 days ago',
        description:
            'Last-minute revision material for DSA that prioritizes patterns, time complexity intuition, and common viva prompts.',
        tags: ['DSA', 'Quick revision', 'Popular'],
        coverage: [
          'Complexity cheat table',
          'Tree traversal patterns',
          'Shortest path and MST problem types',
        ],
        isPopular: true,
      ),
    ],
  ),
  StudyResourceCategory(
    id: 'previous-papers',
    title: 'Previous Papers',
    subtitle: 'Past exam questions and solved archives',
    summary:
        'Midterm, CT, and final papers collected semester by semester with tagging for solved sets and faculty patterns.',
    icon: Icons.quiz_rounded,
    accentColor: AppColors.warning,
    gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    highlights: ['Solved sets', 'CT + final', 'Faculty pattern tracking'],
    items: [
      StudyResourceItem(
        id: 'pp-3201-os-final',
        title: 'Operating Systems Final Archive',
        subtitle: 'Five semesters of final questions with topic tags',
        courseCode: 'CSE 3201',
        contributor: 'Collected by KUET CSE resource desk',
        termLabel: '3-2',
        formatLabel: 'Question bank',
        sizeLabel: '5 papers',
        updatedLabel: 'Updated yesterday',
        description:
            'A consolidated archive of OS final questions with recurrence frequency and marking pattern hints for major chapters.',
        tags: ['Featured', 'Solved index', 'Final exam'],
        coverage: [
          'Process and thread theory questions',
          'Memory management problem patterns',
          'Deadlock and synchronization derivations',
        ],
        isFeatured: true,
        isRecent: true,
        isPopular: true,
      ),
      StudyResourceItem(
        id: 'pp-2105-dbms-ct',
        title: 'DBMS CT Question Sets',
        subtitle: 'Class tests and model answers from recent batches',
        courseCode: 'CSE 2105',
        contributor: 'Batch 20 CR collection',
        termLabel: '2-1',
        formatLabel: 'Scanned PDFs',
        sizeLabel: '9 sets',
        updatedLabel: 'Updated 3 days ago',
        description:
            'A lightweight archive of CT papers, short answer patterns, and instructor-specific preference notes.',
        tags: ['Recent', 'CT', 'Scanned'],
        coverage: [
          'Short relational algebra questions',
          'ER to relation conversion prompts',
          'Normalization mini problems',
        ],
        isRecent: true,
      ),
      StudyResourceItem(
        id: 'pp-2203-dsa-mid',
        title: 'DSA Midterm Paper Pack',
        subtitle: 'Previous mids on recursion, trees, and graph basics',
        courseCode: 'CSE 2203',
        contributor: 'Academic support cell',
        termLabel: '2-2',
        formatLabel: 'PDF bundle',
        sizeLabel: '7 papers',
        updatedLabel: 'Updated 6 days ago',
        description:
            'Well-organized midterm archive for DSA with handwritten solution pointers and topic frequency labels.',
        tags: ['DSA', 'Midterm', 'Solutions'],
        coverage: [
          'Recursion tracing problems',
          'Binary tree and BST questions',
          'Graph traversal and shortest path basics',
        ],
        isPopular: true,
      ),
      StudyResourceItem(
        id: 'pp-4105-ml-final',
        title: 'Machine Learning Final Trends',
        subtitle: 'Past finals mapped to units and study priority',
        courseCode: 'CSE 4105',
        contributor: 'Prepared by AI elective mentors',
        termLabel: '4-1',
        formatLabel: 'Trend report',
        sizeLabel: '12 pages',
        updatedLabel: 'Updated 2 weeks ago',
        description:
            'A final prep sheet that maps previous machine learning questions to unit-wise study recommendations and likely repeats.',
        tags: ['Elective', 'Trend analysis', 'Final'],
        coverage: [
          'Regression and classification themes',
          'Evaluation metric comparisons',
          'Neural network short notes',
        ],
      ),
    ],
  ),
  StudyResourceCategory(
    id: 'ebooks',
    title: 'E-Books',
    subtitle: 'Reference books and chapter-based reading packs',
    summary:
        'Foundational textbooks, quick reference books, and chapter extracts mapped to the department curriculum.',
    icon: Icons.book_rounded,
    accentColor: AppColors.success,
    gradientColors: [Color(0xFF22C55E), Color(0xFF15803D)],
    highlights: ['Reference shelf', 'Chapter indexed', 'Offline friendly'],
    items: [
      StudyResourceItem(
        id: 'eb-os-concepts',
        title: 'Operating System Concepts',
        subtitle: 'Selected chapters with highlighted reading path',
        courseCode: 'CSE 3201',
        contributor: 'Reference edition by Silberschatz et al.',
        termLabel: '3-2',
        formatLabel: 'PDF book',
        sizeLabel: '11 chapters',
        updatedLabel: 'Updated 4 days ago',
        description:
            'A guided reading pack that links the standard textbook to the KUET course outline and exam-heavy sections.',
        tags: ['Featured', 'Reference', 'Textbook'],
        coverage: [
          'Process management and scheduling',
          'Memory, virtual memory, and storage',
          'File systems and protection',
        ],
        isFeatured: true,
        isPopular: true,
      ),
      StudyResourceItem(
        id: 'eb-clrs-algo',
        title: 'Introduction to Algorithms Reading Plan',
        subtitle: 'Core CLRS chapters for algorithms and data structures',
        courseCode: 'CSE 2203',
        contributor: 'Department reference library',
        termLabel: '2-2',
        formatLabel: 'Chapter set',
        sizeLabel: '9 chapters',
        updatedLabel: 'Updated this week',
        description:
            'A chapter-by-chapter reading route for algorithm design, analysis, graph algorithms, greedy methods, and dynamic programming.',
        tags: ['Recent', 'Algorithms', 'Reference'],
        coverage: [
          'Asymptotic analysis and recurrences',
          'Greedy and dynamic programming',
          'Graph algorithms and shortest paths',
        ],
        isRecent: true,
        isPopular: true,
      ),
      StudyResourceItem(
        id: 'eb-clean-code',
        title: 'Clean Code Essentials',
        subtitle: 'Software engineering reading for project work',
        courseCode: 'CSE 3103',
        contributor: 'Software project studio shelf',
        termLabel: '3-1',
        formatLabel: 'ePub summary',
        sizeLabel: '14 chapters',
        updatedLabel: 'Updated 1 week ago',
        description:
            'A curated software engineering reading list on naming, modular design, testing, refactoring, and maintainable project habits.',
        tags: ['Software engineering', 'Project', 'Best practices'],
        coverage: [
          'Meaningful naming and small functions',
          'Code smells and refactoring habits',
          'Testing discipline and maintainability',
        ],
      ),
      StudyResourceItem(
        id: 'eb-cn-topdown',
        title: 'Computer Networking Top-Down Notes',
        subtitle: 'Textbook companion for the networking theory course',
        courseCode: 'CSE 3107',
        contributor: 'Supplementary reading archive',
        termLabel: '3-1',
        formatLabel: 'Companion book',
        sizeLabel: '8 chapters',
        updatedLabel: 'Updated 9 days ago',
        description:
            'A companion reading set for networking that aligns chapter priority with the department syllabus and class lecture order.',
        tags: ['Networking', 'Companion', 'Readable'],
        coverage: [
          'Application and transport layer flow',
          'Routing and network layer concepts',
          'Link layer and wireless overview',
        ],
      ),
    ],
  ),
  StudyResourceCategory(
    id: 'video-lectures',
    title: 'Video Lectures',
    subtitle: 'Recorded classes, walkthroughs, and revision explainers',
    summary:
        'Short explainers and full recorded sessions with topic markers for lab work, tricky theory, and revision nights.',
    icon: Icons.ondemand_video_rounded,
    accentColor: AppColors.danger,
    gradientColors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    highlights: ['Topic markers', 'Recorded classes', 'Watch later'],
    items: [
      StudyResourceItem(
        id: 'vl-dsa-greedy',
        title: 'Greedy vs Dynamic Programming Clinic',
        subtitle: 'Problem-solving session with worked examples',
        courseCode: 'CSE 2203',
        contributor: 'Recorded by Dept. academic support team',
        termLabel: '2-2',
        formatLabel: 'Video lecture',
        sizeLabel: '48 min',
        updatedLabel: 'Updated today',
        description:
            'A focused walkthrough on how to distinguish greedy approaches from dynamic programming, with common pitfalls and sample problems.',
        tags: ['Featured', 'DSA', 'Problem solving'],
        coverage: [
          'Choice property and proof intuition',
          'Counterexamples for invalid greedy picks',
          'Dynamic programming state design',
        ],
        isFeatured: true,
        isRecent: true,
        isPopular: true,
      ),
      StudyResourceItem(
        id: 'vl-dbms-query-opt',
        title: 'DBMS Query Optimization Walkthrough',
        subtitle: 'Recorded class on joins, indexing, and execution plans',
        courseCode: 'CSE 2105',
        contributor: 'Instructor recording archive',
        termLabel: '2-1',
        formatLabel: 'Class recording',
        sizeLabel: '1h 12m',
        updatedLabel: 'Updated 2 days ago',
        description:
            'A complete recorded lecture that explains practical query tuning and the reasoning behind faster database access paths.',
        tags: ['Recent', 'DBMS', 'Recorded class'],
        coverage: [
          'Join ordering and indexing tradeoffs',
          'Query plan cost comparisons',
          'Real examples with SQL patterns',
        ],
        isRecent: true,
      ),
      StudyResourceItem(
        id: 'vl-compiler-syntax',
        title: 'Compiler Syntax Analysis Session',
        subtitle: 'LL, LR, parsing tables, and grammar handling',
        courseCode: 'CSE 4203',
        contributor: 'Senior support lecture series',
        termLabel: '4-1',
        formatLabel: 'Explainer video',
        sizeLabel: '54 min',
        updatedLabel: 'Updated 5 days ago',
        description:
            'A guided parsing lecture that breaks down syntax analysis into manageable visual steps for exams and viva.',
        tags: ['Compiler', 'Parsing', 'Explainer'],
        coverage: [
          'FIRST and FOLLOW set construction',
          'LL parsing table generation',
          'LR intuition and parser conflicts',
        ],
        isPopular: true,
      ),
      StudyResourceItem(
        id: 'vl-microprocessor-lab',
        title: 'Microprocessor Interfacing Lab Demo',
        subtitle: 'Hands-on demo for peripheral communication setup',
        courseCode: 'CSE 3101',
        contributor: 'Lab instructor media archive',
        termLabel: '3-1',
        formatLabel: 'Lab demo',
        sizeLabel: '36 min',
        updatedLabel: 'Updated 1 week ago',
        description:
            'A practical demo that shows the usual hardware setup, interface sequence, and troubleshooting path before lab evaluation.',
        tags: ['Lab', 'Microprocessor', 'Hands-on'],
        coverage: [
          'Pin mapping and setup sequence',
          'Port communication logic',
          'Common lab errors and fixes',
        ],
      ),
    ],
  ),
  StudyResourceCategory(
    id: 'assignments',
    title: 'Assignments',
    subtitle: 'Task sheets, templates, and submission guidance',
    summary:
        'Collected assignment briefs, rubric-ready templates, and submission checklists to reduce last-minute friction.',
    icon: Icons.assignment_rounded,
    accentColor: Color(0xFF1565C0),
    gradientColors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    highlights: ['Submission ready', 'Template included', 'Rubric aware'],
    items: [
      StudyResourceItem(
        id: 'as-dsa-set3',
        title: 'DSA Assignment Set 03',
        subtitle: 'Graph traversal, shortest path, and report template',
        courseCode: 'CSE 2203',
        contributor: 'Provided by course coordinator',
        termLabel: '2-2',
        formatLabel: 'Assignment pack',
        sizeLabel: 'Deadline in 5 days',
        updatedLabel: 'Updated today',
        description:
            'Includes the original task sheet, starter pseudocode hints, and a clean report format for graph algorithm problems.',
        tags: ['Featured', 'Deadline soon', 'Template'],
        coverage: [
          'BFS and DFS implementation goals',
          'Single-source shortest path comparison',
          'Report structure and complexity discussion',
        ],
        isFeatured: true,
        isRecent: true,
      ),
      StudyResourceItem(
        id: 'as-swe-srs',
        title: 'Software Engineering SRS Draft Kit',
        subtitle: 'Requirement template and review checklist',
        courseCode: 'CSE 3103',
        contributor: 'Project lab support cell',
        termLabel: '3-1',
        formatLabel: 'Template bundle',
        sizeLabel: '6 files',
        updatedLabel: 'Updated 3 days ago',
        description:
            'A starter kit for SRS preparation with headings, use case examples, non-functional requirement prompts, and review checkpoints.',
        tags: ['Recent', 'Project', 'Template'],
        coverage: [
          'Functional and non-functional sections',
          'Use case and flow documentation',
          'Formatting and submission checklist',
        ],
        isRecent: true,
        isPopular: true,
      ),
      StudyResourceItem(
        id: 'as-cn-packettrace',
        title: 'Networking Packet Trace Report',
        subtitle: 'Wireshark-based lab assignment support',
        courseCode: 'CSE 3107',
        contributor: 'Networking lab mentors',
        termLabel: '3-1',
        formatLabel: 'Report guide',
        sizeLabel: '22 pages',
        updatedLabel: 'Updated 6 days ago',
        description:
            'A reporting guide that explains capture setup, annotation style, and the best way to explain protocol behavior with screenshots.',
        tags: ['Networking', 'Lab report', 'Wireshark'],
        coverage: [
          'Capture setup and filtering',
          'Packet annotation workflow',
          'Screenshot-based explanation pattern',
        ],
      ),
      StudyResourceItem(
        id: 'as-ai-search',
        title: 'AI Search Strategy Worksheet',
        subtitle: 'Heuristic search tasks with marking hints',
        courseCode: 'CSE 4101',
        contributor: 'AI elective teaching assistants',
        termLabel: '4-1',
        formatLabel: 'Worksheet',
        sizeLabel: '14 tasks',
        updatedLabel: 'Updated 1 week ago',
        description:
            'A guided worksheet on uninformed and heuristic search with recommended answer structure and performance discussion hints.',
        tags: ['AI', 'Worksheet', 'Scoring guide'],
        coverage: [
          'BFS, DFS, UCS task patterns',
          'A-star and heuristic admissibility',
          'Search tree comparison write-up',
        ],
        isPopular: true,
      ),
    ],
  ),
  StudyResourceCategory(
    id: 'lab-manuals',
    title: 'Lab Manuals',
    subtitle: 'Experiment sheets and viva preparation material',
    summary:
        'Experiment procedures, expected outputs, and viva cue cards for hardware, software, and database labs.',
    icon: Icons.science_rounded,
    accentColor: Color(0xFFE91E63),
    gradientColors: [Color(0xFFE91E63), Color(0xFFBE185D)],
    highlights: ['Experiment flow', 'Viva cues', 'Output snapshots'],
    items: [
      StudyResourceItem(
        id: 'lm-dbms',
        title: 'DBMS Lab Manual',
        subtitle: 'SQL practice sheet with expected outputs',
        courseCode: 'CSE 2106',
        contributor: 'Database lab committee',
        termLabel: '2-1',
        formatLabel: 'Lab manual',
        sizeLabel: '11 experiments',
        updatedLabel: 'Updated yesterday',
        description:
            'The full DBMS lab handbook with SQL setup, sample datasets, expected outputs, and viva-oriented recap questions.',
        tags: ['Featured', 'SQL', 'Expected output'],
        coverage: [
          'DDL, DML, and query practice',
          'Join and aggregation exercises',
          'Normalization and transaction tasks',
        ],
        isFeatured: true,
        isRecent: true,
        isPopular: true,
      ),
      StudyResourceItem(
        id: 'lm-microprocessor',
        title: 'Microprocessor Lab Experiments',
        subtitle: 'Assembly routines, interfacing, and viva prompts',
        courseCode: 'CSE 3102',
        contributor: 'Hardware lab archive',
        termLabel: '3-1',
        formatLabel: 'Experiment book',
        sizeLabel: '9 experiments',
        updatedLabel: 'Updated 4 days ago',
        description:
            'A practical lab manual covering instruction basics, assembly exercises, interfacing experiments, and examiner prompts.',
        tags: ['Recent', 'Hardware', 'Assembly'],
        coverage: [
          'Basic assembly programming tasks',
          'Delay loops and port output',
          'Interfacing flow and viva questions',
        ],
        isRecent: true,
      ),
      StudyResourceItem(
        id: 'lm-compiler-viva',
        title: 'Compiler Lab Viva Cards',
        subtitle: 'Short, high-yield viva questions and answers',
        courseCode: 'CSE 4204',
        contributor: 'Compiler lab mentors',
        termLabel: '4-1',
        formatLabel: 'Cue card pack',
        sizeLabel: '56 cards',
        updatedLabel: 'Updated 1 week ago',
        description:
            'Pocket-sized viva material focused on tokenization, parsing, code generation, and common implementation decisions.',
        tags: ['Compiler', 'Viva', 'Quick recall'],
        coverage: [
          'Lexer and parser fundamentals',
          'Symbol table and intermediate code',
          'Optimization and code generation basics',
        ],
        isPopular: true,
      ),
      StudyResourceItem(
        id: 'lm-num-methods',
        title: 'Numerical Methods Lab Workbook',
        subtitle: 'Formula reference and coding output examples',
        courseCode: 'CSE 2208',
        contributor: 'Scientific computing lab support',
        termLabel: '2-2',
        formatLabel: 'Workbook',
        sizeLabel: '17 pages',
        updatedLabel: 'Updated 10 days ago',
        description:
            'A concise workbook containing algorithm formulas, code output screenshots, and common sources of numerical error.',
        tags: ['Methods', 'Workbook', 'Outputs'],
        coverage: [
          'Root finding and interpolation',
          'Linear systems and numerical integration',
          'Error analysis and report writing',
        ],
      ),
    ],
  ),
];
