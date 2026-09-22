import express from 'express';
import { createClient } from '@supabase/supabase-js';

const router = express.Router();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE = process.env.SUPABASE_SERVICE_ROLE; // server only
const FRONTEND_CONFIRM_SUCCESS = process.env.FRONTEND_CONFIRM_SUCCESS || 'https://app.vodoohost.com/login?confirmed=1';
const FRONTEND_SUCCESS_WITH_TOKEN = process.env.FRONTEND_SUCCESS_WITH_TOKEN || 'https://app.vodoohost.com/auth/success';

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE) {
  console.warn('Supabase callback route: SUPABASE_URL or SUPABASE_SERVICE_ROLE missing in env');
}

const supabaseAdmin = createClient(SUPABASE_URL || '', SUPABASE_SERVICE_ROLE || '', {
  auth: { persistSession: false },
});

// Route: GET /hoost/auth/supabase/callback
router.get('/hoost/auth/supabase/callback', async (req, res) => {
  try {
    // Supabase may return token in query params; fragment (#) is NOT sent to server.
    const accessToken = req.query.access_token || req.query.token || req.query.refresh_token || req.query['access-token'];
    const email = req.query.email || req.query.user_email || null;

    // 1) If token present, redirect frontend to consume it (auto-login flow)
    if (accessToken) {
      return res.redirect(`${FRONTEND_SUCCESS_WITH_TOKEN}?access_token=${encodeURIComponent(accessToken)}`);
    }

    // 2) No token readable by server: if no email, show friendly page
    if (!email) {
      return res.send(`
        <html><body style="font-family:Arial,Helvetica,sans-serif;padding:24px">
          <h2>Email confirmé</h2>
          <p>Votre adresse a été confirmée. Fermez cette fenêtre puis connectez-vous dans l'application.</p>
          <p><a href="${FRONTEND_CONFIRM_SUCCESS}">Aller à la connexion</a></p>
        </body></html>
      `);
    }

    // 3) Verify confirmation server-side using Supabase Admin (service role)
    const { data, error } = await supabaseAdmin
      .from('auth.users')
      .select('confirmed_at, email_confirmed_at')
      .eq('email', email)
      .limit(1)
      .single();

    if (error) {
      console.error('Supabase admin error:', error);
      return res.status(500).send('Erreur interne, veuillez réessayer plus tard.');
    }

    const confirmed = (data && (data.confirmed_at || data.email_confirmed_at)) != null;
    if (!confirmed) {
      return res.send(`
        <html><body style="font-family:Arial,Helvetica,sans-serif;padding:24px">
          <h2>Confirmation en attente</h2>
          <p>Aucune confirmation trouvée pour ${email}. Attendez quelques instants puis réessayez.</p>
          <p><a href="${FRONTEND_CONFIRM_SUCCESS}">Aller à la connexion</a></p>
        </body></html>
      `);
    }

    // OK: user confirmed. Trigger SQL should have created public.users.
    return res.redirect(FRONTEND_CONFIRM_SUCCESS);
  } catch (err) {
    console.error('Callback error:', err);
    return res.status(500).send('Erreur serveur.');
  }
});

export default router;
