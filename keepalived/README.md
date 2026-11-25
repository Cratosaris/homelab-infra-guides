# 🔁 Keepalived : IP virtuelle et haute disponibilité (VRRP)

![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-E95420?logo=ubuntu&logoColor=white)
![Protocole](https://img.shields.io/badge/protocole-VRRP-informational)
![Difficulté](https://img.shields.io/badge/difficulté-facile-brightgreen)

> Faites en sorte que votre service reste joignable **même si un serveur tombe** : deux nœuds partagent une **adresse IP virtuelle (VIP)**. Si le serveur principal s'arrête, le serveur de secours reprend la VIP automatiquement.

## 📑 Sommaire

1. [Comment ça marche](#-comment-ça-marche)
2. [Prérequis](#-prérequis)
3. [Installer Keepalived](#1-installer-keepalived-sur-les-deux-nœuds)
4. [Nœud principal](#2-configurer-le-nœud-principal-node01)
5. [Nœud de secours](#3-configurer-le-nœud-de-secours-node02)
6. [Tester le basculement](#4-tester-le-basculement-et-le-retour-failback)
7. [Désinstaller](#-désinstaller)
8. [Dépannage](#-dépannage)

## 🧠 Comment ça marche

**Keepalived** utilise le protocole **VRRP** (*Virtual Router Redundancy Protocol*). Les deux nœuds échangent des messages ; celui qui a la **priorité la plus haute** (le MASTER) porte l'IP virtuelle. S'il disparaît, le BACKUP la récupère en quelques secondes.

```text
+----------------------+          |          +----------------------+
| node01 (MASTER)      |   VIP : 192.168.8.150   | node02 (BACKUP)     |
| 192.168.8.74         +----------+----------+  192.168.8.87        |
| Keepalived #1        |                     |  Keepalived #2       |
| priorité 200         |                     |  priorité 100        |
+----------------------+                     +----------------------+
```

Vos clients se connectent toujours à la **VIP** : ils ne voient jamais la panne.

## ✅ Prérequis

- **2 serveurs Ubuntu 22.04** sur le **même réseau** (VM Hyper-V par exemple)
- Un accès `root` ou `sudo` sur chacun
- Une **adresse libre dans le même sous-réseau** pour la VIP. Ici : `192.168.8.150`
- Le nom de l'interface réseau (`ip a` ; `eth0` dans ce guide)

> 📌 **Important** : la VIP doit appartenir au **même sous-réseau** que les adresses réelles des nœuds (ici `192.168.8.0/24`), sinon les clients ne pourront pas l'atteindre.

| Rôle | Nom | IP réelle | Priorité |
|---|---|---|---|
| Principal | `node01` | `192.168.8.74` | 200 |
| Secours | `node02` | `192.168.8.87` | 100 |
| Virtuelle | : | `192.168.8.150` | : |

## 1. Installer Keepalived sur les deux nœuds

À exécuter sur **node01 et node02** :

```bash
sudo apt update
sudo apt -y install keepalived
```

## 2. Configurer le nœud principal (node01)

```bash
sudo nano /etc/keepalived/keepalived.conf
```

```text
global_defs {
    router_id node01
}

vrrp_instance VRRP1 {
    # MASTER sur le nœud principal, BACKUP sur le nœud de secours
    state MASTER

    # Pour désactiver le retour automatique (failback) : mettre BACKUP + nopreempt sur les DEUX nœuds
    # nopreempt

    # Interface où l'IP virtuelle est ajoutée
    interface eth0

    # Même ID sur tous les nœuds de ce groupe VRRP
    virtual_router_id 101

    # Priorité : MASTER > BACKUP
    priority 200

    # Intervalle d'annonce VRRP (secondes)
    advert_int 1

    # (Recommandé) authentification entre les nœuds : même valeur sur les deux
    authentication {
        auth_type PASS
        auth_pass CHANGEME      # 8 caractères max, à remplacer
    }

    virtual_ipaddress {
        192.168.8.150/24
    }
}
```

```bash
sudo systemctl restart keepalived
sudo systemctl enable keepalived
ip address show eth0
```

La VIP doit apparaître sur l'interface :

```text
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 state UP
    inet 192.168.8.74/24 metric 100 brd 192.168.8.255 scope global dynamic eth0
    inet 192.168.8.150/24 scope global eth0
```

## 3. Configurer le nœud de secours (node02)

```bash
sudo nano /etc/keepalived/keepalived.conf
```

```text
global_defs {
    router_id node02
}

vrrp_instance VRRP1 {
    state BACKUP
    # nopreempt
    interface eth0
    virtual_router_id 101
    priority 100
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass CHANGEME      # identique à node01
    }

    virtual_ipaddress {
        192.168.8.150/24
    }
}
```

```bash
sudo systemctl restart keepalived
sudo systemctl enable keepalived
```

## 4. Tester le basculement et le retour (failback)

**a) Simuler une panne du nœud principal**

Sur `node01` :

```bash
sudo ip link set eth0 down
```

**b) Vérifier que node02 a pris la VIP**

Sur `node02` :

```bash
ip address show eth0
```

```text
    inet 192.168.8.87/24 metric 100 brd 192.168.8.255 scope global dynamic eth0
    inet 192.168.8.150/24 scope global eth0      ← la VIP est maintenant ici
```

**c) Rétablir node01 : retour automatique (failback)**

Sur `node01` :

```bash
sudo ip link set eth0 up
ip address show eth0
```

La VIP revient sur `node01`, car il a la priorité la plus haute (sauf si vous avez activé `nopreempt`).

> 💡 Pendant le test, lancez un `ping 192.168.8.150` depuis un autre poste : vous ne devriez perdre que quelques paquets lors de la bascule.

## 🧹 Désinstaller

Voir le guide dédié : [**uninstall/**](./uninstall/README.md).

## 🔧 Dépannage

| Symptôme | Solution |
|---|---|
| Les deux nœuds ont la VIP (*split-brain*) | Le trafic VRRP est bloqué entre eux : autorisez le protocole **112** ou vérifiez le pare-feu et le réseau |
| La VIP n'apparaît pas | `sudo systemctl status keepalived` ; `sudo journalctl -u keepalived -n 30` ; vérifiez le nom de l'interface (`eth0`) |
| Pas de basculement | Vérifiez que `virtual_router_id` et `auth_pass` sont **identiques** sur les deux nœuds |
| Sous Hyper-V, la VIP ne répond pas | Activez le **MAC address spoofing** sur la carte réseau des VM |
| Vérifier la config | `sudo keepalived -t -f /etc/keepalived/keepalived.conf` |

## 📖 Références

- [Documentation Keepalived](https://keepalived.readthedocs.io/)
- [Protocole VRRP (RFC 5798)](https://datatracker.ietf.org/doc/html/rfc5798)

---

⬅️ [Retour à l'accueil du dépôt](../README.md)
