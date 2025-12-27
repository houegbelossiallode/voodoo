# 🔧 Solution Complète - Google Sign-In ApiException: 7

## ✅ Modifications Appliquées

### 1. Scopes Ajoutés dans auth_repository.dart

```dart
final GoogleSignIn googleSignIn = GoogleSignIn(
  serverClientId: SupabaseConfig.googleClientId,
  scopes: [
    'email',
    'profile',
    'openid',
  ],
);
```

**Pourquoi ?** Les scopes `email`, `profile`, et `openid` sont nécessaires pour que Google génère des tokens valides pour Supabase.

---

## 🎯 Vérifications Obligatoires

### 1. Supabase Dashboard - Configuration Google

Allez sur https://supabase.com/dashboard → Votre projet → **Authentication** → **Providers** → **Google**

**Vérifiez que** :

1. ✅ Google est **activé** (toggle ON)

2. ✅ **Client ID (for OAuth)** est renseigné :
   ```
   563099795585-f9pr51ihtuvcv8s4n23cpcr2r9m80msf.apps.googleusercontent.com
   ```

3. ✅ **Client Secret (for OAuth)** est renseigné :
   - Copiez-le depuis Google Cloud Console
   - Ne laissez PAS ce champ vide

4. ✅ **Authorized Client IDs** (optionnel mais recommandé) :
   - Ajoutez le Client ID Android si vous voulez supporter les deux :
   ```
   563099795585-t6toaj2erv817l9hho0lrhivivq6g18p.apps.googleusercontent.com
   ```

5. ✅ Cliquez sur **"Save"** après toute modification

---

### 2. Google Cloud Console - URI de Redirection

Allez sur https://console.cloud.google.com → **API et services** → **Identifiants**

**Pour le Web Client ID** (`563099795585-f9pr51ihtuvcv8s4n23cpcr2r9m80msf`) :

1. Cliquez sur le Client ID
2. Dans **"URI de redirection autorisés"**, ajoutez :
   ```
   https://vbfgfbqgtattrajdmeit.supabase.co/auth/v1/callback
   ```
3. Cliquez sur **"Enregistrer"**
4. **Attendez 5-10 minutes** pour la propagation des changements

---

### 3. Google Cloud Console - Écran de Consentement OAuth

Allez sur https://console.cloud.google.com → **API et services** → **Écran de consentement OAuth**

**Vérifiez que** :

1. ✅ **Statut de publication** :
   - Si **"Test"** : Ajoutez votre email dans **"Utilisateurs test"**
   - Si **"En production"** : Tout le monde peut se connecter

2. ✅ **Champs d'application** :
   - `.../auth/userinfo.email`
   - `.../auth/userinfo.profile`
   - `openid`

3. Si ces scopes ne sont pas là, ajoutez-les :
   - Cliquez sur **"Modifier l'application"**
   - **"Champs d'application"** → **"Ajouter ou supprimer des champs d'application"**
   - Recherchez et ajoutez : `email`, `profile`, `openid`
   - Cliquez sur **"Enregistrer et continuer"**

---

### 4. Google Cloud Console - API Activées

Allez sur https://console.cloud.google.com → **API et services** → **Bibliothèque**

**Vérifiez que ces APIs sont activées** :

1. ✅ **Google+ API** (ou **People API**)
2. ✅ **Google Sign-In API**

Si elles ne sont pas activées :
- Recherchez-les dans la bibliothèque
- Cliquez sur **"Activer"**

---

## 🧪 Test Complet

### Étape 1 : Nettoyer le Cache

```bash
flutter clean
flutter pub get
cd android
gradlew clean
cd ..
```

### Étape 2 : Relancer l'Application

```bash
flutter run --verbose
```

### Étape 3 : Tester Google Sign-In

1. Cliquez sur **"Se connecter avec Google"**
2. Sélectionnez votre compte Google
3. Observez les logs

**Logs attendus si ça fonctionne** :
```
🔵 AuthRepository: Début authentification Google...
✅ AuthRepository: Utilisateur Google: votre.email@gmail.com
✅ AuthRepository: Tokens Google récupérés
✅ AuthRepository: Authentification Supabase réussie
✅ AuthRepository: Profil utilisateur prêt
```

---

## 🚨 Si l'Erreur Persiste

### Diagnostic Avancé

Ajoutez des logs supplémentaires pour identifier où ça bloque :

```dart
// Dans auth_repository.dart, après la ligne 249
print('🔍 DEBUG: accessToken présent: ${accessToken != null}');
print('🔍 DEBUG: idToken présent: ${idToken != null}');
print('🔍 DEBUG: serverClientId: ${SupabaseConfig.googleClientId}');
```

### Causes Possibles et Solutions

#### Cause 1 : Client Secret Manquant dans Supabase

**Symptôme** : L'erreur se produit après avoir sélectionné le compte Google

**Solution** :
1. Allez dans Google Cloud Console → Identifiants → Web Client ID
2. **Copiez le Client Secret** (cliquez sur l'icône œil pour le révéler)
3. Allez dans Supabase Dashboard → Authentication → Providers → Google
4. **Collez le Client Secret** dans le champ correspondant
5. Cliquez sur **"Save"**

#### Cause 2 : URI de Redirection Non Configuré

**Symptôme** : L'erreur se produit immédiatement après la sélection du compte

**Solution** :
1. Vérifiez que l'URI `https://vbfgfbqgtattrajdmeit.supabase.co/auth/v1/callback` est bien dans Google Cloud Console
2. Vérifiez qu'elle est dans le **Web Client ID**, pas l'Android
3. Attendez 5-10 minutes après l'ajout
4. Relancez l'application

#### Cause 3 : Scopes Manquants dans Google Cloud Console

**Symptôme** : Erreur de permission ou de consentement

**Solution** :
1. Google Cloud Console → Écran de consentement OAuth
2. Vérifiez que `email`, `profile`, `openid` sont dans les champs d'application
3. Si manquants, ajoutez-les via **"Modifier l'application"**

#### Cause 4 : Application en Mode Test sans Utilisateur Test

**Symptôme** : Erreur "access_denied" ou similaire

**Solution** :
1. Google Cloud Console → Écran de consentement OAuth
2. Si **"Statut de publication"** = **"Test"**
3. Ajoutez votre email dans **"Utilisateurs test"**
4. Ou passez en **"En production"** (nécessite vérification Google)

#### Cause 5 : Cache Google Play Services

**Symptôme** : L'erreur persiste malgré toutes les configurations correctes

**Solution** :
```bash
# Désinstaller complètement l'application
flutter clean
adb uninstall com.example.vodou

# Réinstaller
flutter run
```

---

## 📋 Checklist Finale Complète

Avant de tester, vérifiez que **TOUS** ces points sont ✅ :

### Configuration Code
- [ ] Web Client ID configuré dans `supabase_config.dart`
- [ ] Scopes `email`, `profile`, `openid` ajoutés dans `auth_repository.dart`
- [ ] `flutter clean` effectué

### Configuration Supabase
- [ ] Google activé dans Supabase Dashboard
- [ ] Client ID (Web) configuré
- [ ] **Client Secret configuré** (CRITIQUE)
- [ ] Modifications sauvegardées

### Configuration Google Cloud Console
- [ ] URI de redirection Supabase ajouté dans le Web Client ID
- [ ] Scopes `email`, `profile`, `openid` dans l'écran de consentement
- [ ] Google+ API ou People API activée
- [ ] Si mode Test : Email ajouté dans utilisateurs test
- [ ] Changements sauvegardés et propagés (attendre 5-10 min)

---

## 🎯 Commandes de Débogage

```bash
# Nettoyer complètement
flutter clean
cd android
gradlew clean
cd ..
flutter pub get

# Désinstaller l'app
adb uninstall com.example.vodou

# Réinstaller avec logs détaillés
flutter run --verbose

# Voir les logs en temps réel
adb logcat | grep -i "google\|auth\|oauth"
```

---

## 📞 Vérification Rapide du Client Secret

Le **Client Secret** est souvent la cause de l'erreur ApiException: 7.

**Comment vérifier** :

1. Supabase Dashboard → Authentication → Providers → Google
2. Le champ **"Client Secret (for OAuth)"** doit contenir une longue chaîne de caractères
3. Si vide ou si vous voyez des `*****`, cliquez sur **"Edit"** et recollez le vrai secret

**Où trouver le Client Secret** :

1. Google Cloud Console → API et services → Identifiants
2. Cliquez sur le **Web Client ID** (`563099795585-f9pr51ihtuvcv8s4n23cpcr2r9m80msf`)
3. Le **Client Secret** est affiché (cliquez sur l'icône œil si masqué)
4. Copiez-le et collez-le dans Supabase

---

## ✅ Résumé

**Problème** : `ApiException: 7` = Google ne peut pas valider les tokens avec Supabase

**Causes Principales** :
1. ❌ Client Secret manquant dans Supabase (TRÈS FRÉQUENT)
2. ❌ URI de redirection non configuré
3. ❌ Scopes manquants
4. ❌ API Google non activée

**Solution** :
1. ✅ Ajout des scopes dans le code
2. ✅ Configuration complète dans Supabase (Client ID + Secret)
3. ✅ URI de redirection dans Google Cloud Console
4. ✅ Scopes dans l'écran de consentement OAuth

---

**Une fois toutes ces vérifications effectuées, Google Sign-In fonctionnera ! 🎉**
