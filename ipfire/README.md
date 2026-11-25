# 🔥 IPFire : installation pas à pas dans Hyper-V

![IPFire](https://img.shields.io/badge/IPFire-2.29%20Core%20198-red)
![Hyper-V](https://img.shields.io/badge/Hyper--V-Gen%201-0078D4?logo=windows&logoColor=white)
![Difficulté](https://img.shields.io/badge/difficulté-intermédiaire-yellow)

> Montez votre propre **pare-feu Linux durci** avec deux zones réseau (GREEN = interne, RED = Internet), puis administrez-le depuis une interface web. 📖 Pour comprendre ce qu'est IPFire et ce qu'il sait faire, lisez d'abord la [**présentation**](./overview.md).

## 📑 Sommaire

1. [Prérequis](#-prérequis)
2. [Préparer la machine virtuelle](#1-préparer-la-machine-virtuelle-hyper-v)
3. [Installer IPFire](#2-installer-ipfire)
4. [Configurer le réseau](#3-configurer-le-réseau-green--red)
5. [Accéder à l'interface web](#4-accéder-à-linterface-web)
6. [Dépannage](#-dépannage)

## ✅ Prérequis

| Élément | Valeur |
|---|---|
| Hyperviseur | Hyper-V (Windows 10/11 Pro ou Server) |
| Génération de la VM | **Génération 1** (recommandé pour IPFire) |
| RAM | 2048 Mo minimum |
| Disque | 20 Go ou plus |
| Cartes réseau | **2 minimum** (GREEN et RED) |
| ISO | IPFire 2.29 Core 198, x86_64 |

## 1. Préparer la machine virtuelle (Hyper-V)

### 1.1 Télécharger IPFire

Rendez-vous sur [ipfire.org](https://www.ipfire.org/) → **Download**, choisissez l'ISO **x86_64** et téléchargez-la.

### 1.2 Créer la VM

Dans **Hyper-V Manager** : **New → Virtual Machine**, puis :

- **Name** : `IPFire`
- **Generation** : Generation 1
- **Memory** : 2048 Mo
- **Virtual hard disk** : 20 Go ou plus
- **Installation media** : l'ISO IPFire téléchargée

### 1.3 Ajouter les deux cartes réseau

IPFire doit avoir **au moins deux cartes** :

| Zone | Rôle | Connecté à |
|---|---|---|
| 🟢 **GREEN** | Réseau interne (LAN, vos machines) | Switch virtuel **interne** |
| 🔴 **RED** | Réseau externe (Internet) | Switch virtuel **externe** (box, routeur 4G, carte Wi-Fi) |

Arrêtez la VM, ouvrez **Settings → Add Hardware → Network Adapter** et ajoutez la seconde carte.

![Ajout d'une seconde carte réseau](<images/add hardware networs two natwork.png>)

> 💡 Si vous utilisez un routeur ou une box, la carte **RED** doit être reliée à celui-ci.

## 2. Installer IPFire

Démarrez la VM. L'installateur est en mode texte : **pas de souris**. Utilisez les **flèches** pour naviguer et la **barre d'espace** pour sélectionner.

**1.** Sélectionnez **Install IPFire 2.29 – Core 198**.

![Menu de démarrage](<images/First ipfire.png>)

**2.** Choisissez la langue (ici *English*).

![Langue](<images/two ipfire.png>)

**3.** Un écran propose de démarrer l'installation : sélectionnez-le avec la barre d'espace, puis **OK**.

![Démarrage](<images/tree ipfire.png>)

**4.** Acceptez de **formater** la partition d'installation.

![Formatage](<images/four ipfire.png>)

**5.** Choisissez le système de fichiers **ext4**.

![ext4](<images/five ipfire.png>)

**6.** L'installation de base est terminée : redémarrez.

![Redémarrage](<images/six ipfire.png>)

**7.** Au redémarrage, choisissez la disposition du clavier (ici **qwerty**) puis **OK**.

![Clavier](<images/seven ipfire.png>)

**8.** Choisissez votre fuseau horaire (ici **Africa / Bujumbura**).

![Fuseau horaire](<images/eith ipfire.png>)

**9.** Saisissez le **nom d'hôte** de la machine, puis le **nom de domaine**.

![Nom d'hôte](<images/ipfire username.png>)
![Nom de domaine](<images/domain name.png>)

**10.** Définissez le **mot de passe de l'utilisateur `root`** (administration en ligne de commande), puis confirmez-le.

> ⚠️ Sous Linux, **rien ne s'affiche** pendant la saisie d'un mot de passe, pas même des astérisques. Tapez calmement et vérifiez que le verrouillage majuscule est bien désactivé.

![Mot de passe root](<images/password ipfire.png>)
![Confirmation](<images/a nother password ipfire.png>)

**11.** Répétez l'opération pour l'utilisateur **`admin`** : c'est lui qui se connectera à l'interface web.

> 🔐 Choisissez deux mots de passe **différents et solides**.

## 3. Configurer le réseau (GREEN + RED)

**1.** Sélectionnez **Network configuration type**.

![Type de configuration réseau](<images/ipfire network configurations.png>)

**2.** Choisissez **GREEN + RED**, puis **OK**.

**3.** Revenez au menu et sélectionnez **Drivers and cards assignments**.

![Attribution des cartes](<images/green and red  ipfire.png>)

**4.** Sélectionnez **GREEN**, puis **Select**, et choisissez la carte de votre réseau local (LAN).

![Interface GREEN](<images/interface green ipfire.png>)
![Choix de la carte GREEN](<images/shoose int green.png>)

**5.** Répétez l'opération pour **RED** avec la carte reliée à Internet (WAN), puis cliquez sur **Done**.

**6.** Sélectionnez **Address settings**, puis **GREEN** : saisissez l'adresse IP d'IPFire côté LAN et son masque de sous-réseau. Exemple utilisé dans ce guide : `192.168.60.1` / `255.255.255.0`.

![IP de GREEN](<images/green ip adresse.png>)

**7.** Pour **RED**, laissez le mode **DHCP** si IPFire est derrière une box (il obtient alors son adresse automatiquement). Sélectionnez l'option avec la **barre d'espace** (un `*` apparaît), puis **OK**.

![RED en DHCP](<images/red dhcp .png>)

**8.** Quand les deux interfaces sont configurées, validez avec **Done** (deux fois).

**9.** *Serveur DHCP* : cette étape sert à faire d'IPFire le serveur DHCP du LAN. Ici on ne l'active pas : descendez sur **OK** et validez.

![Serveur DHCP](<images/dhcp server localys.png>)

**10.** Le paramétrage est terminé : appuyez une dernière fois sur **Entrée** 🎉

![Configuration terminée](<images/set up compety.png>)

IPFire redémarre pour vérifier la configuration. Attendez l'invite de connexion :

![IPFire démarré](<images/true boom.png>)

## 4. Accéder à l'interface web

Depuis **un autre poste du réseau GREEN** (avec une IP fixe ou DHCP dans ce réseau), ouvrez un navigateur :

```text
https://192.168.60.1:444
```

> Remplacez `192.168.60.1` par l'adresse que vous avez donnée à l'interface GREEN. Le port est toujours **444**.

Le navigateur signale une connexion non sécurisée : c'est **normal** (certificat auto-signé). Cliquez sur **Avancé → Poursuivre vers l'IP**.

Connectez-vous avec l'utilisateur **`admin`** et le mot de passe défini à l'installation.

![Connexion](<images/id truly.png>)

Voici la page d'accueil d'IPFire :

![Interface IPFire](<images/interface ipfere 2025.png>)

Toutes les fonctionnalités (pare-feu, proxy, VPN, IPS, DNS...) sont accessibles via les **onglets en haut de la page**.

## 🔧 Dépannage

| Symptôme | Solution |
|---|---|
| Impossible d'atteindre `https://<IP>:444` | Votre poste est-il bien dans le réseau GREEN ? Testez `ping <IP-GREEN>` |
| Pas d'Internet depuis le LAN | Vérifiez que RED a reçu une IP (menu **Status**) et que la carte RED est sur le bon switch |
| Les cartes sont inversées | Relancez `setup` en console, **Drivers and cards assignments**, et réattribuez |
| Clavier mal configuré | Relancez `setup` et rechoisissez la disposition |

## 🔒 Bonnes pratiques de sécurité

- [ ] Mots de passe `root` et `admin` **différents** et solides
- [ ] Ne jamais exposer le port **444** côté RED (Internet)
- [ ] Appliquer les mises à jour (**System → Pakfire**)
- [ ] Activer l'IPS et sauvegarder la configuration (**System → Backup**)

## 📖 Références

- [Wiki officiel d'IPFire](https://wiki.ipfire.org/)
- [Site d'IPFire](https://www.ipfire.org/)

---

⬅️ [Retour à l'accueil du dépôt](../README.md)
