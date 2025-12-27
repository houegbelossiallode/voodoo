# 🔵 Configuration Google Sign-In - Guide Complet

## ❌ Erreur Actuelle

```
ApiException: 7 (NETWORK_ERROR)
```

Cette erreur signifie que Google Sign-In ne peut pas communiquer avec les serveurs Google car la configuration OAuth n'est pas complète.

---

## ✅ Corrections Appliquées

1. ✅ **google-services.json créé** (template à remplacer)
2. ✅ **Plugin Google Services appliqué** dans build.gradle.kts
3. ✅ **Dépendances ajoutées** (play-services-auth)

---

## 🔧 Configuration Obligatoire (Étape par Étape)

### **Étape 1: Générer le SHA-1 de votre application**

Ouvrez un terminal dans le dossier de votre projet et exécutez :

```bash
cd android
gradlew signingReport
```

**Ou avec keytool directement** :
```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Résultat attendu** :
```
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD
```

⚠️ **COPIEZ CE SHA-1**, vous en aurez besoin à l'étape suivante.

---

### **Étape 2: Configurer Google Cloud Console**

#### 2.1 Créer un projet Google Cloud

1. Allez sur https://console.cloud.google.com
2. Cliquez sur **"Sélectionner un projet"** → **"Nouveau projet"**
3. Nom du projet : **Vodou Host**
4. Cliquez sur **"Créer"**

#### 2.2 Activer l'API Google Sign-In

1. Dans le menu, allez dans **"API et services"** → **"Bibliothèque"**
2. Recherchez **"Google Sign-In API"** ou **"Google+ API"**
3. Cliquez sur **"Activer"**

#### 2.3 Créer un écran de consentement OAuth

1. Allez dans **"API et services"** → **"Écran de consentement OAuth"**
2. Sélectionnez **"Externe"** (pour tester avec n'importe quel compte Google)
3. Cliquez sur **"Créer"**
4. Remplissez les informations :
   - **Nom de l'application** : Vodou Host
   - **E-mail d'assistance utilisateur** : Votre email
   - **Domaine de l'application** : Laissez vide pour l'instant
   - **E-mail du développeur** : Votre email
5. Cliquez sur **"Enregistrer et continuer"**
6. **Champs d'application** : Laissez par défaut, cliquez sur **"Enregistrer et continuer"**
7. **Utilisateurs test** : Ajoutez votre email Google pour tester
8. Cliquez sur **"Enregistrer et continuer"**

#### 2.4 Créer un ID client OAuth 2.0 pour Android

1. Allez dans **"API et services"** → **"Identifiants"**
2. Cliquez sur **"+ CRÉER DES IDENTIFIANTS"** → **"ID client OAuth 2.0"**
3. Sélectionnez **"Application Android"**
4. Remplissez :
   - **Nom** : Vodou Host Android
   - **Nom du package** : `com.example.vodou`
   - **Empreinte du certificat SHA-1** : Collez le SHA-1 obtenu à l'étape 1
5. Cliquez sur **"Créer"**

✅ **Votre ID client Android est créé !**

#### 2.5 Créer un ID client OAuth 2.0 Web (pour Supabase)

1. Cliquez à nouveau sur **"+ CRÉER DES IDENTIFIANTS"** → **"ID client OAuth 2.0"**
2. Sélectionnez **"Application Web"**
3. Remplissez :
   - **Nom** : Vodou Host Web (Supabase)
   - **URI de redirection autorisés** : Ajoutez l'URL de callback Supabase
     ```
     https://vbfgfbqgtattrajdmeit.supabase.co/auth/v1/callback
     ```
4. Cliquez sur **"Créer"**

✅ **Votre ID client Web est créé !**

⚠️ **IMPORTANT** : Copiez le **Client ID Web**, vous en aurez besoin pour Supabase.

---

### **Étape 3: Télécharger google-services.json**

1. Dans Google Cloud Console, allez dans **"Paramètres du projet"** (icône engrenage en haut à gauche)
2. Descendez jusqu'à **"Vos applications"**
3. Cliquez sur l'application Android (com.example.vodou)
4. Cliquez sur **"Télécharger google-services.json"**
5. **REMPLACEZ** le fichier `android/app/google-services.json` par celui téléchargé

⚠️ **CRITIQUE** : Le fichier `google-services.json` actuel est un template. Vous DEVEZ le remplacer par le vrai fichier téléchargé depuis Google Cloud Console.

---

### **Étape 4: Configurer Supabase**

#### 4.1 Ajouter Google comme provider OAuth

1. Allez sur https://supabase.com/dashboard
2. Sélectionnez votre projet **Vodou**
3. Allez dans **"Authentication"** → **"Providers"**
4. Activez **"Google"**
5. Remplissez :
   - **Client ID** : Collez le Client ID Web (étape 2.5)
   - **Client Secret** : Copiez le Secret depuis Google Cloud Console (visible dans les identifiants Web)
6. Cliquez sur **"Save"**

#### 4.2 Mettre à jour supabase_config.dart

Ouvrez `lib/core/config/supabase_config.dart` et mettez à jour :

```dart
// OAuth Configuration
static const String googleClientId = 'VOTRE_CLIENT_ID_WEB.apps.googleusercontent.com';
```

⚠️ **Utilisez le Client ID WEB**, pas le Client ID Android !

---

### **Étape 5: Nettoyer et Reconstruire**

```bash
flutter clean
flutter pub get
cd android
gradlew clean
cd ..
flutter run
```

---

## 🧪 Tester Google Sign-In

1. Lancez l'application
2. Cliquez sur **"Se connecter avec Google"**
3. Sélectionnez votre compte Google
4. Autorisez l'application

**Logs attendus** :
```
✅ AuthRepository: Tokens Google récupérés
✅ AuthRepository: Authentification Supabase réussie
✅ AuthRepository: Profil utilisateur prêt
```

---

## 🚨 Résolution des Erreurs

### Erreur: `ApiException: 7` (NETWORK_ERROR)

**Causes** :
- ❌ `google-services.json` manquant ou incorrect
- ❌ SHA-1 non configuré dans Google Cloud Console
- ❌ ID client Android non créé

**Solutions** :
1. Vérifiez que `android/app/google-services.json` existe et contient vos vraies clés
2. Vérifiez que le SHA-1 est bien ajouté dans Google Cloud Console
3. Vérifiez que le package name est `com.example.vodou` partout
4. Relancez `flutter clean && flutter run`

### Erreur: `ApiException: 10` (DEVELOPER_ERROR)

**Causes** :
- ❌ SHA-1 ne correspond pas
- ❌ Package name incorrect
- ❌ `google-services.json` d'un autre projet

**Solutions** :
1. Régénérez le SHA-1 avec `gradlew signingReport`
2. Vérifiez que le package name dans `build.gradle.kts` est `com.example.vodou`
3. Téléchargez à nouveau `google-services.json` depuis Google Cloud Console

### Erreur: `PlatformException(sign_in_canceled)`

**Cause** :
- L'utilisateur a annulé la connexion

**Solution** :
- Normal, aucune action requise

### Erreur: `ApiException: 12501` (SIGN_IN_CANCELLED)

**Cause** :
- L'utilisateur a fermé la fenêtre de connexion

**Solution** :
- Normal, aucune action requise

---

## 📋 Checklist Finale

Avant de tester, vérifiez que :

- [ ] SHA-1 généré et copié
- [ ] Projet Google Cloud créé
- [ ] API Google Sign-In activée
- [ ] Écran de consentement OAuth configuré
- [ ] ID client Android créé avec le bon SHA-1 et package name
- [ ] ID client Web créé pour Supabase
- [ ] `google-services.json` téléchargé et placé dans `android/app/`
- [ ] Client ID Web ajouté dans Supabase Dashboard
- [ ] Client ID Web mis à jour dans `supabase_config.dart`
- [ ] `flutter clean` et rebuild effectués

---

## 🎯 Commandes Utiles

```bash
# Générer le SHA-1
cd android && gradlew signingReport

# Voir le contenu de google-services.json
cat android/app/google-services.json

# Nettoyer et reconstruire
flutter clean && flutter pub get && flutter run

# Logs détaillés
flutter run --verbose
```

---

## 📞 Vérifications Importantes

### Vérifier que google-services.json est valide

Ouvrez `android/app/google-services.json` et vérifiez :

1. **project_id** : Ne doit PAS être "your-project-id"
2. **client_id** : Doit se terminer par `.apps.googleusercontent.com`
3. **package_name** : Doit être `com.example.vodou`
4. **certificate_hash** : Doit contenir votre SHA-1 réel

Si vous voyez des valeurs comme "YOUR_PROJECT_NUMBER" ou "YOUR_CLIENT_ID", c'est que vous utilisez encore le template. Vous DEVEZ télécharger le vrai fichier depuis Google Cloud Console.

---

## ✅ Une fois configuré correctement

Google Sign-In fonctionnera et vous verrez :

1. La fenêtre de sélection de compte Google s'ouvre
2. Vous sélectionnez votre compte
3. Vous autorisez l'application
4. Vous êtes connecté et redirigé vers l'application
5. Votre profil utilisateur est créé dans Supabase

---

**🎉 Bon courage ! Une fois ces étapes complétées, Google Sign-In fonctionnera parfaitement.**
