# 📊 Grafana + Prometheus sur Ubuntu Server 22.04

![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-E95420?logo=ubuntu&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-3.6.0-E6522C?logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-OSS-F46800?logo=grafana&logoColor=white)
![Difficulté](https://img.shields.io/badge/difficulté-intermédiaire-yellow)

> Installez une stack de supervision moderne : **Prometheus** collecte les métriques, **node_exporter** observe votre serveur, **Grafana** les transforme en tableaux de bord, le tout derrière **Nginx**.

## 📑 Sommaire

1. [Présentation](#-présentation)
2. [Prérequis](#-prérequis)
3. [Étape 1 : Dépôt Grafana](#étape-1--ajouter-le-dépôt-grafana)
4. [Étape 2 : Installer Grafana](#étape-2--installer-et-configurer-grafana)
5. [Étape 3 : Reverse proxy Nginx](#étape-3--installer-et-configurer-nginx)
6. [Étape 4 : Installer Prometheus](#étape-4--installer-et-configurer-prometheus)
7. [Étape 5 : node_exporter](#étape-5--installer-node_exporter)
8. [Étape 6 : Accéder à Prometheus](#étape-6--accéder-à-prometheus)
9. [Étape 7 : Démarrage automatique](#étape-7--démarrage-automatique)
10. [Étape 8 : Dashboard Grafana 1860](#étape-8--connecter-grafana-et-importer-le-dashboard-1860)
11. [Dépannage](#-dépannage)
12. [Références](#-références)

## 🎯 Présentation

**Grafana** est une plateforme open source de visualisation et d'observabilité, créée en 2014. **Prometheus** est une base de données de séries temporelles qui *récupère* (scrape) les métriques exposées par vos serveurs.

Voici comment les composants dialoguent :

![Schéma de fonctionnement de Prometheus](<images-prometheus/olla promotheus.webp>)

| Composant | Rôle | Port |
|---|---|---|
| Grafana | Tableaux de bord | 3000 (derrière Nginx : 80) |
| Prometheus | Collecte et stockage des métriques | 9090 |
| node_exporter | Métriques du système (CPU, RAM, disque, réseau) | 9100 |
| Nginx | Reverse proxy devant Grafana | 80 |

## ✅ Prérequis

- Un serveur **Ubuntu Server 22.04** avec accès `root` ou `sudo`
- **2 Go de RAM** minimum, 10 Go de disque
- Un accès Internet
- *(Optionnel)* un nom de domaine pour Grafana

> 💡 Dans ce guide, les commandes sont écrites avec `sudo`. Si vous êtes connecté en `root`, vous pouvez l'omettre.

---

## Étape 1 : Ajouter le dépôt Grafana

Installez les dépendances :

```bash
sudo apt update
sudo apt install -y gnupg2 apt-transport-https software-properties-common wget
```

Ajoutez la clé GPG et le dépôt officiels de Grafana :

```bash
sudo mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update
```

## Étape 2 : Installer et configurer Grafana

```bash
sudo apt install -y grafana
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl status grafana-server
```

Résultat attendu : `active (running)`.

```text
● grafana-server.service - Grafana instance
     Active: active (running) since ...
   Main PID: 143160 (grafana)
```

Éditez la configuration :

```bash
sudo nano /etc/grafana/grafana.ini
```

```ini
# Écoute locale uniquement si vous utilisez Nginx devant (recommandé).
# Mettez 0.0.0.0 si vous voulez accéder directement à Grafana sans Nginx.
http_addr = 127.0.0.1

http_port = 3000

# Votre nom de domaine, ou "localhost" si vous n'en avez pas
domain = grafana.example.com
```

Enregistrez, puis redémarrez Grafana :

```bash
sudo systemctl restart grafana-server
```

## Étape 3 : Installer et configurer Nginx

```bash
sudo apt install -y nginx
sudo nano /etc/nginx/conf.d/grafana.conf
```

```nginx
# Nécessaire pour les connexions WebSocket de Grafana Live
map $http_upgrade $connection_upgrade {
  default upgrade;
  ''      close;
}

server {
  listen      80;
  server_name grafana.example.com;   # Remplacez, ou utilisez "_" sans nom de domaine

  access_log /var/log/nginx/grafana-access.log;
  error_log  /var/log/nginx/grafana-error.log;

  location / {
    proxy_set_header Host $http_host;
    proxy_pass http://localhost:3000/;
  }

  # Grafana Live (WebSocket)
  location /api/live {
    rewrite  ^/(.*)  /$1 break;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Host $http_host;
    proxy_pass http://localhost:3000/;
  }
}
```

Testez la syntaxe puis rechargez Nginx :

```bash
sudo nginx -t
sudo systemctl reload nginx
```

![Reverse proxy Nginx fonctionnel](<images-grafana/succeful reverse proxy.png>)

Ouvrez `http://<IP-du-serveur>` (ou `http://<IP>:3000` sans Nginx) : la page de connexion apparaît.

![Page de connexion Grafana](<images-grafana/singup grafana.png>)

Identifiants **par défaut** : `admin` / `admin`. Grafana vous demande aussitôt de choisir un nouveau mot de passe :

![Changement du mot de passe Grafana](<images-grafana/change password.png>)

Vous arrivez ensuite sur le tableau de bord :

![Interface Grafana](<images-grafana/grafana interface 2025.png>)

## Étape 4 : Installer et configurer Prometheus

### 4.1 Utilisateur et répertoires

```bash
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus

sudo mkdir /var/lib/prometheus
for i in rules rules.d files_sd; do sudo mkdir -p /etc/prometheus/${i}; done
```

### 4.2 Télécharger et installer

Choisissez la version sur la [page des releases](https://github.com/prometheus/prometheus/releases). Ici : `3.6.0`.

```bash
PROM_VERSION="3.6.0"
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROM_VERSION}.linux-amd64

sudo cp prometheus promtool /usr/local/bin/
sudo cp prometheus.yml /etc/prometheus/
sudo chown prometheus:prometheus /var/lib/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus
```

> 🐢 **Connexion lente ?** Téléchargez l'archive depuis un autre poste et copiez-la sur le serveur avec `scp`.

Vérifiez :

```bash
prometheus --version
```

```text
prometheus, version 3.6.0 (branch: HEAD, revision: 491734606591ef8c188f5489c70380805bc868c0)
  go version:       go1.24.7
  platform:         linux/amd64
```

### 4.3 Protéger Prometheus par mot de passe

Installez l'utilitaire `htpasswd` et générez un **hash bcrypt** de votre mot de passe :

```bash
sudo apt install -y apache2-utils
htpasswd -nBC 10 "" | tr -d ':\n'
```

Saisissez votre mot de passe (deux fois). La commande affiche un hash du type `$2y$10$...` : copiez-le.

Créez le fichier d'authentification web :

```bash
sudo nano /etc/prometheus/web.yml
```

```yaml
basic_auth_users:
  admin: '$2y$10$REMPLACEZ_PAR_VOTRE_HASH_BCRYPT'
```

```bash
sudo chown prometheus:prometheus /etc/prometheus/web.yml
sudo chmod 640 /etc/prometheus/web.yml
```

> ⚠️ Ne publiez jamais ce fichier : il contient l'empreinte de votre mot de passe. Il est ignoré par le `.gitignore` de ce dépôt.

### 4.4 Permettre à Prometheus de se superviser lui-même

Comme Prometheus est maintenant protégé, il doit s'authentifier pour lire **ses propres** métriques. Stockez le mot de passe en clair dans un fichier lisible uniquement par Prometheus :

```bash
sudo nano /etc/prometheus/prometheus.password    # écrivez le mot de passe, sans retour à la ligne final
sudo chown prometheus:prometheus /etc/prometheus/prometheus.password
sudo chmod 600 /etc/prometheus/prometheus.password
```

Éditez la configuration :

```bash
sudo nano /etc/prometheus/prometheus.yml
```

```yaml
scrape_configs:
  - job_name: "prometheus"
    basic_auth:
      username: 'admin'
      password_file: /etc/prometheus/prometheus.password
    static_configs:
      - targets: ["127.0.0.1:9090"]
```

### 4.5 Créer le service systemd

```bash
sudo nano /etc/systemd/system/prometheus.service
```

```ini
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.listen-address=0.0.0.0:9090 \
  --web.config.file=/etc/prometheus/web.yml
SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo systemctl status prometheus
```

```text
● prometheus.service - Prometheus
     Loaded: loaded (/etc/systemd/system/prometheus.service; enabled)
     Active: active (running) since ...
```

## Étape 5 : Installer node_exporter

`node_exporter` expose les métriques du système sur le port **9100**.

```bash
curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest \
  | grep browser_download_url \
  | grep linux-amd64 \
  | cut -d '"' -f 4 \
  | wget -qi -

tar xvf node_exporter-*.linux-amd64.tar.gz
sudo mv node_exporter-*.linux-amd64/node_exporter /usr/local/bin/
```

Créez un utilisateur dédié, sans shell ni dossier personnel (bonne pratique de sécurité) :

```bash
sudo useradd --no-create-home --shell /bin/false node_exporter
node_exporter --version
```

```text
node_exporter, version 1.9.1 (branch: HEAD, revision: f2ec547b49af53815038a50265aa2a dcd1275959)
```

Service systemd :

```bash
sudo nano /etc/systemd/system/node_exporter.service
```

```ini
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl status node_exporter
```

Ajoutez-le à Prometheus, à la fin de `scrape_configs` dans `/etc/prometheus/prometheus.yml` :

```yaml
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
```

```bash
sudo systemctl reload prometheus
```

## Étape 6 : Accéder à Prometheus

Ouvrez `http://<IP-du-serveur>:9090` et connectez-vous avec `admin` et votre mot de passe.

![Connexion à Prometheus](<images-prometheus/Loggin prometheus.png>)

![Interface Prometheus](<images-prometheus/prometheus interface.png>)

Testez une requête, par exemple `node_cpu_guest_seconds_total`, puis cliquez sur **Execute** :

![Requête de test](<images-prometheus/querry nodes.png>)

Dans **Status → Targets**, vous devez voir deux cibles à l'état **UP** : `prometheus` et `node_exporter`.

![Cibles Prometheus](<images-prometheus/bomm nodes exports 2025.png>)

## Étape 7 : Démarrage automatique

```bash
sudo systemctl enable prometheus.service
sudo systemctl enable grafana-server.service
sudo systemctl enable node_exporter.service
```

Vérification (chaque commande doit répondre `enabled`) :

```bash
systemctl is-enabled prometheus.service
systemctl is-enabled grafana-server.service
```

![Services activés au démarrage](<images-prometheus/systemctl senabled.png>)

## Étape 8 : Connecter Grafana et importer le dashboard 1860

Le dashboard **Node Exporter Full** (ID `1860`) offre une vue complète des métriques système.

### 8.1 Ajouter Prometheus comme source de données

1. Dans Grafana : **Connections → Data sources → Add data source**
2. Choisissez **Prometheus**
3. Renseignez :
   - **Name** : `Prometheus-Local`
   - **URL** : `http://localhost:9090`
   - **Basic auth** : activez-le, puis saisissez l'utilisateur `admin` et votre mot de passe Prometheus
4. Cliquez sur **Save & test** : le message « Data source is working » doit apparaître.

![Étape 1](<images-prometheus/prometheus grafana.png>)
![Étape 2](<images-prometheus/next promotheus grafana.png>)
![Étape 3](<images-prometheus/end promos et grafas.png>)
![Succès](<images-prometheus/succeful insta.png>)

### 8.2 Importer le dashboard

1. **Dashboards → New → Import**
2. Saisissez l'ID **`1860`** puis **Load**

![Import du dashboard 1860](<images-prometheus/1680.png>)

3. Sélectionnez votre source de données Prometheus, puis **Import**

![Configuration de l'import](<images-prometheus/config now.png>)

Le tableau de bord **Node Exporter Full** s'affiche :

![Dashboard Node Exporter Full](<images-prometheus/true dashboard.png>)

---

## 🔧 Dépannage

| Symptôme | Cause probable | Solution |
|---|---|---|
| `401 Unauthorized` sur la cible `prometheus` | Prometheus protégé mais sans identifiants pour se lire lui-même | Vérifiez le bloc `basic_auth` de l'[étape 4.4](#44-permettre-à-prometheus-de-se-superviser-lui-même) |
| Grafana inaccessible | Service arrêté ou mauvais `http_addr` | `sudo systemctl status grafana-server` ; mettez `0.0.0.0` pour un accès direct |
| Cible `node_exporter` en `DOWN` | Service arrêté ou port 9100 bloqué | `sudo systemctl status node_exporter` |
| `Data source is not working` | URL ou Basic auth incorrects | Vérifiez l'URL et le mot de passe Prometheus |
| Prometheus ne démarre pas | Erreur de syntaxe YAML | `promtool check config /etc/prometheus/prometheus.yml` |

Consultez les journaux avec `sudo journalctl -u prometheus -f` (ou `grafana-server`, `node_exporter`).

## 🔒 Bonnes pratiques de sécurité

- [ ] Changer le mot de passe `admin` de Grafana dès la première connexion
- [ ] Ne pas exposer le port 9090 sur Internet (pare-feu ou reverse proxy)
- [ ] Activer HTTPS (Let's Encrypt) si vous avez un nom de domaine
- [ ] Ne jamais commiter `web.yml` ni `prometheus.password`

## 📖 Références

- [Documentation Grafana](https://grafana.com/docs/grafana/latest/)
- [Documentation Prometheus](https://prometheus.io/docs/introduction/overview/)
- [Sécuriser Prometheus (basic auth)](https://prometheus.io/docs/guides/basic-auth/)
- [Dashboard 1860 : Node Exporter Full](https://grafana.com/grafana/dashboards/1860)

---

⬅️ [Retour à l'accueil du dépôt](../README.md)
