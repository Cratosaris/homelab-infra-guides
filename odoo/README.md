# 💼 Odoo 17 sur Ubuntu 24.04 : installation en un script

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?logo=ubuntu&logoColor=white)
![Odoo](https://img.shields.io/badge/Odoo-17.0-714B67?logo=odoo&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-ok-4169E1?logo=postgresql&logoColor=white)
![Difficulté](https://img.shields.io/badge/difficulté-facile-brightgreen)

> Déployez un ERP **Odoo 17** complet (PostgreSQL, environnement Python isolé, service systemd, Nginx) avec **une seule commande**, puis vérifiez sa santé avec un **script de diagnostic** qui répare automatiquement les services arrêtés.

## 📑 Sommaire

1. [Ce que fait le script](#-ce-que-fait-le-script)
2. [Prérequis](#-prérequis)
3. [Installation](#-installation)
4. [Configurer Odoo dans le navigateur](#-configurer-odoo-dans-le-navigateur)
5. [Script de diagnostic](#-script-de-diagnostic)
6. [HTTPS avec un nom de domaine](#-optionnel--https-avec-certbot)
7. [Dépannage](#-dépannage)

## 📦 Ce que fait le script

| Composant | Détail |
|---|---|
| PostgreSQL | Base de données + utilisateur `odoo17` |
| Utilisateur système | `odoo17` (sans connexion interactive) |
| Odoo 17.0 | Cloné depuis GitHub dans `/opt/odoo17/odoo` |
| Environnement Python | Virtualenv isolé dans `/opt/odoo17/venv` |
| Service systemd | `odoo17.service` (démarrage automatique) |
| Nginx | Reverse proxy sur le port 80 |
| Sécurité | Mot de passe maître **généré aléatoirement**, fichier de configuration en `640` |

## ✅ Prérequis

- Serveur **Ubuntu 24.04** (VM ou physique)
- **4 Go de RAM** recommandés (2 Go minimum), 20 Go de disque
- Accès `sudo` et connexion Internet

## 🚀 Installation

Les scripts sont dans le dossier [`scripts/`](./scripts/) :

| Script | Rôle |
|---|---|
| [`install_odoo17.sh`](./scripts/install_odoo17.sh) | Installation complète |
| [`check_odoo.sh`](./scripts/check_odoo.sh) | Diagnostic et réparation automatique |

**1. Récupérez les scripts**

```bash
git clone https://github.com/Cratosaris/homelab-infra-guides.git
cd homelab-infra-guides/odoo/scripts
```

**2. Rendez-les exécutables**

```bash
chmod +x install_odoo17.sh check_odoo.sh
```

**3. Lancez l'installation**

```bash
sudo ./install_odoo17.sh
```

> 🔎 **Lisez le script avant de l'exécuter** : exécuter du code téléchargé en `root` sans le lire est une mauvaise habitude.

À la fin, le script affiche l'adresse d'accès et la commande pour retrouver votre mot de passe maître :

![Installation terminée](<images/insta odoo 2.png>)
![Étape d'installation](<images/odoo 3.png>)
![Étape d'installation](<images/odoo 4.png>)
![Étape d'installation](<images/oddoo 5.png>)

## 🖥️ Configurer Odoo dans le navigateur

### 1. Ouvrir Odoo

```text
http://<IP-du-serveur>:8069
```

*(ou `http://<IP-du-serveur>` grâce à Nginx, ou `https://votre-domaine.com` si vous avez configuré SSL)*

### 2. Créer la base de données

Le formulaire **Create Database** apparaît. Renseignez :

| Champ | Valeur |
|---|---|
| **Master Password** | Le mot de passe généré par le script (voir ci-dessous) |
| **Database Name** | `odoo17db` (par exemple) |
| **Email** | Votre identifiant administrateur, ex. `admin@entreprise.com` |
| **Password** | Le mot de passe de votre compte administrateur (**choisissez-le solide**) |
| **Language / Country** | Selon vos besoins |
| **Demo data** | À cocher uniquement pour tester |

Pour retrouver le **mot de passe maître** :

```bash
sudo grep admin_passwd /etc/odoo17.conf
```

> 🔐 Ce mot de passe permet de créer, sauvegarder et **supprimer** des bases. Conservez-le dans un gestionnaire de mots de passe et ne le partagez jamais.

![Création de la base](<images/vrais loggin odoo.png>)

### 3. Se connecter

Utilisez l'e-mail et le mot de passe choisis à l'étape précédente.

![Connexion](<images/odoo loggin.png>)

### 4. Installer vos applications

Facturation, Ventes, Comptabilité, CRM, Inventaire, RH, Site web & e-commerce… chaque module s'installe en un clic.

![Tableau de bord Odoo](<images/boom odoo.png>)

### 5. Paramètres généraux

Dans **Paramètres** (⚙️), vous pouvez modifier le nom de l'entreprise, la devise, le fuseau horaire et activer les fonctionnalités voulues.

## 🩺 Script de diagnostic

`check_odoo.sh` vérifie en quelques secondes :

- ✅ l'état des services **Odoo**, **PostgreSQL** et **Nginx** (et les relance s'ils sont arrêtés)
- ✅ l'ouverture du port `8069`
- ✅ les 10 dernières lignes du journal
- ✅ l'utilisateur et la base PostgreSQL
- ✅ la configuration (le mot de passe maître **n'est jamais affiché**)
- ✅ la réponse HTTP d'Odoo

Il génère aussi un rapport HTML dans `/tmp/rapport_odoo.html`.

```bash
sudo ./check_odoo.sh
```

![Résultat du diagnostic](<images/script diagnostic orginos.png>)

## 🔒 Optionnel : HTTPS avec Certbot

Si vous avez un nom de domaine pointant vers votre serveur :

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d mondomaine.com
```

## 🔧 Dépannage

| Symptôme | Solution |
|---|---|
| Page inaccessible | `sudo ./check_odoo.sh` puis `sudo journalctl -u odoo17 -n 50` |
| Erreur 502 Bad Gateway | Odoo est arrêté : `sudo systemctl restart odoo17` |
| Mot de passe maître oublié | `sudo grep admin_passwd /etc/odoo17.conf` |
| Voir les logs en direct | `sudo tail -f /var/log/odoo17/odoo.log` |
| Ajouter un module personnalisé | Déposez-le dans `/opt/odoo17/custom_addons` puis `sudo systemctl restart odoo17` |

## 🔒 Bonnes pratiques de sécurité

- [ ] Activer HTTPS avant d'ouvrir Odoo sur Internet
- [ ] Restreindre `/web/database/manager` (gestionnaire de bases) ou le désactiver en production avec `list_db = False` dans `/etc/odoo17.conf`
- [ ] Planifier des sauvegardes régulières de la base PostgreSQL
- [ ] Garder le système à jour (`sudo apt update && sudo apt upgrade`)

## 📖 Références

- [Documentation officielle Odoo 17](https://www.odoo.com/documentation/17.0/)
- [Dépôt GitHub d'Odoo](https://github.com/odoo/odoo)

---

⬅️ [Retour à l'accueil du dépôt](../README.md)
