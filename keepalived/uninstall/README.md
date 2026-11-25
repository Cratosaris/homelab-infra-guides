# 🧹 Désinstaller Keepalived et MariaDB (Ubuntu 22.04)

> Supprimez proprement Keepalived et MariaDB, par exemple pour repartir d'une machine propre après vos tests.

> ⚠️ **Attention : opération destructive.** Les commandes ci-dessous suppriment les **configurations** (et donc les données de MariaDB si vous les purgez). **Sauvegardez d'abord** tout ce qui compte, par exemple avec `mysqldump`.

**Prérequis** : un utilisateur avec les droits `sudo`.

## 1. Arrêter les services

```bash
sudo systemctl stop keepalived
sudo systemctl stop mariadb
```

## 2. Désinstaller les paquets

`--purge` supprime aussi les fichiers de configuration gérés par les paquets :

```bash
sudo apt-get remove --purge keepalived mariadb-server mariadb-client
```

## 3. Supprimer les configurations restantes

```bash
sudo rm -rf /etc/keepalived
sudo rm -rf /etc/mysql
```

> 🔎 Vérifiez bien le chemin avant d'appuyer sur Entrée : `rm -rf` ne demande aucune confirmation.

## 4. Nettoyer les paquets inutiles

```bash
sudo apt-get autoremove
sudo apt-get autoclean
```

## 5. Vérifier la désinstallation

```bash
sudo systemctl status keepalived
sudo systemctl status mariadb
```

Résultat attendu :

```text
Unit keepalived.service could not be found.
○ mariadb.service
     Loaded: masked (Reason: Unit mariadb.service is masked.)
     Active: inactive (dead)
     Status: "MariaDB server is down"
```

Si les services sont introuvables ou **masqués / inactifs**, la désinstallation est réussie.

---

⬅️ [Retour au guide Keepalived](../README.md) · [Accueil du dépôt](../../README.md)
