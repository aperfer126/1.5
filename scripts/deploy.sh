#!/bin/bash

set -ex

cd "$(dirname "$0")"
source .env

# Desplegar la aplicación web propuesta
sudo apt update
sudo apt install -y git

sudo rm -rf /var/www/html/*
sudo git clone "$APP_REPO" /var/www/html/app
sudo rsync -a --exclude='.git' /var/www/html/app/ /var/www/html/
sudo rm -rf /var/www/html/app

# Ajustar permisos y reiniciar Apache
sudo chown -R www-data:www-data /var/www/html
sudo systemctl restart apache2

# Crear la base de datos y asignar permisos de nuevo si es necesario
sudo mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
