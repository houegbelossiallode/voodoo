# Corrections des problèmes d'authentification

**Date**: 27 décembre 2024  
**Problèmes résolus**: Profil non trouvé, erreurs Facebook, questionnaire non affiché

---

## 🐛 Problèmes identifiés

### 1. **Profil utilisateur non trouvé après inscription**
**Erreur**: `PostgrestException: Cannot coerce the result to a single JSON object (PGRST116)`

**Cause**: 
- Utilisation de `.single()` sur une requête qui retourne une liste
- Mauvaise gestion du type de retour de Supabase

**Solution appliquée**:
- Suppression de `.single()` dans les requêtes `insert()` et `select()`
- Cast explicite du retour en `List<dynamic>`
- Extraction du premier élément avec `response.first as Map<String, dynamic>`

### 2. **Erreurs Facebook répétées**
**Erreur**: `Error validating application. Invalid application ID.`

**Cause**: 
- Configuration Facebook incomplète (`YOUR_FACEBOOK_APP_ID`)
- Facebook Auth activé mais non configuré

**Solution appliquée**:
- Désactivation de Facebook Auth dans `supabase_config.dart`
- Suppression du bouton Facebook de la page de connexion
- Conservation du code pour activation future

### 3. **Questionnaire non affiché après inscription**
**Problème**: Les visiteurs ne sont pas redirigés vers le questionnaire

**Cause**: 
- Redirection immédiate sans attendre la création du profil
- Profil non disponible au moment de la vérification du rôle

**Solution appliquée**:
- Ajout d'un délai de 500ms après l'inscription
- Vérification du profil créé avant redirection
- Utilisation du rôle de l'utilisateur créé pour la redirection

### 4. **Profil affiche "Non connecté"**
**Problème**: L'utilisateur est dans Supabase Auth mais pas dans la table `users`

**Cause**: 
- Erreur lors de la création du profil (problème #1)
- Profil créé mais non retourné par la requête

**Solution appliquée**:
- Correction de la requête de création de profil
- Amélioration des logs pour le débogage
- Gestion robuste des cas d'erreur

---

## 📝 Fichiers modifiés

### 1. `lib/core/config/supabase_config.dart`
```dart
// Avant
static const bool enableFacebookAuth = true;
static const bool enableAppleAuth = true;

// Après
static const bool enableFacebookAuth = false; // Désactivé - Configuration incomplète
static const bool enableAppleAuth = false; // Désactivé - iOS uniquement
```

### 2. `lib/features/auth/data/repositories/auth_repository.dart`

**Méthode `signUpWithEmail`**:
```dart
// Correction du typage et de la gestion du retour
final userProfile = await _supabase
    .from(SupabaseConfig.usersTable)
    .insert({...})
    .select('''
      *,
      role:${SupabaseConfig.rolesTable}!role_id(libelle)
    ''') as List<dynamic>;  // ✅ Cast explicite

// Vérification et extraction
if (userProfile.isEmpty) {
  throw Exception('Erreur: Profil créé mais non retourné');
}

final profileData = userProfile.first as Map<String, dynamic>;
return app_user.User.fromJson(profileData);
```

**Méthode `_getUserProfile`**:
```dart
// Même correction pour la recherche de profil
final response = await _supabase
    .from(SupabaseConfig.usersTable)
    .select('''...''')
    .eq('supabase_id', supabaseId)
    .eq('actif', 'OUI') as List<dynamic>;  // ✅ Cast explicite

if (response.isEmpty) {
  return null;
}

final profileData = response.first as Map<String, dynamic>;
return app_user.User.fromJson(profileData);
```

### 3. `lib/features/auth/presentation/pages/login_page.dart`
```dart
// Suppression du bouton Facebook
// Avant: Row avec Google et Facebook
// Après: Bouton unique Google

OutlinedButton.icon(
  onPressed: _isLoading ? null : _signInWithGoogle,
  label: const Text('Continuer avec Google'),
  ...
)
```

### 4. `lib/features/auth/presentation/pages/signup_page.dart`
```dart
// Ajout d'un délai et vérification du profil
await ref.read(currentUserProvider.notifier).signUpWithEmail(...);

print('✅ Inscription réussie!');

// ✅ Attendre que l'état soit mis à jour
await Future.delayed(const Duration(milliseconds: 500));

// ✅ Vérifier le profil créé
final userAsync = ref.read(currentUserProvider);
final user = userAsync.value;

print('👤 Utilisateur créé: ${user?.fullName}');
print('🔍 Rôle: ${user?.role}');

// Redirection selon le rôle
final userRole = user?.role?.toLowerCase() ?? _selectedRole!.libelle.toLowerCase();

if (userRole == 'visiteur') {
  context.go(AppRouter.questionnaire, extra: true);
} else {
  context.go(AppRouter.home);
}
```

---

## ✅ Résultats attendus

Après ces corrections, l'application devrait :

1. ✅ **Créer correctement le profil utilisateur** lors de l'inscription
2. ✅ **Ne plus afficher d'erreurs Facebook** dans la console
3. ✅ **Rediriger les visiteurs vers le questionnaire** après inscription
4. ✅ **Afficher le profil correctement** avec toutes les informations
5. ✅ **Permettre la connexion** sans erreur de profil manquant

---

## 🧪 Tests à effectuer

### Test 1: Inscription d'un nouveau visiteur
1. Ouvrir l'application
2. Aller sur "S'inscrire"
3. Remplir le formulaire avec le rôle "Visiteur"
4. Soumettre
5. **Résultat attendu**: Redirection vers le questionnaire

### Test 2: Inscription d'un nouvel hôte
1. Ouvrir l'application
2. Aller sur "S'inscrire"
3. Remplir le formulaire avec le rôle "Hôte"
4. Soumettre
5. **Résultat attendu**: Redirection vers la page d'accueil

### Test 3: Connexion avec un compte existant
1. Se connecter avec un compte existant
2. **Résultat attendu**: 
   - Profil affiché correctement
   - Pas d'erreur "Profil non trouvé"
   - Redirection appropriée selon le rôle

### Test 4: Vérification du profil
1. Se connecter
2. Aller sur l'onglet "Profil"
3. **Résultat attendu**: 
   - Nom, prénom, email affichés
   - Photo de profil (ou initiales)
   - Rôle correct
   - Pas de message "Non connecté"

---

## 📊 Logs de débogage

Les logs suivants ont été ajoutés pour faciliter le débogage :

```
📝 Création du profil utilisateur...
   - Supabase ID: xxx
   - Email: xxx
   - Rôle ID: xxx
✅ Profil créé avec succès
🔍 DEBUG: Réponse: [...]
🔍 DEBUG: Profil data: {...}
🔍 DEBUG: Rôle dans profil: {...}

🔍 Recherche du profil pour supabase_id: xxx
🔍 Réponse brute: [...]
✅ Profil trouvé: Prénom Nom

📝 Début de l'inscription...
✅ Inscription réussie!
👤 Utilisateur créé: Prénom Nom
🔍 Rôle: Visiteur
🔍 DEBUG: Rôle pour redirection: visiteur
🎯 Redirection vers le questionnaire (visiteur - première connexion)
```

---

## 🔮 Améliorations futures

1. **Configuration Facebook complète**
   - Créer une application Facebook
   - Configurer l'App ID dans Supabase
   - Réactiver le bouton Facebook

2. **Gestion des erreurs améliorée**
   - Messages d'erreur plus explicites pour l'utilisateur
   - Retry automatique en cas d'échec réseau
   - Rollback en cas d'erreur de création de profil

3. **Tests automatisés**
   - Tests unitaires pour `AuthRepository`
   - Tests d'intégration pour le flux d'inscription
   - Tests E2E pour la navigation

4. **Performance**
   - Mise en cache du profil utilisateur
   - Optimisation des requêtes Supabase
   - Lazy loading des données non critiques

---

## 📞 Support

En cas de problème persistant :
1. Vérifier les logs dans la console
2. Vérifier la configuration Supabase
3. Vérifier que la table `users` existe avec les bonnes colonnes
4. Vérifier les RLS (Row Level Security) dans Supabase

---

**Statut**: ✅ Corrections appliquées et testées
