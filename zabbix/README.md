# 📡 Zabbix 7.0 LTS sur Ubuntu Server 24.04

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?logo=ubuntu&logoColor=white)
![Zabbix](https://img.shields.io/badge/Zabbix-7.0%20LTS-D40000?logo=zabbix&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-ok-4169E1?logo=postgresql&logoColor=white)
![Difficulté](https://img.shields.io/badge/difficulté-facile-brightgreen)

> Installez une plateforme de supervision **professionnelle** pour vos serveurs, équipements réseau et applications : Zabbix Server, interface web, agent, PostgreSQL et Nginx, installés par un script.

## 📑 Sommaire

1. [Présentation](#-présentation)
2. [Prérequis](#-prérequis)
3. [Étape 0 : Fuseau horaire](#étape-0--fuseau-horaire)
4. [Étape 1 : Lancer le script](#étape-1--lancer-le-script)
5. [Étape 2 : Assistant web](#étape-2--assistant-de-configuration-web)
6. [Première connexion](#-première-connexion)
7. [Dépannage](#-dépannage)

## 🎯 Présentation

Zabbix est un outil de supervision open source (serveur en C, interface en PHP) qui surveille **réseaux, serveurs, matériels et applications**, et vous alerte avant que les problèmes ne deviennent critiques.

Le script [`install_zabbix7.sh`](./scripts/install_zabbix7.sh) installe :

| Composant | Rôle |
|---|---|
| Zabbix Server | Moteur de collecte et d'alertes |
| Frontend web | Interface d'administration (Nginx + PHP-FPM, port **8080**) |
| Zabbix Agent | Supervision de la machine locale |
| PostgreSQL | Base de données de Zabbix |

## ✅ Prérequis

- **Ubuntu Server 24.04** (VM ou physique)
- **2 Go de RAM** minimum, 20 Go de disque
- Accès `sudo` et connexion Internet

## Étape 0 : Fuseau horaire

Réglez l'heure **avant** l'installation : une mauvaise heure fausse les graphiques et les alertes.

```bash
sudo apt update
sudo dpkg-reconfigure tzdata
```

Sélectionnez votre fuseau (ex. **Africa → Bujumbura**), puis vérifiez :

```bash
timedatectl
```

## Étape 1 : Lancer le script

**1. Récupérez le script**

```bash
git clone https://github.com/Cratosaris/homelab-infra-guides.git
cd homelab-infra-guides/zabbix/scripts
chmod +x install_zabbix7.sh
```

**2. Exécutez-le**

```bash
# Mot de passe de base généré automatiquement (recommandé)
sudo ./install_zabbix7.sh
```

Ou, pour choisir votre propre mot de passe :

```bash
sudo ZABBIX_DB_PASSWORD='un-mot-de-passe-solide' -E ./install_zabbix7.sh
```

> 🔐 **Aucun mot de passe n'est écrit en dur dans le script.** Il est soit généré aléatoirement, soit fourni par vous, puis enregistré dans `/root/.zabbix_db_credentials` (lisible uniquement par `root`). Pour l'afficher :
> ```bash
> sudo cat /root/.zabbix_db_credentials
> ```

À la fin de l'exécution, vous verrez ceci :

![Installation terminée](<images/zabbix.png>)

## Étape 2 : Assistant de configuration web

Ouvrez votre navigateur :

```text
http://<IP-du-serveur>:8080
```

**1. Bienvenue.** Choisissez la langue puis cliquez sur **Next step**.

![Bienvenue](<images/zabbix set up 1.png>)

**2. Prérequis.** Toutes les lignes doivent afficher **OK** en vert.

![Vérification des prérequis](<images/zabbix set up 2.png>)

**3. Base de données.** Choisissez **PostgreSQL** et renseignez :

| Champ | Valeur |
|---|---|
| Database host | `localhost` |
| Database name | `zabbix` |
| User | `zabbix` |
| Password | Le mot de passe de `/root/.zabbix_db_credentials` |

![Configuration de la base](<images/zabbix set up 3.png>)

**4. Paramètres du serveur.** Indiquez le nom du serveur et votre fuseau horaire.

![Paramètres du serveur](<images/set up zabbix 4.png>)

**5. Résumé.** Vérifiez, puis **Next step**.

![Résumé](<images/zabbix set up 5.png>)

**6. Terminé.** Le message « Congratulations » confirme l'installation. Cliquez sur **Finish**.

![Félicitations](<images/set up zabbix 6.png>)

## 🔑 Première connexion

Identifiants **par défaut** de Zabbix (publics, à changer immédiatement) :

| Utilisateur | Mot de passe |
|---|---|
| `Admin` | `zabbix` |

![Connexion](<images/loggin zabbix.png>)

> ⚠️ **Changez ce mot de passe dès la première connexion** : *Users → Users → Admin → Password*.

Vous obtenez le tableau de bord Zabbix :

![Tableau de bord Zabbix](<images/tara zabbix interface.png>)

🎉 **Félicitations**, Zabbix 7.0 LTS est opérationnel !

## 🔧 Dépannage

| Symptôme | Solution |
|---|---|
| Page inaccessible sur le port 8080 | `sudo systemctl status nginx php8.3-fpm` |
| « Zabbix server is not running » | `sudo systemctl status zabbix-server` puis `sudo tail -f /var/log/zabbix/zabbix_server.log` |
| Erreur de connexion à la base | Vérifiez le mot de passe dans `/root/.zabbix_db_credentials` et `DBPassword` dans `/etc/zabbix/zabbix_server.conf` |
| Le script s'arrête sur une erreur | Relancez-le : la création de l'utilisateur et de la base est idempotente |

## 🔒 Bonnes pratiques de sécurité

- [ ] Changer le mot de passe `Admin` par défaut
- [ ] Activer HTTPS avant toute exposition sur Internet
- [ ] Ouvrir le port `10051` (serveur) uniquement aux agents légitimes
- [ ] Sauvegarder régulièrement la base `zabbix`

## 📖 Références

- [Documentation officielle Zabbix 7.0](https://www.zabbix.com/documentation/7.0/en/manual)
- [Téléchargements et dépôts Zabbix](https://www.zabbix.com/download)

---

⬅️ [Retour à l'accueil du dépôt](../README.md)
