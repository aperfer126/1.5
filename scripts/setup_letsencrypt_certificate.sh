#!/bin/bash
set -ex

# 1. Importar variables del archivo .env
source .env

# 2. Instalación y actualización de snap core
snap install core
snap refresh core

# 3. Eliminar posibles instalaciones previas de certbot con apt
apt remove certbot -y

# 4. Instalar Certbot de forma clásica a través de snap
snap install --classic certbot

# 5. Crear el enlace simbólico para el comando certbot
ln -fs /snap/bin/certbot /usr/bin/certbot

# 6. Solicitar e instalar el certificado de forma no interactiva para Apache
certbot --apache -m "$LE_EMAIL" --agree-tos --no-eff-email -d "$LE_DOMAIN" --non-interactive

echo "¡Certificado oficial de Let's Encrypt configurado con éxito!"