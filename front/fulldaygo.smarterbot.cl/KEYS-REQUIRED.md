# 🔑 Configuración de Keys Pendiente

## Estado Actual
- ✅ Código integrado con ClerkProvider
- ✅ Dependencias instaladas
- ✅ Layout configurado con es-CL
- ⚠️ **Keys pendientes** (usando placeholders)

## Obtener Clerk Keys

### Opción 1: Dashboard Web (Recomendado)
1. Ir a: https://dashboard.clerk.com/
2. Crear cuenta / Iniciar sesión
3. Crear nueva aplicación:
   - Nombre: `fulldaygo` o `SmarterOS`
   - Tipo: **Production** (o Test para desarrollo)
4. Activar Google OAuth:
   - Sidebar: **User & Authentication** → **Social Connections**
   - Toggle: **Google** → ON
5. Obtener keys:
   - Sidebar: **API Keys**
   - Copiar:
     - `Publishable key` → empieza con `pk_test_` o `pk_live_`
     - `Secret key` → click "Show" → empieza con `sk_test_` o `sk_live_`

### Opción 2: Clerk CLI
```bash
# Instalar CLI
npm install -g @clerk/cli

# Login
clerk login

# Ver apps
clerk apps list

# Obtener keys de app específica
clerk keys list --app-id <app-id>
```

## Reemplazar Keys

### 1. Archivo Local (.env.local)
```bash
cd /Users/mac/dev/2025/front/fulldaygo.smarterbot.cl

# Editar .env.local y reemplazar:
# pk_test_placeholder_replace_me → tu publishable key real
# sk_test_placeholder_replace_me → tu secret key real
```

### 2. Vercel Environment Variables
```bash
# Via CLI
vercel env add NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY production
# Pegar: pk_live_xxx

vercel env add CLERK_SECRET_KEY production
# Pegar: sk_live_xxx

# O via dashboard:
# https://vercel.com/smarterbotcl/v0-argentina-mobile-app/settings/environment-variables
```

### 3. Vault (Opcional, para CI/CD)
```bash
vault kv put smarteros/mcp/clerk \
  clerk_publishable_key=pk_live_xxx \
  clerk_secret_key=sk_live_xxx \
  clerk_jwt_key=xxx \
  clerk_webhook_secret=xxx
```

## Verificar Configuración

### Local
```bash
cd /Users/mac/dev/2025/front/fulldaygo.smarterbot.cl
pnpm dev
# Abrir http://localhost:3000
# Verificar que no hay errores de Clerk en consola
```

### Production
```bash
# Después de configurar env vars en Vercel
vercel --prod
# O push a GitHub para trigger automático
```

## Supabase Keys (También Pendientes)

Obtener de: https://supabase.com/dashboard/project/_/settings/api

```
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJxxx (service_role key, NO anon key)
```

## Próximos Pasos Post-Keys

Una vez configuradas las keys:

1. [ ] Test login local con Google
2. [ ] Implementar middleware.ts para auth
3. [ ] Crear páginas /sign-in y /sign-up
4. [ ] Implementar sync Supabase (users/tenants)
5. [ ] Configurar webhook Clerk → Supabase
6. [ ] Implementar Shopify gate
7. [ ] Deploy a producción

## Contacto para Keys

Si necesitas ayuda para obtener las keys:
- Dashboard Clerk: https://dashboard.clerk.com/
- Docs Clerk: https://clerk.com/docs/quickstarts/nextjs
- Support: https://clerk.com/support
