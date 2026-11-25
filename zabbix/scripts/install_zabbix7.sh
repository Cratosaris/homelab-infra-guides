#!/usr/bin/env bash
# =============================================================================
# install_zabbix7.sh — Installation complète de Zabbix 7.0 LTS sur Ubuntu 24.04
#
# Base de données : PostgreSQL
# Frontend web    : Nginx + PHP-FPM (port 8080)
#
# Usage :
#   # Mot de passe généré automatiquement (recommandé) :
#   sudo ./install_zabbix7.sh
#
#   # Ou en choisissant votre propre mot de passe :
#   sudo ZABBIX_DB_PASSWORD='un-mot-de-passe-solide' -E ./install_zabbix7.sh
#
# Le mot de passe de la base n'est jamais affiché à l'écran : il est enregistré
# dans /root/.zabbix_db_credentials (lecture réservée à root).
# =============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "❌ Ce script doit être lancé en root : sudo ./install_zabbix7.sh"
  exit 1
fi

DB_NAME="zabbix"
DB_USER="zabbix"
ZBX_VERSION="7.0"
# Mot de passe fourni via l'environnement, sinon généré aléatoirement
DB_PASSWORD="${ZABBIX_DB_PASSWORD:-$(openssl rand -base64 24 | tr -d '/+=\n')}"
CRED_FILE="/root/.zabbix_db_credentials"

echo "==> Mise à jour du système..."
apt update && apt upgrade -y

echo "==> Installation des dépendances..."
apt install -y wget curl gnupg lsb-release nano openssl

echo "==> Ajout du dépôt officiel Zabbix..."
wget -q "https://repo.zabbix.com/zabbix/${ZBX_VERSION}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZBX_VERSION}-1+ubuntu24.04_all.deb"
dpkg -i "zabbix-release_${ZBX_VERSION}-1+ubuntu24.04_all.deb"
apt update

echo "==> Installation de PostgreSQL..."
apt install -y postgresql postgresql-contrib

echo "==> Création de la base et de l'utilisateur PostgreSQL Zabbix..."
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1; then
  sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';"
fi
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1; then
  sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"
fi

echo "==> Installation de Zabbix Server, Frontend, Agent et utilitaires..."
apt install -y zabbix-server-pgsql zabbix-frontend-php \
               zabbix-nginx-conf zabbix-sql-scripts \
               zabbix-agent php8.3-pgsql

echo "==> Importation du schéma de base de données initial..."
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u "${DB_USER}" psql "${DB_NAME}"

echo "==> Configuration de Zabbix Server..."
sed -i "s/^# DBPassword=.*/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf

echo "==> Configuration Nginx pour Zabbix..."
sed -i "s/#        listen.*/        listen 8080;/" /etc/zabbix/nginx.conf
sed -i "s/#        server_name.*/        server_name _;/" /etc/zabbix/nginx.conf

echo "==> Activation et démarrage des services..."
systemctl restart zabbix-server zabbix-agent nginx php8.3-fpm
systemctl enable zabbix-server zabbix-agent nginx php8.3-fpm

echo "==> Enregistrement des identifiants de la base (lecture root uniquement)..."
umask 077
cat > "$CRED_FILE" <<EOF
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
EOF
chmod 600 "$CRED_FILE"

echo "========================================================"
echo "✅ Installation terminée !"
echo "Accès web : http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "Identifiants de la base PostgreSQL (assistant web, étape 3) :"
echo "  Fichier : $CRED_FILE"
echo "  Lecture : sudo cat $CRED_FILE"
echo "========================================================"
