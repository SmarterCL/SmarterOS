# Instalación: Limpieza Automática de Precios

Script para cumplimiento de "leyes de seguridad y búsqueda" (eliminación de referencias a precios).

## 📋 Configuración

### 1. Hacer el script ejecutable
```bash
chmod +x /Users/mac/dev/2025/scripts/remove-pricing-mentions.sh
```

### 2. Crear directorio de logs
```bash
mkdir -p /Users/mac/dev/2025/.logs/backups
```

### 3. Instalar cron job
```bash
crontab /Users/mac/dev/2025/scripts/pricing-cleanup.cron
```

### 4. Verificar instalación
```bash
crontab -l
```

**Salida esperada:**
```
0 3 * * 0 /bin/bash /Users/mac/dev/2025/scripts/remove-pricing-mentions.sh >> /Users/mac/dev/2025/.logs/cron-pricing-cleanup.log 2>&1
0 4 1 * * gzip -c /Users/mac/dev/2025/.logs/cron-pricing-cleanup.log > /Users/mac/dev/2025/.logs/backups/cron-pricing-cleanup-$(date +\%Y\%m).log.gz && echo "" > /Users/mac/dev/2025/.logs/cron-pricing-cleanup.log
0 8 * * 1 [ -f /Users/mac/dev/2025/scripts/remove-pricing-mentions.sh ] && echo "✅ Script exists" || echo "❌ Script missing" | mail -s "Pricing Cleanup Health Check" smarterbotcl@gmail.com
```

---

## ⏰ Frecuencia

- **Limpieza:** Domingos a las 3:00 AM (Chile UTC-3)
- **Backup de logs:** Primer día de cada mes a las 4:00 AM
- **Health check:** Lunes a las 8:00 AM

**Prioridad:** BAJA

---

## 🔍 Qué hace el script

1. **Busca menciones de precios** en:
   - `*.md` (Markdown)
   - `*.yml` / `*.yaml` (YAML)
   - `*.ts` / `*.tsx` (TypeScript)
   - `*.js` / `*.jsx` (JavaScript)
   - `*.json` (JSON)

2. **Filtra false positives:**
   - Template strings: `className=${...}`
   - GitHub Actions: `${{ secrets.TOKEN }}`
   - Vault errors: `${resp.status}`
   - `fulldaygo.smarterbot.cl` (e-commerce, precios intencionales)

3. **Limpia archivos:**
   - `smarteros-specs/services/botpress-agent.yml` (elimina cost estimation)
   - `smarteros-specs/BACKLOG-Q1-2025-BOTPRESS.md` (anonimiza montos)

4. **Commitea y pushea** (solo si estamos en `main` o `master`)

5. **Genera log** en `/Users/mac/dev/2025/.logs/pricing-cleanup-YYYYMMDD-HHMMSS.log`

---

## 📊 Verificar ejecución

### Ver log del último run
```bash
tail -f /Users/mac/dev/2025/.logs/cron-pricing-cleanup.log
```

### Ver historial de runs
```bash
ls -lh /Users/mac/dev/2025/.logs/pricing-cleanup-*.log
```

### Ver backups mensuales
```bash
ls -lh /Users/mac/dev/2025/.logs/backups/
```

---

## 🧪 Probar manualmente

```bash
# Ejecutar el script ahora (sin esperar al domingo)
/bin/bash /Users/mac/dev/2025/scripts/remove-pricing-mentions.sh

# Ver output
cat /Users/mac/dev/2025/.logs/pricing-cleanup-*.log | tail -50
```

---

## ❌ Desinstalar

```bash
# Listar cron jobs actuales
crontab -l

# Editar manualmente
crontab -e

# O eliminar todo
crontab -r
```

---

## 🔧 Troubleshooting

### Error: "Permission denied"
```bash
chmod +x /Users/mac/dev/2025/scripts/remove-pricing-mentions.sh
```

### Error: "No such file or directory"
```bash
# Verificar que el script existe
ls -lh /Users/mac/dev/2025/scripts/remove-pricing-mentions.sh

# Verificar ruta en crontab
crontab -l
```

### Script no se ejecuta
```bash
# Verificar que cron está corriendo (macOS)
sudo launchctl list | grep cron

# Ver logs del sistema
tail -f /var/log/system.log | grep cron
```

### Notificaciones por email no llegan
```bash
# Configurar mail (macOS usa por defecto)
# Opción 1: Configurar Postfix
sudo vim /etc/postfix/main.cf

# Opción 2: Usar SMTP externo (Gmail)
# Ver: https://support.apple.com/en-us/102525
```

---

## 📞 Soporte

- **Email:** smarterbotcl@gmail.com
- **GitHub Issues:** https://github.com/SmarterCL/smarteros-specs/issues

---

_Última actualización: 2025-11-17_
