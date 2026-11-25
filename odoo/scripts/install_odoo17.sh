#!/usr/bin/env bash
# =============================================================================
# install_odoo17.sh — Installation complète d'Odoo 17 sur Ubuntu 24.04
#
# Installe : PostgreSQL, utilisateur système dédié, environnement virtuel
#            Python, Odoo 17 (depuis GitHub), service systemd, Nginx (proxy).
#
# Usage    : sudo ./install_odoo17.sh
# Note     : lisez ce script attentivement avant de l'exécuter.
# =============================================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "❌ Ce script doit être lancé en root : sudo ./install_odoo17.sh"
  exit 1
fi

ODOO_USER="odoo17"
ODOO_HOME="/opt/odoo17"
ODOO_CONF="/etc/odoo17.conf"
ODOO_PORT="8069"
ODOO_BRANCH="17.0"

echo "==> Mise à jour du système..."
apt update && apt upgrade -y

echo "==> Installation des dépendances..."
apt install -y git python3 python3-pip python3-venv python3-dev \
  build-essential wget curl unzip openssl \
  libxml2-dev libxslt1-dev zlib1g-dev libldap2-dev libsasl2-dev \
  libjpeg-dev libpq-dev libffi-dev libssl-dev \
  node-less npm

echo "==> Installation de PostgreSQL..."
apt install -y postgresql
systemctl enable --now postgresql

echo "==> Création de l'utilisateur PostgreSQL pour Odoo..."
sudo -u postgres createuser -s "$ODOO_USER" || true

echo "==> Création de l'utilisateur système Odoo..."
adduser --system --home="$ODOO_HOME" --group "$ODOO_USER" || true

echo "==> Téléchargement d'Odoo..."
if [ ! -d "$ODOO_HOME/odoo" ]; then
  git clone --branch "$ODOO_BRANCH" --depth 1 https://github.com/odoo/odoo "$ODOO_HOME/odoo"
  chown -R "$ODOO_USER:$ODOO_USER" "$ODOO_HOME"
fi

echo "==> Création du dossier d'addons personnalisés..."
mkdir -p "$ODOO_HOME/custom_addons"
chown "$ODOO_USER:$ODOO_USER" "$ODOO_HOME/custom_addons"

echo "==> Création de l'environnement virtuel Python..."
sudo -u "$ODOO_USER" python3 -m venv "$ODOO_HOME/venv"
sudo -u "$ODOO_USER" "$ODOO_HOME/venv/bin/pip" install --upgrade pip wheel
sudo -u "$ODOO_USER" "$ODOO_HOME/venv/bin/pip" install -r "$ODOO_HOME/odoo/requirements.txt"
sudo -u "$ODOO_USER" "$ODOO_HOME/venv/bin/pip" install psycopg2-binary

echo "==> Création du fichier de configuration Odoo..."
# Le mot de passe maître est généré aléatoirement : il n'est JAMAIS écrit en dur.
cat <<EOF > "$ODOO_CONF"
[options]
addons_path = $ODOO_HOME/odoo/addons,$ODOO_HOME/custom_addons
admin_passwd = $(openssl rand -hex 16)
db_host = False
db_port = False
db_user = $ODOO_USER
db_password = False
logfile = /var/log/$ODOO_USER/odoo.log
http_port = $ODOO_PORT
EOF
chown "$ODOO_USER:$ODOO_USER" "$ODOO_CONF"
chmod 640 "$ODOO_CONF"

mkdir -p "/var/log/$ODOO_USER"
chown "$ODOO_USER:root" "/var/log/$ODOO_USER"

echo "==> Création du service systemd Odoo..."
cat <<EOF > "/etc/systemd/system/$ODOO_USER.service"
[Unit]
Description=Odoo17
Documentation=https://www.odoo.com
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=$ODOO_USER
PermissionsStartOnly=true
User=$ODOO_USER
Group=$ODOO_USER
ExecStart=$ODOO_HOME/venv/bin/python3 $ODOO_HOME/odoo/odoo-bin -c $ODOO_CONF
WorkingDirectory=$ODOO_HOME/odoo
StandardOutput=journal+console
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "==> Activation et démarrage du service Odoo..."
systemctl daemon-reload
systemctl enable --now "$ODOO_USER"
systemctl status "$ODOO_USER" --no-pager || true

echo "==> Installation de Nginx..."
apt install -y nginx

echo "==> Configuration Nginx..."
cat <<EOF > /etc/nginx/sites-available/odoo
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/odoo.access.log;
    error_log /var/log/nginx/odoo.error.log;

    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;

    location / {
        proxy_pass http://127.0.0.1:$ODOO_PORT;
    }

    location /longpolling {
        proxy_pass http://127.0.0.1:8072;
    }
}
EOF

ln -sf /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/odoo
nginx -t && systemctl reload nginx

echo "========================================================"
echo "✅ Installation terminée !"
echo "Accès à Odoo : http://$(hostname -I | awk '{print $1}'):$ODOO_PORT"
echo ""
echo "Mot de passe maître (à noter dans un gestionnaire de mots de passe) :"
echo "  sudo grep admin_passwd $ODOO_CONF"
echo "========================================================"
