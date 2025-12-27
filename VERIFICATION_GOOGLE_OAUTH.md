# ✅ Vérification Configuration Google OAuth

## 🔧 Configuration Appliquée

J'ai configuré le Web Client ID dans votre code :

```dart
// lib/core/config/supabase_config.dart
static const String googleClientId =
    '563099795585-f9pr51ihtuvcv8s4n23cpcr2r9m80msf.apps.googleusercontent.com';
```

---

## 🔍 Vos 2 Client IDs

Vous avez 2 Client IDs :

1. **563099795585-f9pr51ihtuvcv8s4n23cpcr2r9m80msf** (Premier)
2. **563099795585-t6toaj2erv817l9hho0lrhivivq6g18p** (Second)

### Comment Identifier Lequel est Web vs Android ?

Allez sur https://console.cloud.google.com → **API et services** → **Identifiants**

Pour chaque Client ID, vérifiez le **Type** :
- **Application Web** → Utilisez celui-ci pour Supabase ✅
- **Application Android** → Ne pas utiliser dans le code Flutter

---

## ⚠️ Vérifications Critiques

### 1. Vérifier Supabase Dashboard

1. Allez sur https://supabase.com/dashboard
2. Sélectionnez votre projet **Vodou**
3. **Authentication** → **Providers** → **Google**
4. Vérifiez que :
   - ✅ Google est **activé** (toggle ON)
   - ✅ **Client ID** = Le même que dans votre code (Web Client ID)
   - ✅ **Client Secret** est renseigné

**IMPORTANT** : Le Client ID dans Supabase DOIT être le **Web Client ID**, le même que dans votre code Flutter.

### 2. Vérifier URI de Redirection dans Google Cloud Console

1. https://console.cloud.google.com
2. **API et services** → **Identifiants**
3. Cliquez sur votre **ID client OAuth 2.0 Web**
4. Dans **"URI de redirection autorisés"**, vérifiez que cette URL est présente :
   ```
   https://vbfgfbqgtattrajdmeit.supabase.co/auth/v1/callback
   ```

Si elle n'est pas là, ajoutez-la et cliquez sur **"Enregistrer"**.

### 3. Vérifier l'Écran de Consentement OAuth

1. https://console.cloud.google.com
2. **API et services** → **Écran de consentement OAuth**
3. Vérifiez que :
   - ✅ Statut : **En production** ou **Test**
   - ✅ Si en mode **Test**, ajoutez votre email dans **"Utilisateurs test"**

---

## 🎯 Si l'Erreur Persiste (ApiException: 7)

### Cause Possible 1 : Mauvais Client ID dans le Code

**Vérification** :
- J'ai utilisé le premier Client ID : `563099795585-f9pr51ihtuvcv8s4n23cpcr2r9m80msf`
- Si c'est le Client ID **Android** au lieu du **Web**, l'erreur persistera

**Solution** :
1. Vérifiez dans Google Cloud Console quel est le **Web Client ID**
2. Si c'est le second (`563099795585-t6toaj2erv817l9hho0lrhivivq6g18p`), mettez à jour :

```dart
// lib/core/config/supabase_config.dart
static const String googleClientId =
    '563099795585-t6toaj2erv817l9hho0lrhivivq6g18p.apps.googleusercontent.com';
```

### Cause Possible 2 : Client ID Différent dans Supabase

**Vérification** :
- Le Client ID dans Supabase Dashboard doit être **identique** à celui dans votre code

**Solution** :
1. Vérifiez le Client ID dans Supabase Dashboard
2. Si différent, mettez à jour soit Supabase, soit votre code pour qu'ils correspondent

### Cause Possible 3 : URI de Redirection Manquant

**Vérification** :
- L'URI de redirection Supabase doit être dans Google Cloud Console

**Solution** :
1. Ajoutez `https://vbfgfbqgtattrajdmeit.supabase.co/auth/v1/callback` dans les URI autorisés
2. Attendez 5-10 minutes pour la propagation
3. Relancez l'application

### Cause Possible 4 : Client Secret Incorrect dans Supabase

**Vérification** :
- Le Client Secret dans Supabase doit correspondre à celui de Google Cloud Console

**Solution** :
1. Dans Google Cloud Console → Identifiants → Cliquez sur le Web Client ID
2. Copiez le **Client Secret**
3. Collez-le dans Supabase Dashboard → Authentication → Providers → Google
4. Cliquez sur **Save**

---

## 🧪 Test Complet

### Étape 1 : Nettoyer et Reconstruire

```bash
flutter clean
flutter pub get
flutter run
```

### Étape 2 : Tester la Connexion

1. Lancez l'application
2. Cliquez sur **"Se connecter avec Google"**
3. Sélectionnez votre compte Google
4. Observez les logs

**Logs attendus si ça fonctionne** :
```
🔵 AuthRepository: Début authentification Google...
✅ AuthRepository: Utilisateur Google: votre.email@gmail.com
✅ AuthRepository: Tokens Google récupérés
✅ AuthRepository: Authentification Supabase réussie
✅ AuthRepository: Profil utilisateur prêt
```

**Logs si erreur persiste** :
```
❌ AuthRepository: Erreur Google - PlatformException(network_error, com.google.android.gms.common.api.ApiException: 7:, null, null)
```

---

## 🔄 Procédure de Diagnostic

Si l'erreur persiste après `flutter clean && flutter run`, suivez cette procédure :

### 1. Identifier le Bon Client ID

```bash
# Dans Google Cloud Console, pour chaque Client ID, notez :
# - Type (Web ou Android)
# - Client ID complet
# - Client Secret (pour Web uniquement)
```

### 2. Tableau de Vérification

| Élément | Valeur Attendue | Votre Valeur | ✅/❌ |
|---------|----------------|--------------|-------|
| **Code Flutter** | Web Client ID | 563099795585-f9pr51ihtuvcv8s4n23cpcr2r9m80msf | ? |
| **Supabase Dashboard** | Même Web Client ID | ? | ? |
| **Google Cloud Console** | URI de redirection Supabase | https://vbfgfbqgtattrajdmeit.supabase.co/auth/v1/callback | ? |
| **Supabase Dashboard** | Client Secret renseigné | ******** | ? |

### 3. Actions Correctives

Si une case est ❌ :
- **Code Flutter ≠ Supabase** → Mettez à jour le code avec le Client ID de Supabase
- **URI manquant** → Ajoutez-le dans Google Cloud Console
- **Client Secret vide** → Copiez-le depuis Google Cloud Console vers Supabase

---

## 📞 Commandes de Débogage

```bash
# Voir les logs détaillés
flutter run --verbose

# Nettoyer complètement
flutter clean
cd android
gradlew clean
cd ..
flutter pub get
flutter run

# Vérifier la configuration Gradle
cd android
gradlew dependencies
```

---

## ✅ Checklist Finale

Avant de tester, vérifiez que TOUS ces points sont ✅ :

- [ ] Web Client ID identifié dans Google Cloud Console
- [ ] Web Client ID configuré dans `supabase_config.dart`
- [ ] Même Web Client ID dans Supabase Dashboard
- [ ] Client Secret configuré dans Supabase Dashboard
- [ ] URI de redirection Supabase ajouté dans Google Cloud Console
- [ ] Google activé dans Supabase Dashboard
- [ ] `flutter clean` effectué
- [ ] Application relancée

---

## 🎯 Résumé

**Problème** : `ApiException: 7` = Google ne peut pas valider les tokens

**Causes Principales** :
1. Mauvais Client ID (Android au lieu de Web)
2. Client ID différent entre code et Supabase
3. URI de redirection manquant
4. Client Secret incorrect

**Solution** :
- Utilisez le **Web Client ID** partout
- Assurez-vous que code Flutter = Supabase Dashboard
- Ajoutez l'URI de redirection Supabase dans Google Cloud Console

---

**Une fois toutes les vérifications effectuées, Google Sign-In fonctionnera ! 🎉**
