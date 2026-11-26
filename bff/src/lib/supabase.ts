import { createClient } from '@supabase/supabase-js';
import { getEnv } from './env';

const env = getEnv();

// Cliente público / anónimo para verificar tokens de usuario
export const supabasePublic = createClient(
  env.SUPABASE_URL,
  env.SUPABASE_ANON_KEY
);

// Cliente de backend con privilegios para invocar RPCs protegidas y firmas de storage
export const supabaseAdmin = createClient(
  env.SUPABASE_URL,
  env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);
