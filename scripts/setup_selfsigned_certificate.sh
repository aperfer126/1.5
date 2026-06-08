#!/bin/bash

set -ex

cd "$(dirname "$0")"
source .env

sudo apt update
sudo apt install -y openssl

sudo mkdir -p /etc/ssl/private /etc/ssl/certs
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/apache-selfsigned.key \
  -out /etc/ssl/certs/apache-selfsigned.crt \
  -subj "/C=${OPENSSL_COUNTRY}/ST=${OPENSSL_PROVINCE}/L=${OPENSSL_LOCALITY}/O=${OPENSSL_ORGANIZATION}/OU=${OPENSSL_ORGUNIT}/CN=${OPENSSL_COMMON_NAME}/emailAddress=${OPENSSL_EMAIL}"

sudo cp ../conf/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
sudo a2enmod ssl
sudo a2enmod rewrite
sudo a2ensite default-ssl.conf
sudo a2ensite 000-default.conf
sudo systemctl restart apache2
