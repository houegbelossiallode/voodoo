import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/core/theme/app_theme.dart';
import 'package:vodou/core/constants/app_strings.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/core/config/env.dart';
import 'package:vodou/core/utils/app_logger.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Échoue immédiatement si la configuration de build est incomplète,
  // plutôt qu'au premier appel réseau.
  Env.assertValid();

  AppLogger.i('Démarrage de Vodou Host', {'env': Env.environment});

  // Initialize date formatting for French locale
  await initializeDateFormatting('fr_FR', null);

  // Initialize Supabase
  await SupabaseService.initialize();

  // Vérifier la session au démarrage.
  // L'e-mail et l'échéance de session ne sont pas journalisés (VUL-08).
  final supabase = SupabaseService.instance;
  final hasSession = supabase.client.auth.currentSession != null;
  AppLogger.d('Session au démarrage', {'active': hasSession});

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

class VodooHostApp extends ConsumerStatefulWidget {
  const VodooHostApp({super.key});

  @override
  ConsumerState<VodooHostApp> createState() => _VodooHostAppState();
}

class _VodooHostAppState extends ConsumerState<VodooHostApp> {
  @override
  void initState() {
    super.initState();
    _listenToAuthNavigation();
  }

  void _listenToAuthNavigation() {
    authNavigationController.stream.listen((event) {
      if (event == AuthNavigationEvent.passwordRecovery) {
        AppLogger.d('🔑 Navigation vers reset-password détectée');
        if (mounted) {
          AppRouter.router.push(AppRouter.resetPassword);
        }
      }
    });
  }

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
