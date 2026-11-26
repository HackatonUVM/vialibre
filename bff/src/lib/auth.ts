import { NextRequest } from 'next/server';
import { supabasePublic } from './supabase';

export interface AuthUser {
  id: string;
  isAnonymous: boolean;
}

/**
 * Valida el encabezado Authorization: Bearer <token> emitido por Supabase Auth
 * (compatible con sesiones anónimas mediante supabase.auth.signInAnonymously())
 */
export async function authenticateRequest(req: NextRequest): Promise<{ user: AuthUser | null; error?: string }> {
  const authHeader = req.headers.get('authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    // Si no hay token en modo demo o desarrollo, permitimos un fallback anónimo
    if (process.env.NODE_ENV === 'development' || !process.env.SUPABASE_URL) {
      return {
        user: { id: '00000000-0000-0000-0000-000000000000', isAnonymous: true },
      };
    }
    return {
      user: null,
      error: 'Encabezado de autorización ausente o inválido (Bearer token requerido)',
    };
  }

  const token = authHeader.split(' ')[1];
  try {
    const { data, error } = await supabasePublic.auth.getUser(token);
    if (error || !data.user) {
      return { user: null, error: error?.message || 'Token de sesión inválido o expirado' };
    }
    return {
      user: {
        id: data.user.id,
        isAnonymous: data.user.is_anonymous ?? true,
      },
    };
  } catch (err: any) {
    return { user: null, error: err.message || 'Error validando sesión' };
  }
}
