import 'package:go_router/go_router.dart';
import 'package:vodou/core/router/go_router_refresh_stream.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/auth/presentation/pages/login_page.dart';
import 'package:vodou/features/auth/presentation/pages/signup_page.dart';
import 'package:vodou/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:vodou/features/home/presentation/pages/main_page.dart';
import 'package:vodou/features/accommodation/presentation/pages/accommodation_details_page.dart';
import 'package:vodou/features/booking/presentation/pages/booking_page_v2.dart';
import 'package:vodou/features/preferences/presentation/pages/questionnaire_page.dart';
import 'package:vodou/features/rituals/presentation/pages/ritual_details_page.dart';
import 'package:vodou/features/messaging/presentation/pages/chat_page.dart';
import 'package:vodou/features/messaging/presentation/pages/conversations_page.dart';
import 'package:vodou/features/home/domain/models/logement.dart';

class AppRouter {
  static const String login = '/';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String questionnaire = '/questionnaire';
  static const String home = '/home';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String accommodationDetails = '/accommodation/:id';
  static const String ritualDetails = '/ritual/:id';
  static const String booking = '/booking';
  static const String chat = '/chat/:conversationId';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final supabase = SupabaseService.instance;
      final isAuthenticated = supabase.isAuthenticated;
      final isGoingToAuth =
          state.matchedLocation == login ||
          state.matchedLocation == signup ||
          state.matchedLocation == forgotPassword;

      // Pages publiques accessibles sans connexion
      final publicPages = [
        login,
        signup,
        forgotPassword,
        home,
        '/search',
        '/favorites',
      ];

      final isGoingToPublicPage = publicPages.any(
        (page) => state.matchedLocation.startsWith(page),
      );

      // Si l'utilisateur est connecté et essaie d'aller sur login/signup
      if (isAuthenticated && isGoingToAuth) {
        print('🔄 Utilisateur déjà connecté, redirection vers home');
        return home;
      }

      // Si l'utilisateur n'est pas connecté et essaie d'accéder à une page protégée
      if (!isAuthenticated && !isGoingToPublicPage) {
        print('⚠️ Utilisateur non connecté, redirection vers login');
        return login;
      }

      // Pas de redirection nécessaire
      return null;
    },
    refreshListenable: GoRouterRefreshStream(
      SupabaseService.instance.authStateChanges,
    ),
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: signup,
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: questionnaire,
        name: 'questionnaire',
        builder: (context, state) {
          final isFirstTime = state.extra as bool? ?? false;
          return QuestionnairePage(isFirstTime: isFirstTime);
        },
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const MainPage(),
      ),
      GoRoute(
        path: accommodationDetails,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AccommodationDetailsPage(accommodationId: id);
        },
      ),
      GoRoute(
        path: ritualDetails,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return RitualDetailsPage(ritualId: id);
        },
      ),
      GoRoute(
        path: booking,
        builder: (context, state) {
          final logement = state.extra as Logement?;
          if (logement == null) {
            // Si aucun logement n'est passé, retourner à la page d'accueil
            return const MainPage();
          }
          return BookingPageV2(logement: logement);
        },
      ),
      GoRoute(
        path: chat,
        builder: (context, state) {
          final conversationId = int.parse(
            state.pathParameters['conversationId']!,
          );
          return ChatPage(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: messages,
        name: 'messages',
        builder: (context, state) => const ConversationsPage(),
      ),
    ],
  );
}
