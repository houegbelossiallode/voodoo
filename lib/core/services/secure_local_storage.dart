import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/core/utils/app_logger.dart';

/// Persistance de la session Supabase dans le stockage **chiffré** du système.
///
/// Par défaut, `supabase_flutter` écrit la session — donc le jeton d'accès et
/// le jeton de rafraîchissement — dans `SharedPreferences`, c'est-à-dire en
/// clair dans `/data/data/<package>/shared_prefs/`. Sur un appareil rooté ou
/// via une sauvegarde ADB, ces jetons sont lisibles et rejouables jusqu'à leur
/// expiration (cf. `AUDIT_SECURITE.md` — VUL-10).
///
/// Cette implémentation s'appuie sur le **Keystore Android** et le **Keychain
/// iOS** via `flutter_secure_storage`.
///
/// ## Migration
///
/// [initialize] déplace une session déjà présente dans `SharedPreferences`
/// vers le stockage chiffré, puis efface l'original. Les utilisateurs déjà
/// connectés le restent : il n'y a pas de déconnexion massive au déploiement.
///
/// ## Dégradation
///
/// Si le stockage sécurisé est indisponible (Keystore corrompu après une
/// restauration d'usine, émulateur mal configuré), la classe retombe sur
/// `SharedPreferences` plutôt que d'empêcher toute connexion. Ce repli est
/// journalisé en avertissement.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({required this.persistSessionKey});

  /// Clé de session, identique à celle utilisée par `supabase_flutter`
  /// pour permettre la migration.
  final String persistSessionKey;

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Passe à `true` si le stockage chiffré s'avère inutilisable.
  bool _fallbackToPrefs = false;
  SharedPreferences? _prefs;

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    try {
      // Vérifie que le stockage sécurisé répond avant de s'y fier.
      await _secure.containsKey(key: persistSessionKey);
    } catch (e, s) {
      _fallbackToPrefs = true;
      AppLogger.e(
        'Stockage sécurisé indisponible — repli sur SharedPreferences. '
        'Les jetons ne seront pas chiffrés sur cet appareil.',
        e,
        s,
      );
      return;
    }

    await _migrateFromSharedPreferences();
  }

  /// Déplace une session héritée de `SharedPreferences` vers le Keystore.
  Future<void> _migrateFromSharedPreferences() async {
    final legacy = _prefs?.getString(persistSessionKey);
    if (legacy == null) return;

    try {
      final alreadyMigrated = await _secure.containsKey(key: persistSessionKey);
      if (!alreadyMigrated) {
        await _secure.write(key: persistSessionKey, value: legacy);
        AppLogger.i('Session migrée vers le stockage chiffré');
      }
      // L'original en clair est effacé dans tous les cas.
      await _prefs?.remove(persistSessionKey);
    } catch (e, s) {
      AppLogger.e('Échec de la migration de session', e, s);
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    if (_fallbackToPrefs) {
      return _prefs?.containsKey(persistSessionKey) ?? false;
    }
    try {
      return await _secure.containsKey(key: persistSessionKey);
    } catch (e, s) {
      AppLogger.e('Lecture du stockage sécurisé impossible', e, s);
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    if (_fallbackToPrefs) return _prefs?.getString(persistSessionKey);
    try {
      return await _secure.read(key: persistSessionKey);
    } catch (e, s) {
      AppLogger.e('Lecture de la session impossible', e, s);
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (_fallbackToPrefs) {
      await _prefs?.setString(persistSessionKey, persistSessionString);
      return;
    }
    try {
      await _secure.write(key: persistSessionKey, value: persistSessionString);
    } catch (e, s) {
      AppLogger.e('Écriture de la session impossible', e, s);
    }
  }

  @override
  Future<void> removePersistedSession() async {
    // Purge des DEUX emplacements : au logout, rien ne doit subsister,
    // y compris un résidu de migration.
    await _prefs?.remove(persistSessionKey);
    try {
      await _secure.delete(key: persistSessionKey);
    } catch (e, s) {
      AppLogger.e('Suppression de la session impossible', e, s);
    }
  }

  /// Efface toutes les données sensibles de l'appareil.
  ///
  /// À appeler à la déconnexion, en complément de `supabase.auth.signOut()`.
  Future<void> purgeAll() async {
    await removePersistedSession();
    try {
      await _secure.deleteAll();
    } catch (e, s) {
      AppLogger.e('Purge du stockage sécurisé impossible', e, s);
    }
  }
}
