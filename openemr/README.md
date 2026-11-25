# 🏥 OpenEMR sur Ubuntu 24.04 Server (LEMP)

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?logo=ubuntu&logoColor=white)
![OpenEMR](https://img.shields.io/badge/OpenEMR-7.0.2-2E7D32)
![Stack](https://img.shields.io/badge/stack-Nginx%20%7C%20MariaDB%20%7C%20PHP%208.3-informational)
![Difficulté](https://img.shields.io/badge/difficulté-intermédiaire-yellow)

> Déployez **OpenEMR**, la solution open source de dossier médical électronique et de gestion de cabinet, sur une pile **LEMP** (Linux, Nginx, MariaDB, PHP-FPM).

## 📑 Sommaire

1. [Présentation](#-présentation)
2. [Prérequis](#-prérequis)
3. [Installer la pile LEMP](#1-installer-la-pile-lemp)
4. [Configurer PHP-FPM](#2-configurer-php-fpm)
5. [Configurer MariaDB](#3-configurer-mariadb)
6. [Télécharger OpenEMR](#4-télécharger-openemr)
7. [Configurer Nginx](#5-configurer-nginx)
8. [HTTPS (optionnel)](#6-https-optionnel-mais-recommandé)
9. [Assistant d'installation](#7-assistant-dinstallation-web)
10. [Après l'installation](#8-après-linstallation--sécurité)
11. [Dépannage](#-dépannage)

## 🎯 Présentation

OpenEMR est une solution intégrée de **dossiers médicaux électroniques**, de **planification**, de **facturation** et de gestion de cabinet, certifiée **ONC**. C'est une application web **PHP + MySQL/MariaDB**.

## ✅ Prérequis

- Un serveur **Ubuntu 24.04**
- Un utilisateur **non root** avec droits `sudo`
- **2 Go de RAM** minimum, 10 Go de disque
- *(Optionnel)* un nom de domaine pointant vers l'IP du serveur, nécessaire pour Let's Encrypt

> 💡 **Sans nom de domaine ?** Pas de problème : ce guide propose une configuration Nginx par IP à l'[étape 5](#5-configurer-nginx).

## 1. Installer la pile LEMP

```bash
sudo apt update
sudo apt install -y nginx mariadb-server php-fpm php-mysql php-bcmath php-xml \
  php-zip php-curl php-mbstring php-gd php-tidy php-intl php-cli php-soap \
  imagemagick libtiff-tools php-ldap
```

Vérifiez que chaque service est **actif** :

```bash
sudo systemctl is-enabled nginx && sudo systemctl status nginx
```

![Nginx](<images/nginx status.png>)

```bash
sudo systemctl is-enabled mariadb && sudo systemctl status mariadb
```

![MariaDB](<images/mariadb status.png>)

```bash
sudo systemctl is-enabled php8.3-fpm && sudo systemctl status php8.3-fpm
```

![PHP 8.3 FPM](<images/php status 8.3.png>)

## 2. Configurer PHP-FPM

```bash
sudo nano /etc/php/8.3/fpm/php.ini
```

Ajustez ces valeurs (adaptez `memory_limit` à votre RAM) :

```ini
max_execution_time = 60
max_input_time = -1
memory_limit = 512M
post_max_size = 30M
upload_max_filesize = 30M
max_input_vars = 3000
mysqli.allow_local_infile = On
```

Puis :

```bash
sudo chgrp -R www-data /var/lib/php/sessions
sudo systemctl restart php8.3-fpm
```

## 3. Configurer MariaDB

### 3.1 Sécuriser le serveur

```bash
sudo mariadb-secure-installation
```

Répondez ainsi :

| Question | Réponse |
|---|---|
| Entrée pour continuer | `ENTRÉE` |
| Définir le mot de passe root | `Y`, puis saisissez un mot de passe **solide** |
| Interdire la connexion root à distance | `Y` |
| Supprimer la base `test` | `Y` |
| Recharger les privilèges | `Y` |

![Sécurisation de MariaDB](<images/secure maria DB.png>)

### 3.2 Créer la base et l'utilisateur d'OpenEMR

```bash
sudo mariadb -u root -p
```

```sql
CREATE DATABASE openemr;
CREATE USER 'openemruser'@'localhost' IDENTIFIED BY 'CHANGEME_mot_de_passe_solide';
GRANT ALL PRIVILEGES ON openemr.* TO 'openemruser'@'localhost';
FLUSH PRIVILEGES;
```

> 🔐 Remplacez `CHANGEME_mot_de_passe_solide` par un vrai mot de passe. Vous en aurez besoin à l'[étape 7](#7-assistant-dinstallation-web).

![Création de la base](<images/create database mariadb.png>)

Vérifiez les droits, puis quittez avec `quit` :

```sql
SHOW GRANTS FOR openemruser@localhost;
```

![Privilèges](<images/look privilleges mariadb user database.png>)

## 4. Télécharger OpenEMR

```bash
cd /var/www/
sudo wget https://sourceforge.net/projects/openemr/files/OpenEMR%20Current/7.0.2/openemr-7.0.2.tar.gz
```

![Téléchargement](<images/openEmr succeful download.png>)

```bash
sudo tar -pxzf openemr-7.0.2.tar.gz
sudo mv openemr-7.0.2 openemr
sudo chown -R www-data:www-data /var/www/openemr
```

> 📌 Vérifiez la dernière version stable sur [open-emr.org](https://www.open-emr.org/) et adaptez les commandes si besoin.

## 5. Configurer Nginx

Deux options, selon que vous avez un nom de domaine ou non.

### Option A : avec un nom de domaine

```bash
sudo nano /etc/nginx/sites-available/openemr
```

```nginx
server {
    listen 80;
    server_name openemr.example.com;   # ← votre nom de domaine

    access_log /var/log/nginx/openemr.access.log;
    error_log  /var/log/nginx/openemr.error.log;

    root /var/www/openemr;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php;
    }

    # Transmission des scripts PHP à PHP-FPM
    location ~* \.php$ {
        try_files $uri =404;
        fastcgi_index index.php;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;   # doit correspondre à votre version de PHP
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $realpath_root;
        include fastcgi_params;
    }

    # Protection des dossiers sensibles
    location ~* ^/sites/*/(documents|edi|era) { deny all; return 404; }
    location ~* ^/(contrib|tests)            { deny all; return 404; }
    location ~* ^/(admin|setup|acl_setup|acl_upgrade|sl_convert|sql_upgrade|gacl/setup|ippf_upgrade|sql_patch)\.php {
        deny all;
        return 404;
    }

    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt  { log_not_found off; access_log off; }
    location ~ /\.          { deny all; }
}
```

> ⚠️ Les règles `deny` sur `setup.php` bloquent l'assistant d'installation. Commentez cette ligne **le temps de l'installation**, puis réactivez-la.

Activez le site :

```bash
sudo ln -s /etc/nginx/sites-available/openemr /etc/nginx/sites-enabled/
```

### Option B : sans nom de domaine (accès par IP)

On modifie le site Nginx par défaut :

```bash
sudo nano /etc/nginx/sites-available/default
```

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    # La racine est le dossier qui CONTIENT « openemr »
    root /var/www;
    index index.php index.html index.htm;
    server_name _;

    location /openemr {
        try_files $uri $uri/ /openemr/index.php?$query_string;
    }

    # Protection des dossiers sensibles
    location ~* ^/openemr/sites/.*/(documents|edi|era) { deny all; return 404; }
    location ~* ^/openemr/(contrib|tests)              { deny all; return 404; }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        # Vérifiez votre version de PHP avec : ls /run/php/
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    location ~ /\.ht { deny all; }
}
```

### Valider et redémarrer

```bash
sudo nginx -t
sudo systemctl restart nginx
```

Vous devez obtenir : `syntax is ok` et `test is successful`.

## 6. HTTPS (optionnel mais recommandé)

> 🩺 Un dossier médical contient des **données sensibles** : en production, HTTPS est indispensable. En laboratoire local, vous pouvez utiliser un certificat auto-signé.

```bash
sudo ufw allow 'Nginx Full'
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d openemr.example.com     # ← votre vrai nom de domaine
```

Les certificats sont stockés dans `/etc/letsencrypt/live/<domaine>/`.

## 7. Assistant d'installation web

Ouvrez :

- avec HTTPS/domaine : `https://openemr.example.com/`
- sans domaine : `http://<IP-du-serveur>/openemr`

![Démarrage de l'assistant](<images/start steps now.png>)

**Étape 1** : l'assistant vérifie les permissions du code source.

![Étape 1](<images/step one.png>)

**Étape 2** : choisissez **« I have already created the database »**.

![Étape 2](<images/step two.png>)

**Étape 3** : saisissez les informations de la base (`openemr`, `openemruser`, votre mot de passe) et créez le compte administrateur d'OpenEMR.

![Étape 3](<images/Set up tree.png>)

**Étape 4** : initialisation de la base et création de l'administrateur.

![Étape 4](<images/step four.png>)

**Étape 5** : contrôle de la configuration PHP.

![Étape 5](<images/step five.png>)

**Étape 6** : choix du thème de connexion.

![Étape 6](<images/step six.png>)

Dernière étape de configuration :

![Fin de l'installation](<images/finaly step installations.png>)

Vous êtes redirigé vers la page de connexion. Entrez votre compte administrateur :

![Connexion](<images/connexion openemr.png>)

🎉 Le tableau de bord OpenEMR s'affiche :

![Interface OpenEMR](<images/interface grafique openemr.png>)

## 8. Après l'installation : sécurité

- [ ] Remettez les règles `deny` de Nginx que vous aviez désactivées pour l'assistant
- [ ] Passez le fichier de configuration en lecture seule : `sudo chmod 444 /var/www/openemr/sites/default/sqlconf.php`
- [ ] Changez le mot de passe `admin` si vous avez utilisé une valeur provisoire
- [ ] Activez HTTPS et planifiez des **sauvegardes chiffrées** de la base et du dossier `sites/`
- [ ] Gardez PHP, MariaDB et OpenEMR à jour

## 🔧 Dépannage

| Symptôme | Solution |
|---|---|
| **404** sur `/openemr` | Vérifiez `root` et `location /openemr` dans le site Nginx ; `sudo nginx -t` |
| **502 Bad Gateway** | Le socket PHP ne correspond pas : `ls /run/php/` puis corrigez `fastcgi_pass` |
| Page blanche ou erreurs PHP | `sudo tail -f /var/log/nginx/error.log` |
| « Cannot connect to database » | Vérifiez nom de base, utilisateur et mot de passe ; `sudo mariadb -u openemruser -p openemr` |
| Envoi de fichiers refusé | Augmentez `upload_max_filesize` et `post_max_size` dans `php.ini` |

## 📖 Références

- [Site officiel d'OpenEMR](https://www.open-emr.org/)
- [Wiki OpenEMR](https://www.open-emr.org/wiki/)
- [Documentation Nginx](https://nginx.org/en/docs/)

---

⬅️ [Retour à l'accueil du dépôt](../README.md)
