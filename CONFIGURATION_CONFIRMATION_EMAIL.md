# Configuration Confirmation Email - Supabase

## ✅ Implémentation terminée

L'application est maintenant configurée pour gérer la confirmation par email avec Supabase en utilisant l'approche simplifiée (navigateur web). Voici les étapes pour activer et configurer cette fonctionnalité.

---

## ⚠️ Mode Développement - Désactiver la confirmation email

Si vous rencontrez l'erreur "nombreux essais détectés" lors des tests, vous pouvez désactiver temporairement la confirmation email :

1. Ouvrez `lib/core/config/supabase_config.dart`
2. Changez la ligne :
   ```dart
   static const bool disableEmailConfirmation = false;
   ```
   en :
   ```dart
   static const bool disableEmailConfirmation = true;
   ```

**Effet** : Le profil sera créé immédiatement après inscription, sans confirmation email.

**Attention** : Remettez à `false` avant la mise en production !

---

## 🔧 Étape 1: Activer la confirmation email dans Supabase Dashboard

1. Connectez-vous à votre dashboard Supabase: https://app.supabase.com
2. Sélectionnez votre projet: `vbfgfbqgtattrajdmeit`
3. Allez dans **Authentication** > **Providers** > **Email**
4. Activez l'option **Confirm email**
5. Cliquez sur **Save**

**Note** : L'application utilise l'URL de redirection par défaut de Supabase (navigateur web).

---

## 📧 Étape 3: Personnaliser l'email de confirmation (Optionnel)

1. Dans Supabase Dashboard, allez dans **Authentication** > **Email Templates**
2. Sélectionnez **Confirm signup**
3. Personnalisez le template selon vos besoins
4. Assurez-vous que le lien contient `{{ .ConfirmationURL }}`

---

## 🧪 Étape 4: Tester le flux

### Scénario 1: Nouvelle inscription
1. Lancez l'application
2. Allez sur "S'inscrire"
3. Remplissez le formulaire avec un email valide
4. Soumettez le formulaire
5. **Résultat attendu**: Redirection vers la page de confirmation email

### Scénario 2: Confirmation email
1. Vérifiez votre boîte mail (y compris spam)
2. Cliquez sur le lien de confirmation
3. **Résultat attendu**: L'application s'ouvre et vous connecte automatiquement

### Scénario 3: Première connexion après confirmation
1. Après confirmation, connectez-vous avec vos identifiants
2. **Résultat attendu**: 
   - Le profil est créé automatiquement depuis les métadonnées
   - Redirection selon votre rôle (Visiteur → Questionnaire, Hôte → Accueil)

---

## 📊 Flux de données

### Inscription
```
User → Formulaire → signUpWithEmail()
  → Stocke données dans user_metadata
  → Envoie email confirmation Supabase
  → Redirection vers EmailConfirmationPage
```

### Confirmation Email
```
User → Clique lien email → Deep Link
  → Supabase confirme l'email
  → Session créée
  → Ouverture app avec session active
```

### Première Connexion
```
User → signInWithEmail()
  → Vérifie si profil existe
  → Si non: Crée profil depuis user_metadata
  → Redirection selon rôle
```

---

## 🐛 Dépannage

### Problème: "Nombreux essais détectés" lors de l'inscription
**Cause**: Supabase a un rate limiting qui bloque les tentatives répétées d'inscription, même avec des emails différents.

**Solutions**:
1. **Augmenter les limites dans Supabase Dashboard** (recommandé pour permettre les tests):
   - Allez dans **Authentication** > **Rate Limiting**
   - Augmentez la limite "Email signups" (par exemple: 10 par minute ou plus)
   - Cliquez sur **Save**
   - Cela permet plus d'inscriptions sans bloquer les utilisateurs

2. **Désactiver temporairement la confirmation email** (uniquement pour les tests rapides):
   - Ouvrez `lib/core/config/supabase_config.dart`
   - Changez `disableEmailConfirmation = true`
   - Recompilez l'APK
   - **Attention**: Remettez à `false` avant la production

3. **Attendre entre les essais**:
   - Attendez 5-10 minutes entre chaque tentative
   - Le rate limiting se réinitialise après un certain temps

### Problème: Email non reçu
**Solutions**:
- Vérifiez le dossier spam/indésirable
- Vérifiez que l'option "Confirm email" est activée dans Supabase
- Vérifiez que l'URL de redirection est correcte

### Problème: Deep link ne fonctionne pas
**Solutions**:
- Vérifiez que `AndroidManifest.xml` contient l'intent-filter
- Vérifiez que le schéma `vodoohost://` est configuré dans Supabase
- Testez avec `adb shell am start -W -a android.intent.action.VIEW -d "vodoohost://test"`

### Problème: Profil non créé après confirmation
**Solutions**:
- Vérifiez les logs Flutter pour les erreurs
- Vérifiez que les métadonnées contiennent toutes les données requises
- Vérifiez que la table `users` existe avec les bonnes colonnes

### Problème: Erreur "Profil non trouvé" lors de la connexion
**Solutions**:
- C'est normal si l'utilisateur n'a pas encore confirmé son email
- Après confirmation, le profil sera créé automatiquement
- Vérifiez que `_createProfileFromMetadata` fonctionne correctement

---

## 🔒 Sécurité

### RLS Policies
Les politiques RLS existantes dans `supabase_rls_all_tables.sql` sont compatibles avec ce flux.

### Données sensibles
- Les mots de passe ne sont jamais stockés dans user_metadata
- Seules les données du profil (nom, prénom, etc.) sont stockées
- Les métadonnées sont accessibles uniquement par l'utilisateur connecté

---

## 📝 Résumé des modifications

### Fichiers modifiés
1. `lib/features/auth/data/repositories/auth_repository.dart`
   - `signUpWithEmail()`: Stocke les données dans user_metadata
   - `signInWithEmail()`: Crée le profil si manquant
   - `_createProfileFromMetadata()`: Nouvelle méthode

2. `lib/features/auth/presentation/providers/auth_provider.dart`
   - `signUpWithEmail()`: Retourne void, état reste null

3. `lib/features/auth/presentation/pages/signup_page.dart`
   - Redirection vers `EmailConfirmationPage` après inscription

4. `lib/core/router/app_router.dart`
   - Ajout de la route `/email-confirmation`
   - Import de `EmailConfirmationPage`

5. `android/app/src/main/AndroidManifest.xml`
   - Ajout de l'intent-filter pour deep linking

### Fichiers créés
1. `lib/features/auth/presentation/pages/email_confirmation_page.dart`
   - Page de confirmation email avec UX

---

## ✅ Checklist de configuration

- [ ] Activer "Confirm email" dans Supabase Dashboard
- [ ] Configurer l'URL de redirection: `vodoohost://auth/callback`
- [ ] Ajouter l'URL dans Redirect URLs Supabase
- [ ] Vérifier l'intent-filter dans AndroidManifest.xml
- [ ] Tester l'inscription avec un email réel
- [ ] Tester la confirmation email
- [ ] Tester la création automatique du profil
- [ ] Vérifier les logs pour les erreurs

---

## 🚀 Prochaines étapes

1. **Tester sur device réel**: Le deep linking fonctionne mieux sur un device réel que sur émulateur
2. **Personnaliser l'email**: Adapter le template email à votre branding
3. **Ajouter iOS**: Configurer le deep linking pour iOS si nécessaire
4. **Monitoring**: Surveiller les taux de confirmation email

---

**Statut**: ✅ Implémentation terminée, configuration Supabase requise
