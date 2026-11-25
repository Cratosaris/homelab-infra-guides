# 🚨 Nagios Core sur Ubuntu 22.04

![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-E95420?logo=ubuntu&logoColor=white)
![Nagios](https://img.shields.io/badge/Nagios%20Core-4.5.10-1B6EC2)
![Plugins](https://img.shields.io/badge/plugins-2.4.11-informational)
![Difficulté](https://img.shields.io/badge/difficulté-intermédiaire-yellow)

> Installez **Nagios Core**, la référence open source de la supervision, **compilé depuis les sources** : surveillez vos serveurs, services (HTTP, SSH, FTP, SMTP…) et recevez une alerte avant que vos utilisateurs ne remarquent la panne.

## 📑 Sommaire

1. [Présentation](#-présentation)
2. [Prérequis](#-prérequis)
3. [Étape 1 : Dépendances](#étape-1--installer-les-dépendances)
4. [Étape 2 : Compiler Nagios Core](#étape-2--compiler-et-installer-nagios-core)
5. [Étape 3 : Interface web et compte admin](#étape-3--interface-web-et-compte-administrateur)
6. [Étape 4 : Plugins](#étape-4--installer-les-plugins-nagios)
7. [Étape 5 : Démarrer le service](#étape-5--vérifier-et-démarrer-nagios)
8. [Étape 6 : Accéder à l'interface](#étape-6--accéder-à-linterface-web)
9. [Dépannage](#-dépannage)

## 🎯 Présentation

**Nagios Core** surveille en continu les hôtes et services que vous lui indiquez (CPU, disque, ports, services réseau…) et vous **alerte** en cas d'anomalie. Son interface web centralise l'état de toute votre infrastructure Linux et Windows, et il s'étend grâce à de nombreux plugins.

> 💡 La dernière version de Nagios Core n'est pas dans les dépôts d'Ubuntu 22.04 : on la **compile donc depuis les sources**.

## ✅ Prérequis

- Un serveur **Ubuntu 22.04** (VM ou physique)
- **2 Go de RAM** et 10 Go de disque
- Un accès `root` ou `sudo`, et une connexion Internet

> 🔎 Les commandes ci-dessous sont écrites pour `root`. Avec un utilisateur normal, ajoutez `sudo` devant.

## Étape 1 : Installer les dépendances

```bash
apt-get update -y
apt-get install -y wget unzip vim curl openssl build-essential libgd-dev \
  libssl-dev libapache2-mod-php php-gd php apache2
```

## Étape 2 : Compiler et installer Nagios Core

**1. Téléchargez et extrayez les sources**

```bash
wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.5.10.tar.gz
tar -xvzf nagios-4.5.10.tar.gz
cd nagios-4.5.10
```

> 📌 Vérifiez la dernière version sur [nagios.org](https://www.nagios.org/downloads/nagios-core/) et adaptez le numéro si besoin.

**2. Configurez la compilation**

```bash
./configure --with-httpd-conf=/etc/apache2/sites-enabled
```

Vous devez obtenir un résumé de configuration (extrait) :

```text
*** Configuration summary for nagios 4.5.10 ***:

 Nagios user/group:  nagios,nagios
 Install ${prefix}:  /usr/local/nagios
 HTML URL:           http://localhost/nagios/
```

**3. Compilez**

```bash
make all
```

**4. Créez l'utilisateur système et installez**

```bash
make install-groups-users
usermod -a -G nagios www-data
make install
```

**5. Installez le service, les permissions et la configuration d'exemple**

```bash
make install-daemoninit      # service systemd
make install-commandmode     # permissions du fichier de commandes
make install-config          # fichiers de configuration d'exemple
```

## Étape 3 : Interface web et compte administrateur

```bash
make install-webconf
a2enmod rewrite cgi
systemctl restart apache2
make install-exfoliation     # thème moderne de l'interface
```

Créez le compte qui se connectera à l'interface :

```bash
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
```

Saisissez un mot de passe **solide** (deux fois) :

```text
New password:
Re-type new password:
Adding password for user nagiosadmin
```

> 🔐 Ce fichier contient l'empreinte de votre mot de passe : il est exclu du dépôt par le `.gitignore` (`htpasswd.users`). Ne le publiez jamais.

## Étape 4 : Installer les plugins Nagios

Les plugins sont les « sondes » qui testent vos services.

```bash
cd ~
wget https://github.com/nagios-plugins/nagios-plugins/releases/download/release-2.4.11/nagios-plugins-2.4.11.tar.gz
tar -xvzf nagios-plugins-2.4.11.tar.gz
cd nagios-plugins-2.4.11
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make
make install
```

## Étape 5 : Vérifier et démarrer Nagios

Contrôlez d'abord la configuration :

```bash
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
```

Résultat attendu :

```text
Total Warnings: 0
Total Errors:   0

Things look okay - No serious problems were detected during the pre-flight check
```

Démarrez le service et activez-le au démarrage :

```bash
systemctl start nagios
systemctl enable nagios
systemctl status nagios
```

Vous devez voir `active (running)` :

```text
● nagios.service - Nagios Core 4.5.10
     Loaded: loaded (/lib/systemd/system/nagios.service; enabled)
     Active: active (running)
```

## Étape 6 : Accéder à l'interface web

Ouvrez votre navigateur :

```text
http://<IP-du-serveur>/nagios
```

Connectez-vous avec `nagiosadmin` et le mot de passe choisi à l'étape 3 :

![Connexion à Nagios](<images/loggin nagios.png>)

Le tableau de bord Nagios s'affiche :

![Tableau de bord Nagios Core](<images/nagios core 2025.png>)

🎉 **Félicitations**, Nagios Core est opérationnel ! Il ne reste qu'à ajouter vos propres hôtes à superviser.

## 🔧 Dépannage

| Symptôme | Solution |
|---|---|
| Page `/nagios` introuvable (404) | `a2enmod rewrite cgi` puis `systemctl restart apache2` |
| Erreur `403 Forbidden` ou authentification refusée | Vérifiez que `/usr/local/nagios/etc/htpasswd.users` existe et recréez l'utilisateur avec `htpasswd` |
| Nagios ne démarre pas | `/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg` pour localiser l'erreur de configuration |
| Voir les journaux | `journalctl -u nagios -f` ou `/usr/local/nagios/var/nagios.log` |
| Erreur de compilation `gd.h` introuvable | Installez `libgd-dev` (étape 1) |

## 🔒 Bonnes pratiques de sécurité

- [ ] Utiliser un mot de passe solide pour `nagiosadmin`
- [ ] Activer HTTPS avant toute exposition sur Internet
- [ ] Restreindre l'accès à l'interface par pare-feu
- [ ] Garder Nagios et ses plugins à jour

## 📖 Références

- [Documentation officielle Nagios Core](https://www.nagios.org/documentation/)
- [Téléchargements Nagios Core](https://www.nagios.org/downloads/nagios-core/)
- [Plugins Nagios](https://github.com/nagios-plugins/nagios-plugins)

---

⬅️ [Retour à l'accueil du dépôt](../README.md)
