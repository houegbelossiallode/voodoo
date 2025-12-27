# 🔵 Configuration Google Sign-In avec Supabase (Sans Firebase)

## ✅ Corrections Appliquées

1. ✅ **google-services.json supprimé** - Non nécessaire pour Supabase
2. ✅ **Plugin Google Services retiré** - Non nécessaire pour Supabase
3. ✅ **Dépendances Google Play Services conservées** - Nécessaires pour Google Sign-In

---

## 🔧 Configuration Requise

### **Étape 1: Obtenir le Web Client ID depuis Google Cloud Console**

Vous avez déjà configuré le Client ID dans Supabase. Maintenant, vous devez mettre à jour votre code Flutter avec ce même Client ID.

1. Allez sur https://console.cloud.google.com
2. Sélectionnez votre projet
3. Allez dans **"API et services"** → **"Identifiants"**
4. Trouvez votre **"ID client OAuth 2.0"** de type **"Application Web"**
5. **Copiez le Client ID** (format: `123456789012-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com`)

⚠️ **IMPORTANT**: Utilisez le **Web Client ID**, PAS le Client ID Android !

---

### **Étape 2: Mettre à jour supabase_config.dart**

Ouvrez `lib/core/config/supabase_config.dart` et remplacez la ligne 67-68 :

```dart
// AVANT (ligne 67-68)
static const String googleClientId =
    'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';

// APRÈS (remplacez par votre vrai Client ID Web)
static const String googleClientId =
    '123456789012-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com';
```

---

### **Étape 3: Vérifier la configuration Supabase**

Dans votre Supabase Dashboard :

1. Allez dans **Authentication** → **Providers** → **Google**
2. Vérifiez que :
   - ✅ Google est **activé**
   - ✅ **Client ID** (Web) est renseigné
   - ✅ **Client Secret** est renseigné
3. Copiez l'**URL de redirection** fournie par Supabase :
   ```
   https://vbfgfbqgtattrajdmeit.supabase.co/auth/v1/callback
   ```

---

### **Étape 4: Configurer l'URI de redirection dans Google Cloud Console**

1. Retournez sur https://console.cloud.google.com
2. Allez dans **"API et services"** → **"Identifiants"**
3. Cliquez sur votre **ID client OAuth 2.0 Web**
4. Dans **"URI de redirection autorisés"**, ajoutez :
   ```
   https://vbfgfbqgtattrajdmeit.supabase.co/auth/v1/callback
   ```
5. Cliquez sur **"Enregistrer"**

---

## 🎯 Comment ça Fonctionne (Sans Firebase)

### Flux d'Authentification

```
1. Utilisateur clique sur "Se connecter avec Google"
   ↓
2. GoogleSignIn s'ouvre avec serverClientId (Web Client ID)
   ↓
3. Utilisateur sélectionne son compte Google
   ↓
4. Google retourne accessToken + idToken
   ↓
5. Flutter envoie les tokens à Supabase via signInWithIdToken()
   ↓
6. Supabase valide les tokens avec Google
   ↓
7. Supabase crée/récupère la session utilisateur
   ↓
8. Profil utilisateur créé/récupéré dans la table users
   ↓
9. Utilisateur connecté ✅
```

### Code Actuel (auth_repository.dart)

Le code est déjà correctement configuré :

```dart
// Ligne 233-235
final GoogleSignIn googleSignIn = GoogleSignIn(
  serverClientId: SupabaseConfig.googleClientId, // ← Utilise le Web Client ID
);
```

**Pourquoi `serverClientId` ?**
- `serverClientId` = Web Client ID pour l'authentification côté serveur (Supabase)
- Permet à Supabase de valider les tokens Google
- Pas besoin de Firebase ni de google-services.json

---

## 🧪 Tester Google Sign-In

### Étape 1: Nettoyer et Reconstruire

```bash
flutter clean
flutter pub get
flutter run
```

### Étape 2: Tester la Connexion

1. Lancez l'application
2. Cliquez sur **"Se connecter avec Google"**
3. Sélectionnez votre compte Google
4. Autorisez l'application

**Logs attendus** :
```
🔵 AuthRepository: Début authentification Google...
✅ AuthRepository: Utilisateur Google: votre.email@gmail.com
✅ AuthRepository: Tokens Google récupérés
✅ AuthRepository: Authentification Supabase réussie
✅ AuthRepository: Profil utilisateur prêt
```

---

## 🚨 Résolution des Erreurs

### Erreur: `ApiException: 7` (NETWORK_ERROR)

**Cause** :
- Web Client ID manquant ou incorrect dans `supabase_config.dart`

**Solution** :
1. Vérifiez que `googleClientId` dans `supabase_config.dart` est bien renseigné
2. Vérifiez que c'est le **Web Client ID**, pas le Client ID Android
3. Format attendu : `123456789012-xxxxx.apps.googleusercontent.com`

### Erreur: `ApiException: 10` (DEVELOPER_ERROR)

**Cause** :
- Client ID incorrect
- URI de redirection non configuré

**Solution** :
1. Vérifiez le Client ID dans Google Cloud Console
2. Vérifiez que l'URI de redirection Supabase est bien ajouté
3. Relancez `flutter clean && flutter run`

### Erreur: `PlatformException(sign_in_canceled)`

**Cause** :
- L'utilisateur a annulé la connexion

**Solution** :
- Normal, aucune action requise

### Erreur: Supabase `Invalid login credentials`

**Cause** :
- Client ID ou Client Secret incorrect dans Supabase Dashboard

**Solution** :
1. Vérifiez dans Supabase Dashboard → Authentication → Providers → Google
2. Vérifiez que le Client ID et Client Secret correspondent à ceux de Google Cloud Console
3. Régénérez le Client Secret si nécessaire

---

## 📋 Checklist Finale

Avant de tester, vérifiez que :

- [ ] Web Client ID copié depuis Google Cloud Console
- [ ] `supabase_config.dart` mis à jour avec le vrai Web Client ID
- [ ] Google activé dans Supabase Dashboard
- [ ] Client ID et Client Secret configurés dans Supabase
- [ ] URI de redirection Supabase ajouté dans Google Cloud Console
- [ ] `flutter clean` et rebuild effectués

---

## 🎯 Différences avec Firebase

| Aspect | Avec Firebase | Avec Supabase (Actuel) |
|--------|---------------|------------------------|
| **google-services.json** | ✅ Requis | ❌ Non nécessaire |
| **Plugin Google Services** | ✅ Requis | ❌ Non nécessaire |
| **Client ID** | Android Client ID | **Web Client ID** |
| **Validation** | Firebase Auth | Supabase Auth |
| **Configuration** | Firebase Console | Google Cloud + Supabase |

---

## ✅ Avantages de cette Approche

1. **Plus simple** : Pas besoin de Firebase
2. **Moins de dépendances** : Pas de google-services.json
3. **Direct** : Communication directe entre Google et Supabase
4. **Flexible** : Fonctionne sur toutes les plateformes (Android, iOS, Web)

---

## 📞 Support

Si vous rencontrez toujours l'erreur `ApiException: 7` après avoir mis à jour le `googleClientId`, vérifiez :

1. **Format du Client ID** :
   ```dart
   // ✅ Correct
   '123456789012-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com'
   
   // ❌ Incorrect
   'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com'
   ```

2. **Type de Client ID** :
   - ✅ Utilisez le **Web Client ID** (Application Web)
   - ❌ N'utilisez PAS le Client ID Android

3. **Supabase Dashboard** :
   - Vérifiez que Google est bien activé
   - Vérifiez que le même Client ID est configuré

---

**🎉 Une fois le Web Client ID configuré dans `supabase_config.dart`, Google Sign-In fonctionnera parfaitement avec Supabase !**
