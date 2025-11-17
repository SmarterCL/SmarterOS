# Configuración Clerk + Vercel para fulldaygo.smarterbot.cl

## 1. Obtener Clerk Keys

### Paso 1: Ir a Clerk Dashboard
```
https://dashboard.clerk.com/
```

### Paso 2: Crear/Seleccionar Aplicación
- Nombre: `fulldaygo` o `SmarterOS Production`
- Tipo: Production

### Paso 3: Configurar Google OAuth
- Ir a: **User & Authentication** > **Social Connections**
- Activar: **Google**
- Scopes: `openid`, `profile`, `email`

### Paso 4: Obtener API Keys
- Ir a: **API Keys**
- Copiar:
  - `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` (empieza con `pk_live_` o `pk_test_`)
  - `CLERK_SECRET_KEY` (empieza con `sk_live_` o `sk_test_`)

### Paso 5: Configurar URLs
En **Paths**:
```
Sign-in URL: /sign-in
Sign-up URL: /sign-up
After sign-in URL: /
After sign-up URL: /
```

## 2. Configurar Variables de Entorno en Vercel

### Opción A: Via Dashboard
1. Ir a: https://vercel.com/smarterbotcl/v0-argentina-mobile-app/settings/environment-variables
2. Agregar:

```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_xxx
CLERK_SECRET_KEY=sk_live_xxx
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/
```

3. Aplicar a: **Production**, **Preview**, **Development**

### Opción B: Via CLI
```bash
cd /Users/mac/dev/2025/front/fulldaygo.smarterbot.cl

# Instalar Vercel CLI si no está
pnpm add -g vercel

# Link project
vercel link

# Agregar env vars
vercel env add NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
vercel env add CLERK_SECRET_KEY
vercel env add NEXT_PUBLIC_CLERK_SIGN_IN_URL
vercel env add NEXT_PUBLIC_CLERK_SIGN_UP_URL
vercel env add NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL
vercel env add NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL
```

## 3. Crear .env.local para desarrollo

```bash
cd /Users/mac/dev/2025/front/fulldaygo.smarterbot.cl

cat > .env.local << 'EOF'
# Clerk Keys (obtener de https://dashboard.clerk.com/)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxx
CLERK_SECRET_KEY=sk_test_xxx

# Clerk URLs
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/

# Supabase (para sync post-auth)
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=xxx
EOF
```

## 4. Agregar a .gitignore

```bash
echo ".env.local" >> .gitignore
```

## 5. Guardar en Vault (opcional, para CI/CD)

```bash
# Desde terminal con Vault configurado
vault kv put smarteros/mcp/clerk \
  clerk_publishable_key=pk_live_xxx \
  clerk_secret_key=sk_live_xxx \
  clerk_jwt_key=xxx \
  clerk_webhook_secret=xxx
```

## 6. Redeploy Vercel

```bash
# Trigger nuevo deploy después de configurar env vars
vercel --prod

# O via GitHub push (trigger automático)
git commit --allow-empty -m "trigger: redeploy con Clerk env vars"
git push origin main
```

## 7. Verificar Deploy

1. Check logs: https://vercel.com/smarterbotcl/v0-argentina-mobile-app/deployments
2. Probar URL: https://fulldaygo.smarterbot.cl
3. Intentar login con Google

## Notas

- **Development**: Usar `pk_test_` y `sk_test_` en local
- **Production**: Usar `pk_live_` y `sk_live_` en Vercel
- **Webhook**: Configurar en Clerk si necesitas eventos (user.created, session.created)
- **Demo**: Crear aplicación separada en Clerk para demo.smarterbot.cl

## Próximos pasos

1. [ ] Obtener keys de Clerk dashboard
2. [ ] Configurar env vars en Vercel
3. [ ] Crear .env.local para desarrollo
4. [ ] Implementar middleware.ts con authMiddleware
5. [ ] Crear páginas sign-in/sign-up
6. [ ] Implementar sync a Supabase (webhook o middleware)
