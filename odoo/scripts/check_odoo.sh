#!/usr/bin/env bash
# =============================================================================
# check_odoo.sh — Diagnostic + réparation automatique pour Odoo 17
#
# Vérifie : services (Odoo, PostgreSQL, Nginx), port, logs, utilisateur et base
#           PostgreSQL, configuration, réponse HTTP.
# Relance automatiquement les services inactifs.
# Génère un rapport HTML : /tmp/rapport_odoo.html
#
# Usage : sudo ./check_odoo.sh
# =============================================================================

ODOO_USER="odoo17"
ODOO_CONF="/etc/odoo17.conf"
ODOO_PORT="8069"
ODOO_LOG="/var/log/$ODOO_USER/odoo.log"
HTML_REPORT="/tmp/rapport_odoo.html"

# Le rapport n'est lisible que par son propriétaire
umask 077

add_html() {
  echo "<p><b>$1 :</b> $2</p>" >> "$HTML_REPORT"
}

# Vérifie un service systemd, tente un redémarrage s'il est inactif
check_service() {
  local svc="$1" label="$2"
  if systemctl is-active --quiet "$svc"; then
    echo "✅ $label est actif"
    add_html "Service $label" "<span class='ok'>Actif</span>"
  else
    echo "❌ $label est inactif → tentative de redémarrage..."
    systemctl restart "$svc"
    sleep 3
    if systemctl is-active --quiet "$svc"; then
      echo "✅ $label redémarré avec succès"
      add_html "Service $label" "<span class='ok'>Redémarré avec succès</span>"
    else
      echo "⚠️  Impossible de redémarrer $label"
      add_html "Service $label" "<span class='fail'>Échec du redémarrage</span>"
    fi
  fi
}

echo "======================================================="
echo " 🔍 Diagnostic complet d'Odoo 17 (avec auto-réparation)"
echo "======================================================="

cat <<EOF > "$HTML_REPORT"
<html>
<head>
  <meta charset="UTF-8">
  <title>Rapport Diagnostic Odoo 17</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #4CAF50; }
    .ok { color: green; font-weight: bold; }
    .fail { color: red; font-weight: bold; }
    .info { color: orange; font-weight: bold; }
    pre { background: #f4f4f4; padding: 10px; border-radius: 5px; }
  </style>
</head>
<body>
  <h1>Rapport Diagnostic Odoo 17</h1>
  <p>Généré le : $(date)</p>
  <hr>
EOF

echo -e "\n[1] Service Odoo";       check_service "$ODOO_USER" "Odoo"
echo -e "\n[2] Service PostgreSQL"; check_service postgresql "PostgreSQL"
echo -e "\n[3] Service Nginx";      check_service nginx "Nginx"

echo -e "\n[4] Port $ODOO_PORT"
if ss -ltn | grep -q ":$ODOO_PORT "; then
  echo "✅ Port $ODOO_PORT ouvert"
  add_html "Port $ODOO_PORT" "<span class='ok'>Ouvert</span>"
else
  echo "❌ Port $ODOO_PORT non ouvert"
  add_html "Port $ODOO_PORT" "<span class='fail'>Fermé</span>"
fi

echo -e "\n[5] Dernières lignes du log Odoo"
if [ -f "$ODOO_LOG" ]; then
  tail -n 10 "$ODOO_LOG"
  add_html "Logs Odoo" "<pre>$(tail -n 10 "$ODOO_LOG")</pre>"
else
  echo "❌ Aucun log trouvé"
  add_html "Logs Odoo" "<span class='fail'>Aucun log trouvé</span>"
fi

echo -e "\n[6] PostgreSQL : utilisateur et base"
if sudo -u postgres psql -tAc "SELECT usename FROM pg_user;" | grep -q "$ODOO_USER"; then
  echo "✅ Utilisateur PostgreSQL $ODOO_USER trouvé"
  add_html "Utilisateur PostgreSQL" "<span class='ok'>$ODOO_USER trouvé</span>"
else
  echo "❌ Utilisateur PostgreSQL $ODOO_USER manquant"
  add_html "Utilisateur PostgreSQL" "<span class='fail'>$ODOO_USER manquant</span>"
fi

if sudo -u postgres psql -tAc "SELECT datname FROM pg_database;" | grep -q odoo; then
  echo "✅ Base Odoo trouvée"
  add_html "Base PostgreSQL" "<span class='ok'>Base Odoo trouvée</span>"
else
  echo "ℹ️  Aucune base Odoo trouvée"
  add_html "Base PostgreSQL" "<span class='info'>Pas encore créée</span>"
fi

echo -e "\n[7] Configuration Odoo"
if [ -f "$ODOO_CONF" ]; then
  # Le mot de passe maître (admin_passwd) est volontairement exclu de l'affichage
  # et du rapport HTML.
  CONF_SUMMARY=$(grep -E "^(addons_path|http_port|xmlrpc_port)" "$ODOO_CONF")
  echo "$CONF_SUMMARY"
  add_html "Configuration Odoo" "<pre>$CONF_SUMMARY</pre>"
else
  echo "❌ Fichier de configuration manquant"
  add_html "Configuration Odoo" "<span class='fail'>Fichier manquant</span>"
fi

echo -e "\n[8] Test HTTP"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$ODOO_PORT/web/login")
if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Odoo répond sur le port $ODOO_PORT (HTTP 200)"
  add_html "Test HTTP Odoo" "<span class='ok'>Répond correctement (200 OK)</span>"
else
  echo "❌ Odoo ne répond pas correctement (code HTTP : $HTTP_CODE)"
  add_html "Test HTTP Odoo" "<span class='fail'>Pas de réponse (code $HTTP_CODE)</span>"
fi

cat <<EOF >> "$HTML_REPORT"
<hr>
<p><i>Rapport généré automatiquement par check_odoo.sh</i></p>
</body>
</html>
EOF

echo -e "\n======================================================="
echo " 🔎 Fin du diagnostic"
echo "📄 Rapport HTML généré : $HTML_REPORT"
echo "======================================================="
