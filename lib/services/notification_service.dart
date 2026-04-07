import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/push_notification_service.dart';
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
      createdAt:
          DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'title': title,
    'body': body,
    'target_type': targetType,
    'target_value': targetValue,
    'target_year_term': targetYearTerm,
    'metadata': metadata,
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'is_read': isRead,
  };
}

class _RollRange {
  final int min;
  final int max;

  const _RollRange(this.min, this.max);
}

// ─────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();

  static RealtimeChannel? _channel;
  static const int _maxLocalNotifications = 200;

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
      final profile = await SupabaseCore.from(
        'profiles',
      ).select('role').eq('user_id', userId).maybeSingle();

      final student = await SupabaseCore.from(
        'students',
      ).select('term, section').eq('user_id', userId).maybeSingle();

      final String? role = profile?['role'] as String?;
      final String? term = student?['term'] as String?;
      final String? section = student?['section'] as String?;

      // Build enrolled course codes for COURSE-targeted notifications
      List<String> enrolledCodes = [];
      if (term != null) {
        try {
          final offerings = await SupabaseCore.from(
            'course_offerings',
          ).select('courses!inner(code)').eq('term', term);

          enrolledCodes = (offerings as List)
              .map((o) {
                final courses = o['courses'] as Map<String, dynamic>?;
                return courses?['code'] as String?;
              })
              .whereType<String>()
              .toList();
        } catch (e) {
          debugPrint('[NotificationService] enrolledCodes error: $e');
        }
      }

      // Fetch read receipt IDs
      final reads = await SupabaseCore.from(
        'notification_reads',
      ).select('notification_id').eq('user_id', userId);

      final readIds = <String>{
        for (final r in (reads as List)) r['notification_id'] as String,
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

      final result = unreadOnly
          ? visible.where((n) => !n.isRead).toList()
          : visible;
      final local = await fetchLocalNotifications();
      final merged = _mergeNotifications(result, local);
      final filtered = unreadOnly
          ? merged.where((n) => !n.isRead).toList()
          : merged;
      return filtered.take(limit).toList();
    } catch (e) {
      debugPrint('[NotificationService] fetchNotifications error: $e');
      final local = await fetchLocalNotifications();
      return unreadOnly ? local.where((n) => !n.isRead).toList() : local;
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
      'COURSE' =>
        targetValueUpper != null &&
            enrolledCodesUpper.contains(targetValueUpper),
      'USER' => targetValue == userId,
      _ => false,
    };
  }

  // ── Count unread ───────────────────────────────────────────

  static Future<int> getUnreadCount() async {
    final notifications = await fetchNotifications(
      unreadOnly: true,
      limit: 100,
    );
    return notifications.length;
  }

  // ── Mark specific notifications as read ───────────────────

  static Future<void> markAsRead(List<String> notificationIds) async {
    final userId = SessionService.currentUserId;
    if (userId == null || notificationIds.isEmpty) return;

    try {
      final localIds = notificationIds.where(_isLocalNotificationId).toList();
      final remoteIds = notificationIds
          .where((id) => !_isLocalNotificationId(id))
          .toList();

      if (localIds.isNotEmpty) {
        await _markLocalNotificationsAsRead(localIds);
      }

      if (remoteIds.isEmpty) return;

      final rows = remoteIds
          .map((id) => {'notification_id': id, 'user_id': userId})
          .toList();

      await SupabaseCore.from(
        'notification_reads',
      ).upsert(rows, onConflict: 'notification_id,user_id');
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

  static Future<List<AppNotification>> fetchLocalNotifications() async {
    final userId = SessionService.currentUserId;
    if (userId == null) return [];

    try {
      final prefs = await SupabaseCore.ensurePrefs();
      final raw = prefs.getString(_localNotificationStorageKey(userId));
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final list =
          decoded
              .whereType<Map>()
              .map(
                (item) =>
                    AppNotification.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('[NotificationService] fetchLocalNotifications error: $e');
      return [];
    }
  }

  static Future<void> saveLocalInboxNotification({
    String? id,
    required String type,
    required String title,
    required String body,
    String targetType = 'USER',
    String? targetValue,
    String? targetYearTerm,
    Map<String, dynamic> metadata = const {},
    DateTime? createdAt,
    bool isRead = false,
  }) async {
    final userId = SessionService.currentUserId;
    if (userId == null) return;

    final notification = AppNotification(
      id: _normalizeLocalNotificationId(
        id,
        type,
        title,
        body,
        metadata,
        createdAt,
      ),
      type: type,
      title: title,
      body: body,
      targetType: targetType,
      targetValue: targetValue ?? userId,
      targetYearTerm: targetYearTerm,
      metadata: metadata,
      createdAt: createdAt ?? DateTime.now(),
      expiresAt: null,
      isRead: isRead,
    );

    try {
      final existing = await fetchLocalNotifications();
      final merged = _mergeNotifications([notification], existing)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final trimmed = merged.take(_maxLocalNotifications).toList();

      final prefs = await SupabaseCore.ensurePrefs();
      await prefs.setString(
        _localNotificationStorageKey(userId),
        jsonEncode(trimmed.map((item) => item.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('[NotificationService] saveLocalInboxNotification error: $e');
    }
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

      final recipientIds = await _resolveTargetRecipientIds(
        targetType: targetType,
        targetValue: targetValue,
        targetYearTerm: targetYearTerm,
      );

      await PushNotificationService.sendNotificationToUsers(
        userIds: recipientIds,
        title: title,
        body: body,
        data: {'type': type, ...metadata},
      );
    } catch (e) {
      debugPrint('[NotificationService] createNotification error: $e');
    }
  }

  static Future<void> notifyGeoAttendanceOpened({
    required String courseCode,
    required String term,
    required int durationMinutes,
    required DateTime endTime,
    String? section,
    String? roomNumber,
    String? roomId,
  }) async {
    final userId = SessionService.currentUserId;
    if (userId == null) return;

    final normalizedTerm = _cleanText(term);
    if (normalizedTerm == null) return;

    final sectionLabel = _formatGeoAttendanceSectionLabel(section);
    final title = '📍 Attendance Open — $courseCode$sectionLabel';
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    final body =
        'Your attendance for $courseCode is now open. Submit within $durationMinutes min (before $endHour:$endMinute).';
    final metadata = <String, dynamic>{
      'course_code': courseCode,
      'duration_minutes': durationMinutes,
      'end_time_label': '$endHour:$endMinute',
      'open_screen': 'student_geo_attendance',
      if (_cleanText(roomNumber) != null) 'room_number': _cleanText(roomNumber),
      if (_cleanText(section) != null) 'geo_room_section': _cleanText(section),
      if (_cleanText(roomId) != null) 'geo_room_id': _cleanText(roomId),
    };
    final collapseId =
        _cleanText(roomId) ?? 'geo_attendance_open_${courseCode}_$term';
    final expiresAt = endTime.toIso8601String();
    // collapseId is reserved for future push collapse; suppress lint
    // ignore: unused_local_variable
    final _ = collapseId;

    // COURSE target → only students enrolled in this course + its teacher(s)
    // get in-app visibility + push. Same proven pattern as exam & room booking.
    // Also send a direct USER notification to the teacher who opened the room.
    await Future.wait<Object?>([
      // 1. In-app notification for enrolled students (COURSE target)
      createNotification(
        type: 'geo_attendance_open',
        title: title,
        body: body,
        targetType: 'COURSE',
        targetValue: courseCode,
        metadata: metadata,
        expiresAt: expiresAt,
      ).then((_) => null).onError((e, _) {
        debugPrint('[NotificationService] geo_attendance COURSE notify error: $e');
        return null;
      }),
      // 2. In-app notification for the teacher who opened the room (USER target)
      createNotification(
        type: 'geo_attendance_open',
        title: '📍 Attendance Room Opened — $courseCode$sectionLabel',
        body: 'You opened attendance for $courseCode. '
            'Window closes at $endHour:$endMinute ($durationMinutes min).',
        targetType: 'USER',
        targetValue: userId,
        metadata: metadata,
        expiresAt: expiresAt,
      ).then((_) => null).onError((e, _) {
        debugPrint('[NotificationService] geo_attendance USER notify error: $e');
        return null;
      }),
    ]);

    // Push was already fired by createNotification → _resolveTargetRecipientIds
    // for both COURSE (students + teacher) and USER (teacher) targets.
    // No additional manual push needed.
  }

  static Future<List<String>> _resolveTargetRecipientIds({
    required String targetType,
    String? targetValue,
    String? targetYearTerm,
  }) async {
    final normalizedTargetType = targetType.trim().toUpperCase();
    final cleanedValue = _cleanText(targetValue);
    final cleanedYearTerm = _cleanText(targetYearTerm);

    switch (normalizedTargetType) {
      case 'USER':
        return cleanedValue == null ? [] : [cleanedValue];
      case 'ROLE':
        return _resolveRoleRecipientIds(cleanedValue);
      case 'YEAR_TERM':
        return _resolveYearTermRecipientIds(cleanedValue);
      case 'SECTION':
        return _resolveSectionRecipientIds(
          section: cleanedValue,
          yearTerm: cleanedYearTerm,
        );
      case 'COURSE':
        return _resolveCourseRecipientIds(cleanedValue);
      case 'ALL':
        return _resolveAllRecipientIds();
      default:
        return [];
    }
  }

  static Future<List<String>> _resolveAllRecipientIds() async {
    final data = await SupabaseCore.from(
      'profiles',
    ).select('user_id, is_active');

    final recipients = <String>{};
    for (final row in List<Map<String, dynamic>>.from(data as List)) {
      final userId = _cleanText(row['user_id']?.toString());
      final isActive = row['is_active'] as bool? ?? true;
      if (userId != null && isActive) {
        recipients.add(userId);
      }
    }

    return recipients.toList();
  }

  static Future<List<String>> _resolveRoleRecipientIds(String? role) async {
    final normalizedRole = role?.trim().toUpperCase();
    if (normalizedRole == null || normalizedRole.isEmpty) return [];

    final data = await SupabaseCore.from(
      'profiles',
    ).select('user_id, role, is_active');

    final recipients = <String>{};
    for (final row in List<Map<String, dynamic>>.from(data as List)) {
      final userId = _cleanText(row['user_id']?.toString());
      final rowRole = _cleanText(row['role']?.toString())?.toUpperCase();
      final isActive = row['is_active'] as bool? ?? true;
      if (userId != null && isActive && rowRole == normalizedRole) {
        recipients.add(userId);
      }
    }

    return recipients.toList();
  }

  static Future<List<String>> _resolveYearTermRecipientIds(
    String? yearTerm,
  ) async {
    final normalizedTerm = _cleanText(yearTerm);
    if (normalizedTerm == null) return [];

    final data = await SupabaseCore.from(
      'students',
    ).select('user_id').eq('term', normalizedTerm);

    return List<Map<String, dynamic>>.from(data as List)
        .map((row) => _cleanText(row['user_id']?.toString()))
        .whereType<String>()
        .toSet()
        .toList();
  }

  static Future<List<String>> _resolveSectionRecipientIds({
    String? section,
    String? yearTerm,
  }) async {
    final normalizedSection = section?.trim().toUpperCase();
    if (normalizedSection == null || normalizedSection.isEmpty) return [];

    final data = await SupabaseCore.from(
      'students',
    ).select('user_id, term, section');

    final recipients = <String>{};
    for (final row in List<Map<String, dynamic>>.from(data as List)) {
      final userId = _cleanText(row['user_id']?.toString());
      final rowTerm = _cleanText(row['term']?.toString());
      final rowSection = _cleanText(row['section']?.toString())?.toUpperCase();
      if (userId == null || rowSection != normalizedSection) continue;
      if (yearTerm != null && yearTerm.isNotEmpty && rowTerm != yearTerm) {
        continue;
      }
      recipients.add(userId);
    }

    return recipients.toList();
  }

  static Future<List<String>> _resolveCourseRecipientIds(
    String? courseCode,
  ) async {
    final normalizedCode = courseCode?.trim().toUpperCase();
    if (normalizedCode == null || normalizedCode.isEmpty) return [];

    final offeringsData = await SupabaseCore.from('course_offerings').select('''
          term,
          teacher_user_id,
          courses ( code )
        ''');

    final termWideTerms = <String>{};
    final teacherIds = <String>{};

    for (final row in List<Map<String, dynamic>>.from(offeringsData as List)) {
      final course = row['courses'] as Map<String, dynamic>?;
      final code = _cleanText(course?['code']?.toString())?.toUpperCase();
      if (code != normalizedCode) continue;

      // Collect the teacher assigned to this course offering
      final teacherId = _cleanText(row['teacher_user_id']?.toString());
      if (teacherId != null) teacherIds.add(teacherId);

      final term = _cleanText(row['term']?.toString());
      if (term == null) continue;

      termWideTerms.add(term);
    }

    if (termWideTerms.isEmpty) {
      // No student targets, but still return any matched teachers
      return teacherIds.toList();
    }

    final studentData = await SupabaseCore.from(
      'students',
    ).select('user_id, term');

    final recipients = <String>{};
    // Include course teachers
    recipients.addAll(teacherIds);

    for (final row in List<Map<String, dynamic>>.from(studentData as List)) {
      final userId = _cleanText(row['user_id']?.toString());
      final term = _cleanText(row['term']?.toString());
      if (userId == null || term == null) continue;

      if (termWideTerms.contains(term)) {
        recipients.add(userId);
      }
    }

    return recipients.toList();
  }

  static String? _cleanText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String? _normalizeGeoAttendanceSection(String? section) {
    final cleaned = _cleanText(section);
    if (cleaned == null) return null;

    final normalized = cleaned.toUpperCase();
    if (RegExp(r'^[A-Z]\d?$').hasMatch(normalized)) {
      return normalized;
    }

    final named = RegExp(
      r'\b(section|group)\s+([A-Za-z]\d?)\b',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (named != null) {
      return named.group(2)?.toUpperCase();
    }

    return normalized;
  }

  static String _formatGeoAttendanceSectionLabel(String? section) {
    final cleaned = _cleanText(section);
    if (cleaned == null) return '';
    if (RegExp(r'^(section|group)\b', caseSensitive: false).hasMatch(cleaned)) {
      return ' ($cleaned)';
    }

    final normalized = _normalizeGeoAttendanceSection(cleaned);
    if (normalized == null) return ' ($cleaned)';

    final prefix = normalized.length == 1 ? 'Section' : 'Group';
    return ' ($prefix $normalized)';
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

  static String _localNotificationStorageKey(String userId) =>
      'local_notification_history_$userId';

  static bool _isLocalNotificationId(String id) => id.startsWith('local:');

  static String _normalizeLocalNotificationId(
    String? id,
    String type,
    String title,
    String body,
    Map<String, dynamic> metadata,
    DateTime? createdAt,
  ) {
    final cleanedId = _cleanText(id);
    if (cleanedId != null) {
      return cleanedId.startsWith('local:') ? cleanedId : 'local:$cleanedId';
    }

    final geoRoomId = _cleanText(metadata['geo_room_id']?.toString());
    final courseCode = _cleanText(metadata['course_code']?.toString()) ?? '';
    final endLabel = _cleanText(metadata['end_time_label']?.toString()) ?? '';
    final section = _cleanText(metadata['geo_room_section']?.toString()) ?? '';
    final createdPart = (createdAt ?? DateTime.now()).millisecondsSinceEpoch;
    final fingerprint =
        '$type|$title|$body|$geoRoomId|$courseCode|$section|$endLabel|$createdPart';
    final hash = fingerprint.hashCode.abs();
    return 'local:$hash';
  }

  static String _notificationIdentity(AppNotification notification) {
    final serverId = !_isLocalNotificationId(notification.id)
        ? notification.id
        : _cleanText(
            notification.metadata['server_notification_id']?.toString(),
          );
    if (serverId != null) return 'server:$serverId';

    final geoRoomId = _cleanText(
      notification.metadata['geo_room_id']?.toString(),
    );
    if (geoRoomId != null) {
      final target = notification.targetValue ?? '';
      return 'geo:${notification.type}:$geoRoomId:$target';
    }

    final courseCode =
        _cleanText(notification.metadata['course_code']?.toString()) ?? '';
    final endLabel =
        _cleanText(notification.metadata['end_time_label']?.toString()) ?? '';
    final target = notification.targetValue ?? '';
    return 'fallback:${notification.type}:${notification.title}:$courseCode:$endLabel:$target';
  }

  static List<AppNotification> _mergeNotifications(
    List<AppNotification> primary,
    List<AppNotification> secondary,
  ) {
    final merged = <String, AppNotification>{};

    void upsert(AppNotification notification) {
      final key = _notificationIdentity(notification);
      final existing = merged[key];
      if (existing == null) {
        merged[key] = notification;
        return;
      }

      final preferCurrent = notification.createdAt.isAfter(existing.createdAt);
      final chosen = preferCurrent ? notification : existing;
      merged[key] = chosen.copyWith(
        isRead: notification.isRead || existing.isRead,
      );
    }

    for (final notification in secondary) {
      upsert(notification);
    }
    for (final notification in primary) {
      upsert(notification);
    }

    final result = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  static Future<void> _markLocalNotificationsAsRead(List<String> ids) async {
    final userId = SessionService.currentUserId;
    if (userId == null || ids.isEmpty) return;

    final existing = await fetchLocalNotifications();
    final idSet = ids.toSet();
    final updated = existing
        .map(
          (notification) => idSet.contains(notification.id)
              ? notification.copyWith(isRead: true)
              : notification,
        )
        .toList();

    final prefs = await SupabaseCore.ensurePrefs();
    await prefs.setString(
      _localNotificationStorageKey(userId),
      jsonEncode(updated.map((item) => item.toMap()).toList()),
    );
  }
}
