# 🔐 Configuration OAuth - Google & Facebook

## ✅ Corrections Appliquées

### 1. **AndroidManifest.xml**
- ✅ Ajout de la configuration Facebook (ApplicationId, ClientToken)
- ✅ Ajout des activités Facebook (FacebookActivity, CustomTabActivity)
- ✅ Configuration des intent-filters pour le deep linking

### 2. **build.gradle.kts**
- ✅ `minSdk = 21` (requis pour Google Sign-In et Facebook)
- ✅ `multiDexEnabled = true` (support des grandes applications)
- ✅ Dépendances ajoutées :
  - Google Play Services Auth: `20.7.0`
  - Facebook Android SDK: `16.2.0`
  - MultiDex: `2.0.1`

### 3. **strings.xml**
- ✅ Créé avec les placeholders Facebook
- ⚠️ **À REMPLACER** avec vos vraies clés

---

## 🔧 Configuration Requise

### 📱 **Facebook Login**

#### Étape 1: Obtenir les Clés Facebook
1. Allez sur https://developers.facebook.com/apps
2. Créez une application ou sélectionnez une existante
3. Dans **Paramètres > Général**, récupérez :
   - **App ID** (ID de l'application)
   - **Client Token** (Jeton client)

#### Étape 2: Configurer strings.xml
Ouvrez `android/app/src/main/res/values/strings.xml` et remplacez :

```xml
<string name="facebook_app_id">1234567890123456</string>
<string name="facebook_client_token">abcdef1234567890abcdef1234567890</string>
<string name="fb_login_protocol_scheme">fb1234567890123456</string>
```

**Note**: Le `fb_login_protocol_scheme` doit être `fb` + votre App ID

#### Étape 3: Configurer Facebook Dashboard
1. Dans **Facebook Login > Paramètres**
2. Ajoutez l'URI de redirection OAuth :
   ```
   fbYOUR_APP_ID://authorize
   ```

3. Dans **Paramètres > Général**, ajoutez votre package Android :
   ```
   com.example.vodou
   ```

4. Ajoutez le **Key Hash** de votre application :

**Générer le Key Hash** :
```bash
# Sur Windows (avec OpenSSL installé)
keytool -exportcert -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore | openssl sha1 -binary | openssl base64

# Mot de passe par défaut: android
```

Copiez le hash généré et ajoutez-le dans **Facebook Dashboard > Paramètres > Général > Key Hashes**

---

### 🔵 **Google Sign-In**

#### Étape 1: Obtenir le SHA-1 de votre application

**Sur Windows** :
```bash
cd android
./gradlew signingReport
```

**Ou avec keytool** :
```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copiez le **SHA-1** affiché (format: `AA:BB:CC:DD:...`)

#### Étape 2: Configurer Google Cloud Console
1. Allez sur https://console.cloud.google.com
2. Créez un projet ou sélectionnez-en un
3. Activez **Google Sign-In API**
4. Allez dans **Identifiants > Créer des identifiants > ID client OAuth 2.0**
5. Sélectionnez **Application Android**
6. Remplissez :
   - **Nom** : Vodou Host Android
   - **Nom du package** : `com.example.vodou`
   - **Empreinte SHA-1** : Collez le SHA-1 obtenu à l'étape 1

7. Cliquez sur **Créer**

#### Étape 3: Télécharger google-services.json
1. Dans Google Cloud Console, téléchargez le fichier `google-services.json`
2. Placez-le dans : `android/app/google-services.json`

#### Étape 4: Mettre à jour build.gradle.kts (racine)
Ouvrez `android/build.gradle.kts` et ajoutez :

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

#### Étape 5: Mettre à jour build.gradle.kts (app)
Ouvrez `android/app/build.gradle.kts` et ajoutez en haut :

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← Ajoutez cette ligne
}
```

#### Étape 6: Mettre à jour SupabaseConfig
Ouvrez `lib/core/config/supabase_config.dart` et remplacez :

```dart
static const String googleClientId = 'VOTRE_CLIENT_ID.apps.googleusercontent.com';
```

**Où trouver le Client ID ?**
- Dans Google Cloud Console > Identifiants
- Copiez le **Client ID** de type "Application Android"
- Format: `123456789012-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com`

---

## 🧪 Tester l'Authentification

### Étape 1: Nettoyer et Reconstruire
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### Étape 2: Tester Facebook Login
1. Lancez l'application
2. Cliquez sur "Se connecter avec Facebook"
3. Autorisez l'application
4. Vérifiez les logs :
   ```
   ✅ AuthRepository: Authentification Supabase réussie
   ✅ AuthRepository: Profil utilisateur prêt
   ```

### Étape 3: Tester Google Sign-In
1. Lancez l'application
2. Cliquez sur "Se connecter avec Google"
3. Sélectionnez un compte Google
4. Vérifiez les logs :
   ```
   ✅ AuthRepository: Tokens Google récupérés
   ✅ AuthRepository: Authentification Supabase réussie
   ```

---

## 🚨 Résolution des Erreurs

### Erreur: `PlatformException(sign_in_failed)`
**Causes possibles** :
- SHA-1 non configuré dans Google Cloud Console
- `google-services.json` manquant
- Client ID incorrect dans `supabase_config.dart`

**Solution** :
1. Vérifiez que le SHA-1 est bien ajouté dans Google Cloud Console
2. Téléchargez et placez `google-services.json` dans `android/app/`
3. Vérifiez le Client ID dans `supabase_config.dart`
4. Relancez `flutter clean && flutter run`

### Erreur: `MissingPluginException` (Facebook)
**Causes possibles** :
- Dépendances non installées
- Application non reconstruite après modifications

**Solution** :
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### Erreur: `DEVELOPER_ERROR` (Google)
**Causes possibles** :
- SHA-1 ne correspond pas
- Package name incorrect

**Solution** :
1. Régénérez le SHA-1 avec `./gradlew signingReport`
2. Vérifiez que le package name est bien `com.example.vodou`
3. Mettez à jour Google Cloud Console avec le bon SHA-1

### Erreur: Facebook Key Hash invalide
**Solution** :
```bash
# Régénérez le Key Hash
keytool -exportcert -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore | openssl sha1 -binary | openssl base64

# Ajoutez-le dans Facebook Dashboard
```

---

## 📋 Checklist Finale

### Facebook
- [ ] App ID et Client Token dans `strings.xml`
- [ ] Package name ajouté dans Facebook Dashboard
- [ ] Key Hash ajouté dans Facebook Dashboard
- [ ] URI de redirection configurée

### Google
- [ ] SHA-1 ajouté dans Google Cloud Console
- [ ] `google-services.json` dans `android/app/`
- [ ] Plugin Google Services ajouté dans `build.gradle.kts`
- [ ] Client ID dans `supabase_config.dart`

### Général
- [ ] `minSdk = 21` dans `build.gradle.kts`
- [ ] Dépendances ajoutées (Google Play Services, Facebook SDK)
- [ ] `flutter clean` et rebuild effectués

---

## 🎯 Commandes Utiles

```bash
# Obtenir le SHA-1
cd android && ./gradlew signingReport

# Obtenir le Key Hash Facebook
keytool -exportcert -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore | openssl sha1 -binary | openssl base64

# Nettoyer et reconstruire
flutter clean && flutter pub get && flutter run

# Voir les logs détaillés
flutter run --verbose
```

---

## 📞 Support

En cas de problème persistant :
1. Vérifiez les logs Flutter avec `flutter run --verbose`
2. Consultez la documentation officielle :
   - Google Sign-In: https://pub.dev/packages/google_sign_in
   - Facebook Login: https://pub.dev/packages/flutter_facebook_auth
3. Vérifiez que toutes les clés sont correctement configurées

---

**✅ Une fois ces configurations effectuées, les authentifications Google et Facebook fonctionneront correctement !**
