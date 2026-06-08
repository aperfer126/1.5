## [AMPLIACIÓN - Práctica 1.5] Certificados Válidos con Let's Encrypt y Certbot

### ¿Qué es Let's Encrypt?

**Let's Encrypt** es una autoridad certificadora gratuita, automatizada y abierta que proporciona certificados SSL/TLS válidos reconocidos por todos los navegadores. A diferencia de los certificados autofirmados, los de Let's Encrypt:

- ✅ Son reconocidos por navegadores (sin advertencias)
- ✅ Son completamente gratuitos
- ✅ Se renuevan automáticamente cada 90 días
- ✅ Ideales para producción
- ✅ Mejoran el SEO de tu sitio

### ¿Qué es Certbot?

**Certbot** es el cliente oficial de Let's Encrypt. Automatiza completamente la solicitud, instalación y renovación de certificados. Se integra con Apache para:

- Generar certificados válidos automáticamente
- Configurar Apache para usar HTTPS
- Renovar certificados antes de que expiren
- Crear redirecciones automáticas de HTTP a HTTPS

### Nuevo Script: setup_letsencrypt_certificate.sh

Este script automatiza todo el proceso de instalación de Let's Encrypt con Certbot.

#### Requisitos previos para Let's Encrypt

Antes de ejecutar el script, asegúrate de tener:

1. **Un dominio registrado** que apunte a tu servidor
   - Let's Encrypt valida la propiedad del dominio
   - No funciona solo con IPs

2. **Puerto 80 accesible** desde internet
   - Certbot usa validación HTTP (puerto 80)
   - Firewall/Security Groups deben permitir acceso

3. **DNS correctamente configurado**
   ```bash
   nslookup tu-dominio.com
   # Debe resolver a la IP de tu servidor
   ```

#### Comando de ejecución:

```bash
cd scripts
sudo bash setup_letsencrypt_certificate.sh
```

#### ¿Qué hace este script paso a paso?

**1. Instalar y actualizar snap**
```bash
snap install core
snap refresh core
```
- Snap es un gestor de paquetes de Ubuntu
- Certbot se instala como snap para tener siempre la última versión

**2. Eliminar certbot anterior (si existe)**
```bash
apt remove certbot -y
```
- Evita conflictos con versiones antiguas de apt

**3. Instalar Certbot desde snap (versión clásica)**
```bash
snap install --classic certbot
```
- `--classic` es necesario para que certbot tenga acceso a permisos del sistema
- Instala la última versión estable

**4. Crear enlace simbólico**
```bash
ln -fs /snap/bin/certbot /usr/bin/certbot
```
- Permite ejecutar `certbot` directamente sin la ruta completa

**5. Solicitar e instalar el certificado**
```bash
certbot --apache -m "$LE_EMAIL" --agree-tos --no-eff-email -d "$LE_DOMAIN" --non-interactive
```

**Parámetros explicados:**
- `--apache`: Integración directa con Apache (configura automáticamente)
- `-m "$LE_EMAIL"`: Email para notificaciones de renovación
- `--agree-tos`: Acepta los términos de servicio automáticamente
- `--no-eff-email`: No comparte el email con Electronic Frontier Foundation
- `-d "$LE_DOMAIN"`: Dominio para el que generar el certificado
- `--non-interactive`: Ejecución sin interacción (automatizada)

**Archivos generados por Certbot:**
- `/etc/letsencrypt/live/tu-dominio.com/fullchain.pem` - Certificado público
- `/etc/letsencrypt/live/tu-dominio.com/privkey.pem` - Clave privada
- Configuración automática en Apache
- Renovación automática configurada en cron

---

### Variables de Entorno para Let's Encrypt

Añade estas variables al archivo `.env` en la carpeta `scripts/`:

```bash
# Variables para Let's Encrypt / Certbot
LE_EMAIL="tu-email@ejemplo.com"              # Email para notificaciones (ej. renovación)
LE_DOMAIN="tu-dominio.com"                  # Dominio VÁLIDO y registrado
```

**Importante:**
- `LE_DOMAIN` debe ser un dominio real registrado que apunte a tu servidor
- `LE_EMAIL` recibirá notificaciones sobre renovaciones (60 días antes de expirar)
- Let's Encrypt validará que controlas el dominio

---

### Proceso de Validación de Let's Encrypt

Certbot realiza validación HTTP:

1. **Desafío**: Let's Encrypt envía un código aleatorio
2. **Respuesta**: Certbot lo coloca en `http://tu-dominio.com/.well-known/acme-challenge/`
3. **Verificación**: Let's Encrypt accede a esa URL para validar
4. **Éxito**: Si la validación pasa, se emite el certificado

Por esto es crucial que:
- El dominio resuelva a tu servidor
- Puerto 80 esté accesible desde internet
- Apache esté ejecutándose durante la validación

---

### Diferencias: Autofirmado vs Let's Encrypt

| Aspecto | Autofirmado | Let's Encrypt |
|--------|-------------|---------------|
| **Costo** | Gratuito | Gratuito |
| **Validez** | No confíable | Confiable |
| **Navegador** | Advertencia roja | Certificado válido ✓ |
| **Requiere dominio** | No | Sí |
| **Renovación** | Manual | Automática |
| **Vida útil** | Configurable | 90 días |
| **Uso recomendado** | Desarrollo/Testing | Producción |

---

### Verificar que Let's Encrypt está funcionando

Después de ejecutar el script:

1. **Verificar certificado en el navegador**
   ```bash
   https://tu-dominio.com
   ```
   - No debe mostrar advertencia de seguridad
   - El candado debe verse en verde
   - Haz clic en el candado para ver detalles

2. **Ver información del certificado en terminal**
   ```bash
   sudo certbot certificates
   # Muestra estado y fecha de expiración
   ```

3. **Verificar con OpenSSL**
   ```bash
   openssl s_client -connect tu-dominio.com:443 -servername tu-dominio.com
   # Presiona Ctrl+C para salir
   ```

4. **Validar certificado con herramientas online**
   - [SSL Labs](https://www.ssllabs.com/ssltest/)
   - [Qualys SSL Certificate Checker](https://www.ssllabs.com/ssltest/analyze.html)
   - Ingresa tu dominio para análisis completo

---

### Renovación Automática de Certificados

Certbot configura automáticamente la renovación cada 90 días:

```bash
# Ver trabajos cron programados
sudo systemctl status snap.certbot.renew.service

# Renovación manual (si es necesario)
sudo certbot renew

# Renovar con logs detallados
sudo certbot renew --dry-run
# (--dry-run simula sin hacer cambios reales)
```

Certbot envía recordatorios por email 60 y 30 días antes de expirar.

---

### Redirigir HTTP a HTTPS (automático con Let's Encrypt)

Certbot configura automáticamente la redirección HTTP → HTTPS. Pero puedes verificar:

```bash
# Probar redirección
curl -I http://tu-dominio.com
# Debe responder con 301 o 302 hacia HTTPS
```

Si quieres configurar manualmente:

```apache
<VirtualHost *:80>
    ServerName tu-dominio.com
    
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>
```

---

### Problemas comunes con Let's Encrypt

**Error: "Unable to locate the Server instance or certificates"
- El dominio no resuelve a tu servidor
- Verifica DNS: `nslookup tu-dominio.com`
- Espera 15-30 minutos si acabas de configurar DNS

**Error: "Challenge failed (http-01)"
- Puerto 80 no está accesible desde internet
- Verifica Security Groups/Firewall de AWS
- Asegúrate que Apache está ejecutándose

**Error: "Rate limit exceeded"
- Has solicitado demasiados certificados en 7 días
- Espera una semana o usa `--staging` para testing

**Error: "Certificate is not trusted"
- Todavía está en proceso de validación
- Espera unos minutos
- Limpia cache del navegador

**Verificar errores con logs:**
```bash
sudo certbot renew --dry-run
sudo journalctl -u snap.certbot.renew.service -n 50
```

---

### Comparación de Configuración

**Con certificados autofirmados (Práctica 1.4):**
- Rápido de implementar
- Para desarrollo/testing
- Advertencias de seguridad en navegador

**Con Let's Encrypt (Práctica 1.5):**
- Para producción
- Certificados válidos y confiables
- Renovación automática
- Mejora SEO

### Orden de ejecución recomendado (Producción)

1. Registra un dominio en cualquier registrador
2. Configura DNS para que apunte a tu servidor
3. Instala LAMP: `bash install_lamp.sh`
4. Despliega la aplicación: `bash deploy.sh`
5. Instala certificado Let's Encrypt: `sudo bash setup_letsencrypt_certificate.sh`
6. Verifica que HTTPS funciona
7. Monitorea renovaciones automáticas

---

## Solución de Problemas Comunes

### Los scripts no tienen permisos de ejecución
```bash
chmod +x scripts/install_lamp.sh
chmod +x scripts/deploy.sh
```

### Permiso denegado al ejecutar scripts
```bash
sudo bash scripts/install_lamp.sh
sudo bash scripts/deploy.sh
```

### Error: "No such file or directory" para `.env`
- Verifica que el archivo `.env` existe en la carpeta `scripts/`
- Ejecuta los scripts desde la carpeta `scripts/`

### MySQL rechaza la contraseña
- Verifica que `DB_ROOT_PASS` en `.env` coincide con la contraseña que estableciste
- Si es la primera ejecución, MySQL puede estar sin contraseña

### La aplicación muestra errores de conexión a BD
- Verifica que la BD, usuario y contraseña en `config.php` son correctos
- Ejecuta: `mysql -u root -p"$DB_ROOT_PASS" -e "USE $DB_NAME; SHOW TABLES;"`

---

## Notas de Seguridad

1. **Cambia las contraseñas por defecto** en el archivo `.env`
2. **No commits `.env`** al repositorio (agrega a `.gitignore`)
3. **Usa HTTPS en producción** (obligatorio)
   - Usa certificados válidos de Let's Encrypt (gratuito)
   - Los certificados autofirmados solo para desarrollo/testing
4. **Protege las claves privadas**
   - Nunca compartas ni subas a repositorios
   - Certificados: `/etc/ssl/private/` - Permisos restrictivos
   - Let's Encrypt automáticamente los gestiona
5. **Monitorea renovaciones de certificados**
   ```bash
   sudo certbot certificates   # Ver estado de certificados
   sudo certbot renew --dry-run # Simular renovación
   ```
6. **Restringe permisos de archivos** sensibles
   ```bash
   sudo chmod 600 /etc/letsencrypt/live/*/privkey.pem
   ```
7. **Actualiza regularmente** los paquetes del sistema
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```
8. **Monitora los logs** regularmente
   ```bash
   tail -f /var/log/apache2/error.log
   tail -f /var/log/apache2/access.log
   tail -f /var/log/letsencrypt/letsencrypt.log
   ```

---

## Variables de Entorno (.env)

### Variables de Base de Datos

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `DB_ROOT_PASS` | Contraseña root de MySQL | `SecurePass123!` |
| `DB_NAME` | Nombre de la base de datos | `mi_aplicacion` |
| `DB_USER` | Usuario para la aplicación | `app_user` |
| `DB_PASS` | Contraseña del usuario | `AppPass456!` |
| `REPO_URL` | URL del repositorio Git | `https://github.com/user/repo.git` |
| `DIR_TEMP` | Directorio temporal | `/tmp/app-temp` |

### Variables de Certificado SSL/TLS (Autofirmado)

| Variable | Descripción | Ejemplo |
|----------|-------------|----------|
| `OPENSSL_COUNTRY` | País (código ISO 2 letras) | `ES`, `US`, `MX` |
| `OPENSSL_PROVINCE` | Provincia/Región | `Madrid`, `California` |
| `OPENSSL_LOCALITY` | Ciudad | `Madrid`, `San Francisco` |
| `OPENSSL_ORGANIZATION` | Nombre empresa/organización | `Mi Empresa S.L.` |
| `OPENSSL_ORGUNIT` | Departamento/Unidad | `IT`, `DevOps` |
| `OPENSSL_COMMON_NAME` | **Dominio o IP del servidor** | `www.ejemplo.com`, `192.168.1.1` |
| `OPENSSL_EMAIL` | Email del administrador | `admin@ejemplo.com` |

### Variables de Let's Encrypt / Certbot [NUEVO]

| Variable | Descripción | Ejemplo |
|----------|-------------|----------|
| `LE_EMAIL` | Email para notificaciones de renovación | `admin@tu-dominio.com` |
| `LE_DOMAIN` | Dominio registrado y válido | `mi-sitio.com`, `www.ejemplo.es` |

---

## Referencias Útiles

### General
- [Documentación Apache](https://httpd.apache.org/docs/)
- [Documentación Apache - SSL/TLS](https://httpd.apache.org/docs/current/ssl/)
- [Documentación MySQL](https://dev.mysql.com/doc/)
- [Documentación PHP](https://www.php.net/docs.php)
- [Bash scripting guide](https://www.gnu.org/software/bash/manual/)

### SSL/TLS - Autofirmado
- [Documentación OpenSSL](https://www.openssl.org/docs/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)

### Let's Encrypt & Certbot
- [Let's Encrypt - Certificados gratuitos para producción](https://letsencrypt.org/)
- [Certbot - Cliente oficial de Let's Encrypt](https://certbot.eff.org/)
- [Certbot con Apache](https://certbot.eff.org/instructions?ws=apache&os=ubuntufocal)
- [Let's Encrypt - Cómo funciona](https://letsencrypt.org/how-it-works/)
- [Troubleshooting Certbot](https://certbot.eff.org/faq/)

### Herramientas de Validación
- [SSL Labs - Prueba tu certificado](https://www.ssllabs.com/ssltest/)
- [Qualys SSL Certificate Checker](https://www.ssllabs.com/ssltest/analyze.html)
- [Let's Encrypt Dashboard](https://letsencrypt.org/issuance/)

---
