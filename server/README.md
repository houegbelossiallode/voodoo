Handler de callback Supabase

Fichiers ajoutés :
- `server/src/routes/supabaseCallback.js` : route Express gérant `/hoost/auth/supabase/callback`
- `server/.env.example` : exemple de variables d'environnement

Instructions d'intégration :
1) Installer les dépendances dans votre projet backend :

```bash
npm install express @supabase/supabase-js
```

2) Monter la route dans votre application Express (exemple) :

```js
import express from 'express';
import supabaseCallback from './routes/supabaseCallback.js';

const app = express();
app.use(supabaseCallback);

app.listen(process.env.PORT || 3000, () => console.log('Serveur démarré'));
```

3) Définir les variables d'environnement sur Render (ou votre hébergeur) :
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE` (clé ADMIN — à garder secrète côté serveur)
- `FRONTEND_CONFIRM_SUCCESS` (URL vers la page de connexion/front après confirmation)
- `FRONTEND_SUCCESS_WITH_TOKEN` (URL front pour réception du token si présent)

4) Vérifier que l'URL de redirection utilisée dans `emailRedirectTo` (lors du `signUp`) correspond bien à la route ci‑dessus et figure dans la liste `Redirect URLs` de votre projet Supabase.

5) Tests recommandés :
- Inscrire un compte test, ouvrir l'email de confirmation et cliquer sur le lien.
- Si le lien contient un token, la route redirigera le front avec `access_token`.
- Sinon, la route vérifiera côté serveur (via la clé `service_role`) que l'utilisateur est bien confirmé et redirigera vers la page de connexion.

Notes de sécurité :
- Ne jamais exposer la clé `SUPABASE_SERVICE_ROLE` dans du code client.
- Garder la clé dans les variables d'environnement du serveur uniquement.

Remarques :
- Le trigger SQL fourni dans `supabase_triggers.sql` crée automatiquement le profil `public.users` lors de la confirmation; la route de callback n'a donc pas besoin de créer le profil.

Besoin d'aide pour déployer ce handler sur Render ou pour ajouter une page frontend "E‑mail confirmé" ?
