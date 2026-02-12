/// App models — Notice class used by notices provider

class Notice {
  final String id;
  final String title;
  final String description;
  final String date;
  final String category;
  final bool isImportant;

  Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    required this.isImportant,
  });
}
