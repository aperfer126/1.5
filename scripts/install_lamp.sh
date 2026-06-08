#!/bin/bash

set -ex

cd "$(dirname "$0")"
source .env

# Actualizar el sistema e instalar LAMP
sudo apt update
sudo apt upgrade -y
sudo apt install -y apache2 php libapache2-mod-php php-mysql mysql-server openssl

# Configurar Apache
sudo cp ../conf/000-default.conf /etc/apache2/sites-available/000-default.conf
sudo a2enmod rewrite
sudo systemctl reload apache2

# Crear base de datos si no existe
sudo mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Ajustar permisos web
sudo chown -R www-data:www-data /var/www/html
sudo systemctl restart apache2
