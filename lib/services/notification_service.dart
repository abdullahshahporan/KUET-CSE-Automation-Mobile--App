import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session_service.dart';
import '../services/supabase_core.dart';

// ─────────────────────────────────────────────────────────────
// AppNotification model
// ─────────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String targetType;
  final String? targetValue;
  final String? targetYearTerm;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? expiresAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.targetType,
    this.targetValue,
    this.targetYearTerm,
    required this.metadata,
    required this.createdAt,
    this.expiresAt,
    required this.isRead,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) {
    return AppNotification(
      id: m['id'] as String,
      type: m['type'] as String? ?? 'announcement',
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      targetType: m['target_type'] as String? ?? 'ALL',
      targetValue: m['target_value'] as String?,
      targetYearTerm: m['target_year_term'] as String?,
      metadata: (m['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      expiresAt: m['expires_at'] != null
          ? DateTime.tryParse(m['expires_at'] as String)
          : null,
      isRead: m['is_read'] as bool? ?? false,
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        targetType: targetType,
        targetValue: targetValue,
        targetYearTerm: targetYearTerm,
        metadata: metadata,
        createdAt: createdAt,
        expiresAt: expiresAt,
        isRead: isRead ?? this.isRead,
      );
}

// ─────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();

  static RealtimeChannel? _channel;

  // ── Fetch notifications visible to the current user ───────

  static Future<List<AppNotification>> fetchNotifications({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = SessionService.currentUserId;
    if (userId == null) return [];

    try {
      // Get user context for visibility filtering
      final profile = await SupabaseCore.from('profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      final student = await SupabaseCore.from('students')
          .select('term, section')
          .eq('user_id', userId)
          .maybeSingle();

      final String? role = profile?['role'] as String?;
      final String? term = student?['term'] as String?;
      final String? section = student?['section'] as String?;

      // Build enrolled course codes for COURSE-targeted notifications
      List<String> enrolledCodes = [];
      if (term != null && section != null) {
        final offerings = await SupabaseCore.from('course_offerings')
            .select('courses!inner(code)')
            .eq('term', term)
            .eq('section', section);

        enrolledCodes = (offerings as List)
            .map((o) {
              final courses = o['courses'] as Map<String, dynamic>?;
              return courses?['code'] as String?;
            })
            .whereType<String>()
            .toList();
      }

      // Fetch read receipt IDs
      final reads = await SupabaseCore.from('notification_reads')
          .select('notification_id')
          .eq('user_id', userId);

      final readIds = <String>{
        for (final r in (reads as List))
          r['notification_id'] as String,
      };

      // Build the query with server-side OR targeting
      // We fetch and filter client-side since OR clauses get complex
      final now = DateTime.now().toIso8601String();

      // Base query — fetch recent notifications (all types for server efficiency)
      final data = await SupabaseCore.from('notifications')
          .select()
          .or('expires_at.is.null,expires_at.gt.$now')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1 + 50); // over-fetch and filter

      final all = (data as List)
          .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
          .toList();

      // Filter by visibility rules
      final visible = all.where((n) {
        return _isVisible(
          n,
          userId: userId,
          role: role,
          term: term,
          section: section,
          enrolledCodes: enrolledCodes,
        );
      }).toList();

      // Annotate is_read
      for (final n in visible) {
        n.isRead = readIds.contains(n.id);
      }

      final result = unreadOnly ? visible.where((n) => !n.isRead).toList() : visible;
      return result.take(limit).toList();
    } catch (e) {
      debugPrint('[NotificationService] fetchNotifications error: $e');
      return [];
    }
  }

  // ── Visibility check (mirrors server RLS) ─────────────────

  static bool _isVisible(
    AppNotification n, {
    required String userId,
    String? role,
    String? term,
    String? section,
    List<String> enrolledCodes = const [],
  }) {
    String? normalize(String? value) => value?.trim();
    String? normalizeUpper(String? value) => normalize(value)?.toUpperCase();

    final targetType = normalizeUpper(n.targetType) ?? '';
    final targetValue = normalize(n.targetValue);
    final targetValueUpper = normalizeUpper(n.targetValue);
    final targetYearTerm = normalize(n.targetYearTerm);

    final userRole = normalizeUpper(role);
    final userTerm = normalize(term);
    final userSection = normalizeUpper(section);
    final enrolledCodesUpper = enrolledCodes
        .map((code) => code.trim().toUpperCase())
        .toSet();

    return switch (targetType) {
      'ALL' => true,
      'ROLE' => targetValueUpper == userRole,
      'YEAR_TERM' => targetValue == userTerm,
      // Some older rows may miss target_year_term; keep section-only fallback.
      'SECTION' =>
        targetValueUpper == userSection &&
        (targetYearTerm == null || targetYearTerm == userTerm),
      'COURSE' => targetValueUpper != null && enrolledCodesUpper.contains(targetValueUpper),
      'USER' => targetValue == userId,
      _ => false,
    };
  }

  // ── Count unread ───────────────────────────────────────────

  static Future<int> getUnreadCount() async {
    final notifications = await fetchNotifications(unreadOnly: true, limit: 100);
    return notifications.length;
  }

  // ── Mark specific notifications as read ───────────────────

  static Future<void> markAsRead(List<String> notificationIds) async {
    final userId = SessionService.currentUserId;
    if (userId == null || notificationIds.isEmpty) return;

    try {
      final rows = notificationIds
          .map((id) => {'notification_id': id, 'user_id': userId})
          .toList();

      await SupabaseCore.from('notification_reads')
          .upsert(rows, onConflict: 'notification_id,user_id');
    } catch (e) {
      debugPrint('[NotificationService] markAsRead error: $e');
    }
  }

  // ── Mark all as read ──────────────────────────────────────

  static Future<void> markAllAsRead() async {
    final unread = await fetchNotifications(unreadOnly: true, limit: 200);
    final ids = unread.map((n) => n.id).toList();
    await markAsRead(ids);
  }

  // ── Create a notification (for CR/Teacher on mobile) ──────

  static Future<void> createNotification({
    required String type,
    required String title,
    required String body,
    required String targetType,
    String? targetValue,
    String? targetYearTerm,
    Map<String, dynamic> metadata = const {},
    String? expiresAt,
  }) async {
    final userId = SessionService.currentUserId;
    if (userId == null) return;

    final role = SessionService.currentRole;
    final createdByRole = role == 'STUDENT' ? 'STUDENT_CR' : 'TEACHER';

    try {
      await SupabaseCore.from('notifications').insert({
        'type': type,
        'title': title,
        'body': body,
        'target_type': targetType,
        'target_value': targetValue,
        'target_year_term': targetYearTerm,
        'created_by': userId,
        'created_by_role': createdByRole,
        'metadata': metadata,
        'expires_at': expiresAt,
      });
    } catch (e) {
      debugPrint('[NotificationService] createNotification error: $e');
    }
  }

  // ── Realtime subscription ─────────────────────────────────
  // Calls [onNew] whenever a new notification arrives.
  // The caller (provider) filters visibility.

  static void subscribe(void Function(AppNotification) onNew) {
    final client = SupabaseCore.client;
    _channel?.unsubscribe();
    _channel = client
        .channel('notifications-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            try {
              final n = AppNotification.fromMap(payload.newRecord);
              onNew(n);
            } catch (e) {
              debugPrint('[NotificationService] realtime parse error: $e');
            }
          },
        )
        .subscribe();
  }

  static void unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
