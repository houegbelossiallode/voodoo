import 'dart:async';
import 'package:flutter/foundation.dart';

/// Classe helper pour rafraîchir GoRouter quand un Stream émet une valeur
/// Utilisée pour écouter les changements d'authentification Supabase
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) {
        print('🔔 GoRouter: Changement d\'état d\'authentification détecté');
        notifyListeners();
      },
      onError: (error) {
        print('❌ GoRouter: Erreur dans le stream: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
