import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/core/theme/app_theme.dart';
import 'package:vodou/core/constants/app_strings.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Démarrage de l\'application Vodou Host...');

  // Initialize date formatting for French locale
  await initializeDateFormatting('fr_FR', null);

  // Initialize Supabase
  await SupabaseService.initialize();

  // Vérifier la session au démarrage
  final supabase = SupabaseService.instance;
  final session = supabase.client.auth.currentSession;
  if (session != null) {
    print('✅ Session active détectée au démarrage');
    print('   Email: ${session.user.email}');
    print('   Expire à: ${session.expiresAt}');
  } else {
    print('ℹ️ Aucune session active au démarrage');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: VodooHostApp()));
}

class VodooHostApp extends StatelessWidget {
  const VodooHostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}
