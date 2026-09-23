import 'package:go_router/go_router.dart';
import 'package:vodou/core/router/go_router_refresh_stream.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/auth/data/repositories/auth_repository.dart';
import 'package:vodou/features/auth/presentation/pages/login_page.dart';
import 'package:vodou/features/auth/presentation/pages/signup_page.dart';
import 'package:vodou/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:vodou/features/auth/presentation/pages/email_confirmation_page.dart';
import 'package:vodou/features/home/presentation/pages/main_page_wrapper.dart';
import 'package:vodou/features/accommodation/presentation/pages/accommodation_details_page.dart';
import 'package:vodou/features/booking/presentation/pages/booking_page_v2.dart';
import 'package:vodou/features/preferences/presentation/pages/questionnaire_page.dart';
import 'package:vodou/features/rituals/presentation/pages/ritual_details_page.dart';
import 'package:vodou/features/messaging/presentation/pages/chat_page.dart';
import 'package:vodou/features/messaging/presentation/pages/conversations_page.dart';
import 'package:vodou/features/festivals/presentation/pages/festival_selection_page.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:vodou/core/utils/app_logger.dart';

class AppRouter {
  static const String login = '/';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String emailConfirmation = '/email-confirmation';
  static const String festivalSelection = '/festival-selection';
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
    // Configuration pour accepter les deep links personnalisés
    // Le schéma 'vodoohost://' est configuré dans AndroidManifest.xml
    redirect: (context, state) async {
      final supabase = SupabaseService.instance;
      final isAuthenticated = supabase.isAuthenticated;
      final isGoingToAuth =
          state.matchedLocation == login ||
          state.matchedLocation == signup ||
          state.matchedLocation == forgotPassword;

      // Si l'utilisateur est connecté et essaie d'aller sur une page d'auth (login/signup)
      if (isAuthenticated && isGoingToAuth) {
        final currentUser = supabase.currentUser;
        if (currentUser != null) {
          final authRepo = AuthRepository();
          final userProfile = await authRepo.getCurrentUser();
          if (userProfile == null) {
            AppLogger.w(
              '⚠️ Session Supabase active mais aucun profil dans la table users. Suspension de la redirection auto.',
            );
            return null;
          }
        }

        AppLogger.d(
          '🔄 Utilisateur connecté avec profil, redirection vers festival-selection',
        );
        return festivalSelection;
      }

      // Si l'utilisateur n'est pas connecté et n'est pas sur une page d'auth
      if (!isAuthenticated && !isGoingToAuth) {
        AppLogger.w('⚠️ Utilisateur non connecté, redirection vers login');
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
        path: emailConfirmation,
        name: 'email-confirmation',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return EmailConfirmationPage(email: email);
        },
      ),
      GoRoute(
        path: festivalSelection,
        name: 'festival-selection',
        builder: (context, state) {
          final isFirstTime = state.extra as bool? ?? false;
          return FestivalSelectionPage(isFirstTime: isFirstTime);
        },
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
        builder: (context, state) => const MainPageWrapper(),
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
          Logement? logement;

          // Gérer le cas où state.extra peut être un Logement ou un Map
          if (state.extra is Logement) {
            logement = state.extra as Logement;
          } else if (state.extra is Map<String, dynamic>) {
            logement = Logement.fromJson(state.extra as Map<String, dynamic>);
          }

          if (logement == null) {
            // Si aucun logement n'est passé, retourner à la page d'accueil
            return const MainPageWrapper();
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
