import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lionsns/l10n/app_localizations.dart';
import 'core/services/external/supabase_service.dart';
import 'core/services/internal/push_notification_service.dart';
import 'config/router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('Code verifier')) {
      return;
    }
    FlutterError.presentError(details);
  };

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase 초기화 실패: $e');
  }

  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase 초기화 실패: $e');
  }

  try {
    await PushNotificationService.initialize();
    await PushNotificationService.handleInitialMessage();
  } catch (e) {
    debugPrint('푸시 알림 서비스 초기화 실패: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final l10n = AppLocalizations.of(context);
    return MaterialApp.router(
      title: l10n?.appTitle ?? '커뮤니티 앱',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [
        Locale('ko', ''),
        Locale('en', ''),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 4,
        ),
      ),
      routerConfig: router,
    );
  }
}