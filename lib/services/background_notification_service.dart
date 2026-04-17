import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Background service that polls Supabase for new notifications periodically
/// and shows them as local push notifications even when the app is in background.
@pragma('vm:entry-point')
class BackgroundNotificationService {
  BackgroundNotificationService._();
  static const Duration _pollInterval = Duration(minutes: 2);

  // SharedPreferences keys for background isolate
  static const _kLastBgCheckTs = 'bg_notif_last_check_ts';
  static const _kBgAlertedIds = 'bg_notif_alerted_ids';
  static const _kBgUserId = 'user_id';
  static const _kBgRole = 'bg_user_role';
  static const _kBgTerm = 'bg_user_term';
  static const _kBgSection = 'bg_user_section';
  static const _kBgEnrolledCodes = 'bg_enrolled_codes';
  // Persisted Supabase session JSON so the background isolate can
  // authenticate and read RLS-protected notification rows.
  static const _kBgSessionJson = 'bg_supabase_session_json';

  // Max alerted IDs we persist (avoid growing forever)
  static const _maxAlertedIds = 500;

  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    // Keep this channel for optional fallback background sync mode.
    final notifPlugin = FlutterLocalNotificationsPlugin();
    await notifPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await notifPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'kuet_bg_sync',
            'Background Sync',
            description: 'Silent background notification sync service',
            importance: Importance.low,
            enableVibration: false,
            playSound: false,
            showBadge: false,
          ),
        );

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: false,
        notificationChannelId: 'kuet_bg_sync',
        initialNotificationTitle: 'KUET CSE',
        initialNotificationContent: 'Sync service',
        foregroundServiceNotificationId: 9999,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  /// Save user context so the background isolate can filter notifications.
  /// Call after login / on NotificationProvider.initialize().
  static Future<void> saveUserContext({
    required String userId,
    String? role,
    String? term,
    String? section,
    List<String> enrolledCodes = const [],

    /// The JSON-encoded Supabase Session (session.toJson()) so the background
    /// isolate can authenticate its own SupabaseClient and read RLS-protected
    /// notification rows.
    String? sessionJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Persist userId explicitly so the background isolate can read it
    await prefs.setString(_kBgUserId, userId);
    await prefs.setString(_kBgRole, role ?? '');
    await prefs.setString(_kBgTerm, term ?? '');
    await prefs.setString(_kBgSection, section ?? '');
    await prefs.setString(_kBgEnrolledCodes, jsonEncode(enrolledCodes));
    if (sessionJson != null && sessionJson.isNotEmpty) {
      await prefs.setString(_kBgSessionJson, sessionJson);
    }
  }

  /// Start the background polling service.
  static Future<void> start() async {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (!running) {
      await service.startService();
    }
  }

  /// Stop the background polling service.
  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (running) {
      service.invoke('stop');
    }
  }

  // ────────────────────────────────────────────────────────────
  // Background isolate entry points
  // ────────────────────────────────────────────────────────────

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    // Ensure Flutter bindings are available in this isolate
    DartPluginRegistrant.ensureInitialized();

    // Listen for stop command from the main isolate
    service.on('stop').listen((_) {
      service.stopSelf();
    });

    // Initialize flutter_local_notifications in the background isolate.
    // Wrap in try/catch: on some Android versions the plugin may throw when
    // initialised outside the main (UI) isolate.  If initialisation fails we
    // fall back to a null plugin and skip local-notification delivery – the
    // service continues polling and updating SharedPreferences so the main
    // isolate can still display notifications when the app is foregrounded.
    FlutterLocalNotificationsPlugin? notifPlugin;
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      // Notification channels are already created by MainApplication.kt
      // (native Application subclass) before Dart code runs, so no need
      // to create them here.  This avoids a redundant IPC round-trip.
      notifPlugin = plugin;
    } catch (e) {
      debugPrint(
        '[BackgroundNotificationService] notifications unavailable in '
        'background isolate: $e',
      );
    }

    // Create a Supabase client for this isolate (can't share with main)
    final supabase = SupabaseClient(
      SupabaseConfig.supabaseUrl,
      SupabaseConfig.supabaseAnonKey,
    );

    final prefs = await SharedPreferences.getInstance();

    // Authenticate the background Supabase client using the stored session so
    // it can read RLS-protected notification rows (target_type = 'USER').
    final storedSessionJson = prefs.getString(_kBgSessionJson);
    if (storedSessionJson != null && storedSessionJson.isNotEmpty) {
      try {
        await supabase.auth.recoverSession(storedSessionJson);
      } catch (e) {
        debugPrint(
          '[BackgroundNotificationService] session recovery failed: $e',
        );
      }
    }

    // Set initial last-check time so first tick doesn't flood
    if (prefs.getString(_kLastBgCheckTs) == null) {
      await prefs.setString(_kLastBgCheckTs, DateTime.now().toIso8601String());
    }

    // ── Poll every 2 minutes (fallback mode only) ─────────
    Timer.periodic(_pollInterval, (timer) async {
      try {
        // Re-read prefs each tick (main isolate may update them)
        await prefs.reload();

        final userId = prefs.getString(_kBgUserId);
        if (userId == null || userId.isEmpty) return;

        final role = prefs.getString(_kBgRole) ?? '';
        final term = prefs.getString(_kBgTerm) ?? '';
        final section = prefs.getString(_kBgSection) ?? '';
        final enrolledRaw = prefs.getString(_kBgEnrolledCodes);
        final enrolled = enrolledRaw != null
            ? List<String>.from(jsonDecode(enrolledRaw) as List)
            : <String>[];

        // Load previously alerted IDs
        final alertedRaw = prefs.getString(_kBgAlertedIds);
        final alerted = alertedRaw != null
            ? Set<String>.from(jsonDecode(alertedRaw) as List)
            : <String>{};

        final lastCheck =
            prefs.getString(_kLastBgCheckTs) ??
            DateTime.now()
                .subtract(const Duration(minutes: 1))
                .toIso8601String();
        final now = DateTime.now().toIso8601String();

        // Fetch notifications created after last check
        final data = await supabase
            .from('notifications')
            .select()
            .gt('created_at', lastCheck)
            .or('expires_at.is.null,expires_at.gt.$now')
            .order('created_at', ascending: false)
            .limit(20);

        final newNotifications = <Map<String, dynamic>>[];

        for (final row in (data as List)) {
          final map = row as Map<String, dynamic>;
          final id = map['id'] as String?;
          if (id == null || alerted.contains(id)) continue;

          if (_isVisibleBg(
            map,
            userId: userId,
            role: role,
            term: term,
            section: section,
            enrolledCodes: enrolled,
          )) {
            newNotifications.add(map);
            alerted.add(id);
          }
        }

        // Show local notifications for each new one
        if (newNotifications.isNotEmpty) {
          // Trim alerted set if it grows too large
          if (alerted.length > _maxAlertedIds) {
            final trimmed = alerted.toList()
              ..removeRange(0, alerted.length - _maxAlertedIds);
            alerted
              ..clear()
              ..addAll(trimmed);
          }
          await prefs.setString(_kBgAlertedIds, jsonEncode(alerted.toList()));

          for (final notif in newNotifications) {
            final title = notif['title'] as String? ?? 'New Notification';
            final body = notif['body'] as String? ?? '';
            final notifId = _stableNotifId(notif['id'] as String);

            await notifPlugin?.show(
              notifId,
              title,
              body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'kuet_notifications',
                  'KUET Notifications',
                  channelDescription: 'Real-time department updates and alerts',
                  importance: Importance.high,
                  priority: Priority.high,
                  enableVibration: true,
                  vibrationPattern: Int64List.fromList([
                    0,
                    400,
                    200,
                    400,
                    200,
                    600,
                  ]),
                  playSound: true,
                  visibility: NotificationVisibility.public,
                ),
              ),
            );
          }
        }

        // Update last check timestamp
        await prefs.setString(_kLastBgCheckTs, now);
      } catch (e) {
        debugPrint('[BackgroundNotificationService] poll error: $e');
        // Will retry next tick.
      }
    });
  }

  // ────────────────────────────────────────────────────────────
  // Visibility filter (simplified mirror of NotificationService)
  // ────────────────────────────────────────────────────────────

  static bool _isVisibleBg(
    Map<String, dynamic> n, {
    required String userId,
    required String role,
    required String term,
    required String section,
    required List<String> enrolledCodes,
  }) {
    final targetType =
        (n['target_type'] as String?)?.trim().toUpperCase() ?? '';
    final targetValue = (n['target_value'] as String?)?.trim();
    final targetValueUpper = targetValue?.toUpperCase();
    final targetYearTerm = (n['target_year_term'] as String?)?.trim();

    final roleUpper = role.toUpperCase();
    final sectionUpper = section.toUpperCase();
    final enrolledUpper = enrolledCodes
        .map((c) => c.trim().toUpperCase())
        .toSet();

    return switch (targetType) {
      'ALL' => true,
      'ROLE' => targetValueUpper == roleUpper,
      'YEAR_TERM' => targetValue == term,
      'SECTION' =>
        targetValueUpper == sectionUpper &&
            (targetYearTerm == null || targetYearTerm == term),
      'COURSE' =>
        targetValueUpper != null && enrolledUpper.contains(targetValueUpper),
      'USER' => targetValue == userId,
      _ => false,
    };
  }

  /// Deterministic notification ID from a string key.
  static int _stableNotifId(String key) {
    var hash = 0;
    for (final rune in key.runes) {
      hash = ((hash * 31) + rune) & 0x7fffffff;
    }
    return hash;
  }
}
