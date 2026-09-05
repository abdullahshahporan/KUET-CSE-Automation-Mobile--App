import 'dart:io';

void main() {
  for (final name in ['supabase_config', 'push_config', 'ai_config']) {
    final file = File('lib/config/$name.dart');
    if (!file.existsSync()) {
      File('lib/config/$name.dart.template').copySync(file.path);
      stdout.writeln(
        'Created ${file.path}; existing configuration is preserved.',
      );
    }
  }
}
