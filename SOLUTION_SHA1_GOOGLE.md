# 🔧 Solution Finale - Google Sign-In avec SHA-1

## ✅ Configuration Actuelle

Vous avez :
- ✅ SHA-1 : `0D:4A:98:AE:13:1F:15:76:70:71:A6:3D:B6:AA:2D:B9:A8:EE:29:B2`
- ✅ Web Client ID : `563099795585-f9pr51ihtuvcv8s4n23cpcr2r9m80msf`
- ✅ Android Client ID : `563099795585-t6toaj2erv817l9hho0lrhivivq6g18p`

---

## 🎯 Problème Identifié

L'erreur `ApiException: 7` se produit lors de l'appel à `googleSignIn.signIn()`, ce qui signifie que **Google Play Services ne peut pas valider votre application**.

---

## 🔍 Vérifications Critiques à Faire

### 1. **Vérifier que le SHA-1 est sur le Client ID Android**

Dans Google Cloud Console :
1. Allez dans **API et services** → **Identifiants**
2. Cliquez sur le **Client ID Android** : `563099795585-t6toaj2erv817l9hho0lrhivivq6g18p`
3. Vérifiez que :
   - **Nom du package** = `com.example.vodou`
   - **Empreinte SHA-1** = `0D:4A:98:AE:13:1F:15:76:70:71:A6:3D:B6:AA:2D:B9:A8:EE:29:B2`

⚠️ **IMPORTANT** : Le SHA-1 doit être sur le **Client ID Android**, PAS sur le Web Client ID.

---

### 2. **Vérifier le Package Name Partout**

Le package name doit être **identique** dans :
- ✅ `android/app/build.gradle.kts` → `applicationId = "com.example.vodou"`
- ✅ `android/app/src/main/AndroidManifest.xml` → `package="com.example.vodou"`
- ✅ Google Cloud Console → Client ID Android → Nom du package

---

### 3. **Vérifier que les Deux Client IDs sont dans Supabase**

Dans Supabase Dashboard → Authentication → Providers → Google :

**Client IDs** doit contenir **les deux** (séparés par une virgule) :
```
563099795585-f9pr51ihtuvcv8s4n23cpcr2r9m80msf.apps.googleusercontent.com,563099795585-t6toaj2erv817l9hho0lrhivivq6g18p.apps.googleusercontent.com
```

C'est déjà le cas dans votre configuration ✅

---

## 🔧 Solution Alternative : Forcer l'Utilisation du Client ID Android

Si le problème persiste, essayez d'utiliser le **Client ID Android** dans le code :

### Option 1 : Tester avec Android Client ID

Modifiez temporairement `lib/core/config/supabase_config.dart` :

```dart
// Test avec Android Client ID
static const String googleClientId =
    '563099795585-t6toaj2erv817l9hho0lrhivivq6g18p.apps.googleusercontent.com';
```

Testez avec `flutter run`. Si ça fonctionne, le problème vient de la configuration du Web Client ID.

---

## 🚨 Causes Possibles de l'Erreur Persistante

### Cause 1 : SHA-1 Non Propagé

**Symptôme** : Vous venez d'ajouter le SHA-1

**Solution** : Attendez 10-15 minutes pour la propagation, puis :
```bash
flutter clean
flutter run
```

### Cause 2 : Mauvais SHA-1

**Symptôme** : Le SHA-1 ne correspond pas à votre keystore

**Solution** : Régénérez le SHA-1 et vérifiez qu'il correspond :
```bash
cd android
gradlew signingReport
```

Comparez avec : `0D:4A:98:AE:13:1F:15:76:70:71:A6:3D:B6:AA:2D:B9:A8:EE:29:B2`

### Cause 3 : Package Name Incorrect

**Symptôme** : Le package name ne correspond pas

**Solution** : Vérifiez dans `android/app/build.gradle.kts` :
```kotlin
applicationId = "com.example.vodou"  // Doit correspondre exactement
```

### Cause 4 : Client ID Android Non Créé

**Symptôme** : Le Client ID Android n'existe pas dans Google Cloud Console

**Solution** : Créez-le :
1. Google Cloud Console → API et services → Identifiants
2. **+ CRÉER DES IDENTIFIANTS** → **ID client OAuth 2.0**
3. Type : **Application Android**
4. Nom du package : `com.example.vodou`
5. SHA-1 : `0D:4A:98:AE:13:1F:15:76:70:71:A6:3D:B6:AA:2D:B9:A8:EE:29:B2`

### Cause 5 : Google Play Services Obsolète

**Symptôme** : Version de Google Play Services trop ancienne sur l'émulateur/appareil

**Solution** : Mettez à jour Google Play Services sur votre appareil/émulateur

---

## 🧪 Test Final

```bash
flutter clean
flutter pub get
flutter run
```

Observez les nouveaux logs :
```
🔍 DEBUG: Web Client ID = 563099795585-f9pr51ihtuvcv8s4n23cpcr2r9m80msf...
🔍 DEBUG: Android Client ID = 563099795585-t6toaj2erv817l9hho0lrhivivq6g18p...
```

---

## 📋 Checklist Complète

Avant de tester, vérifiez que **TOUS** ces points sont ✅ :

### Google Cloud Console
- [ ] Client ID Android existe avec le SHA-1 `0D:4A:98:AE:13:1F:15:76:70:71:A6:3D:B6:AA:2D:B9:A8:EE:29:B2`
- [ ] Package name dans Client ID Android = `com.example.vodou`
- [ ] Client ID Web existe avec URI de redirection Supabase
- [ ] Scopes `email`, `profile`, `openid` dans l'écran de consentement

### Supabase Dashboard
- [ ] Google activé
- [ ] Client ID (Web) configuré
- [ ] Client Secret configuré
- [ ] Les deux Client IDs dans "Client IDs" (optionnel mais recommandé)

### Code Flutter
- [ ] `googleClientId` = Web Client ID
- [ ] `googleAndroidClientId` = Android Client ID (ajouté)
- [ ] Package name = `com.example.vodou` partout

### Système
- [ ] `flutter clean` effectué
- [ ] Attendre 10-15 minutes après ajout du SHA-1
- [ ] Google Play Services à jour sur l'appareil

---

## 🎯 Si Ça Ne Fonctionne Toujours Pas

Envoyez-moi une capture d'écran de :
1. Google Cloud Console → Identifiants → Client ID Android (montrant le SHA-1 et package name)
2. Les nouveaux logs après `flutter run`

---

**Le SHA-1 est la clé. Une fois correctement configuré dans le Client ID Android avec le bon package name, l'erreur disparaîtra ! 🎉**
