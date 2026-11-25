# 🛠️ Homelab Infrastructure Guides

> Des guides d'installation **pas à pas, testés et illustrés** pour monter votre propre infrastructure : pare-feu, supervision, virtualisation, haute disponibilité et applications métier.

![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04-E95420?logo=ubuntu&logoColor=white)
![Hyper-V](https://img.shields.io/badge/Hyper--V-testé-0078D4?logo=windows&logoColor=white)
![Langue](https://img.shields.io/badge/langue-français-blue)
![Guides](https://img.shields.io/badge/guides-9-success)

Chaque dossier est un **projet autonome** : un `README.md` détaillé, des **captures d'écran** de chaque étape et, quand c'est utile, des **scripts prêts à l'emploi**. Tout a été réalisé dans un laboratoire sous **Hyper-V** (Windows) avec des machines virtuelles Ubuntu Server.

## 📚 Les projets

### 🔥 Sécurité réseau

| Projet | Description | Plateforme |
|---|---|---|
| [**pfSense**](./pfsense/) | Routeur/pare-feu open source (FreeBSD), assistant de configuration, règles de base | Hyper-V |
| [**IPFire**](./ipfire/) | Pare-feu Linux durci : zones GREEN/RED, IPS, VPN, proxy | Hyper-V |

### 📊 Supervision & monitoring

| Projet | Description | Plateforme |
|---|---|---|
| [**Grafana + Prometheus**](./grafana-prometheus/) | Collecte de métriques, tableaux de bord, node_exporter, reverse proxy Nginx | Ubuntu 22.04 |
| [**Zabbix 7.0 LTS**](./zabbix/) | Supervision complète (serveur, agent, interface web) en un script | Ubuntu 24.04 |
| [**Nagios Core**](./nagios/) | Supervision classique compilée depuis les sources | Ubuntu 22.04 |

### 🖥️ Virtualisation & haute disponibilité

| Projet | Description | Plateforme |
|---|---|---|
| [**Proxmox VE**](./proxmox/) | Hyperviseur dans Hyper-V avec virtualisation imbriquée (nested) | Hyper-V |
| [**Keepalived**](./keepalived/) | IP virtuelle (VRRP) avec basculement automatique entre 2 nœuds | Ubuntu 22.04 |

### 💼 Applications métier

| Projet | Description | Plateforme |
|---|---|---|
| [**Odoo 17**](./odoo/) | ERP complet : script d'installation + script de diagnostic automatique | Ubuntu 24.04 |
| [**OpenEMR**](./openemr/) | Dossier médical électronique sur pile LEMP (Nginx, MariaDB, PHP 8.3) | Ubuntu 24.04 |

## 🚀 Comment utiliser ce dépôt

1. **Choisissez un projet** dans les tableaux ci-dessus et ouvrez son `README.md`.
2. **Vérifiez les prérequis** (système, RAM, réseau) listés au début du guide.
3. **Suivez les étapes dans l'ordre** : chaque commande est copiable, chaque étape est illustrée.
4. **Adaptez les valeurs d'exemple** : tout ce qui est écrit `CHANGEME` ou `example.com` doit être remplacé par vos propres valeurs.

Pour les projets avec scripts (Odoo, Zabbix) :

```bash
git clone https://github.com/Cratosaris/homelab-infra-guides.git
cd homelab-infra-guides/odoo/scripts
chmod +x install_odoo17.sh
sudo ./install_odoo17.sh
```

## 🗂️ Structure du dépôt

```text
.
├── grafana-prometheus/   # README.md + images-*/
├── ipfire/               # README.md + overview.md + images/
├── keepalived/           # README.md + uninstall/ + images/
├── nagios/               # README.md + images/
├── odoo/                 # README.md + scripts/ + images/
├── openemr/              # README.md + images/
├── pfsense/              # README.md + images/
├── proxmox/              # README.md + images/
└── zabbix/               # README.md + scripts/ + images/
```

## 🔒 Sécurité : à lire avant de déployer

- Les **mots de passe des guides sont des exemples** (`CHANGEME`). Ne les réutilisez jamais tels quels.
- Les identifiants **par défaut** de certains logiciels (pfSense, Zabbix, Grafana) sont publics : changez-les dès la première connexion.
- Ces guides ciblent un **laboratoire**. Avant une mise en production : activez HTTPS, limitez les accès par pare-feu et planifiez des sauvegardes.
- Aucun secret n'est stocké dans ce dépôt (le `.gitignore` bloque `.env`, clés, dumps, etc.). Si vous en trouvez un par erreur, ouvrez une *issue*.

## 🤝 Contribuer

Une faute, une commande obsolète, une amélioration ? Les *issues* et *pull requests* sont les bienvenues. Pensez à indiquer la version du système utilisée pour vos tests.

## 📄 Licence

Ce dépôt est publié sous licence [MIT](./LICENSE) : vous pouvez utiliser, copier et adapter ces guides et scripts librement, en conservant la mention de l'auteur. Ils sont fournis **sans garantie**.

## ⭐ Soutenir le projet

Si un guide vous a fait gagner du temps, laissez une étoile ⭐ sur le dépôt : c'est la meilleure façon de dire merci et d'aider d'autres personnes à le trouver.
