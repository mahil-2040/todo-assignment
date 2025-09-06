import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Top-level background handler (MUST be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // You can do lightweight logging here if needed
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final _supabase = Supabase.instance.client;
  final _messaging = FirebaseMessaging.instance;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Firebase.initializeApp();

    // iOS permission (and Android 13+ runtime)
    await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
      provisional: false,
    );

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages (optional UI/snackbar)
    FirebaseMessaging.onMessage.listen((msg) {
      if (kDebugMode) {
        print('FCM foreground: ${msg.notification?.title} - ${msg.notification?.body}');
      }
    });

    // Save current token
    await _ensureTokenSaved();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      await _saveToken(newToken);
    });

    _initialized = true;
  }

  Future<void> _ensureTokenSaved() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }
  }

  Future<void> _saveToken(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (kDebugMode) {
        print('Cannot save FCM token: User not authenticated');
      }
      return;
    }

    final platform = Platform.isAndroid ? 'android' :
                     Platform.isIOS ? 'ios' : 'other';

    try {
      // First try to insert, if conflict then update
      final res = await _supabase
          .from('device_tokens')
          .upsert({
            'user_id': user.id,
            'token': token,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'token')
          .select()
          .maybeSingle();

      if (kDebugMode) {
        print('Saved device token: $res');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving device token: $e');
      }
      // Retry with a simple insert approach
      try {
        await _supabase
            .from('device_tokens')
            .insert({
              'user_id': user.id,
              'token': token,
              'platform': platform,
            });
        if (kDebugMode) {
          print('Device token saved successfully on retry');
        }
      } catch (retryError) {
        if (kDebugMode) {
          print('Failed to save device token on retry: $retryError');
        }
      }
    }
  }

  Future<void> deleteMyToken() async {
    final token = await _messaging.getToken();
    final user = _supabase.auth.currentUser;
    if (token != null && user != null) {
      await _supabase
          .from('device_tokens')
          .delete()
          .eq('token', token)
          .eq('user_id', user.id);
    }
  }
}
