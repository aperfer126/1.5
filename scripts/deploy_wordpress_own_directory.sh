#!/bin/bash
set -ex

# 1. Importar variables del archivo .env
source .env

# 2. Descargar y descomprimir la última versión de WordPress
wget https://wordpress.org/latest.tar.gz -P /tmp
tar -xzvf /tmp/latest.tar.gz -C /tmp

# 3. Limpiar directorio web raíz y mover la carpeta completa de WordPress
rm -rf /var/www/html/*
mv -f /tmp/wordpress /var/www/html/

# 4. Crear la Base de Datos y el Usuario en MySQL/MariaDB
mysql -u root -p"$DB_ROOT_PASS" <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME;"
mysql -u root -p"$DB_ROOT_PASS" <<< "CREATE DATABASE $WORDPRESS_DB_NAME;"
mysql -u root -p"$DB_ROOT_PASS" <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL;"
mysql -u root -p"$DB_ROOT_PASS" <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD';"
mysql -u root -p"$DB_ROOT_PASS" <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL;"

# 5. Configurar el archivo wp-config.php dentro del subdirectorio
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wordpress/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/wordpress/wp-config.php

# 6. Configurar las variables de enrutamiento WP_SITEURL y WP_HOME
sed -i "/DB_COLLATE/a define('WP_SITEURL', 'https://$CERTIFICATE_DOMAIN/wordpress');" /var/www/html/wordpress/wp-config.php
sed -i "/WP_SITEURL/a define('WP_HOME', 'https://$CERTIFICATE_DOMAIN');" /var/www/html/wordpress/wp-config.php

# 7. Configurar las Llaves de Seguridad (Security Keys)
sed -i "/AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/SECURE_AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/LOGGED_IN_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/NONCE_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/AUTH_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/SECURE_AUTH_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/LOGGED_IN_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/NONCE_SALT/d" /var/www/html/wordpress/wp-config.php

SECURITY_KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
SECURITY_KEYS=$(echo "$SECURITY_KEYS" | tr / _)
sed -i "/@-/a $SECURITY_KEYS" /var/www/html/wordpress/wp-config.php

# 8. Modificar el index.php raíz para que apunte al subdirectorio wordpress
cp /var/www/html/wordpress/index.php /var/www/html/
sed -i "s#wp-blog-header.php#wordpress/wp-blog-header.php#" /var/www/html/index.php

# 9. Copiar el archivo .htaccess al directorio raíz para los enlaces permanentes
cp ../conf/.htaccess /var/www/html/.htaccess

# 10. Aplicar permisos de seguridad globales
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# 11. Limpiar residuos temporales
rm -rf /tmp/latest.tar.gz

echo "¡WordPress instalado con éxito en su propio subdirectorio!"