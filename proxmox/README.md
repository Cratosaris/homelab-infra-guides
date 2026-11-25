# 🖥️ Proxmox VE dans Hyper-V (virtualisation imbriquée)

![Hyper-V](https://img.shields.io/badge/Hyper--V-Génération%202-0078D4?logo=windows&logoColor=white)
![Proxmox](https://img.shields.io/badge/Proxmox-VE-E57000?logo=proxmox&logoColor=white)
![Nested](https://img.shields.io/badge/virtualisation-imbriquée-informational)
![Difficulté](https://img.shields.io/badge/difficulté-intermédiaire-yellow)

> Installez l'hyperviseur **Proxmox VE** à l'intérieur d'une machine virtuelle **Hyper-V** et faites tourner des VM *dans* la VM, grâce à la **virtualisation imbriquée** (*nested virtualization*). Idéal pour apprendre sans matériel dédié.

## 📑 Sommaire

1. [Prérequis](#-prérequis)
2. [Partie 1 : Préparer Hyper-V](#partie-1--préparer-la-vm-hyper-v-côté-windows)
3. [Partie 2 : Installer Proxmox](#partie-2--installer-proxmox-dans-la-vm)
4. [Partie 3 : Réseau en DHCP](#partie-3--passer-le-réseau-en-dhcp)
5. [Dépannage](#-dépannage)

## ✅ Prérequis

| Élément | Valeur recommandée |
|---|---|
| Hôte | Windows 10/11 Pro ou Windows Server avec **Hyper-V** activé |
| Génération de la VM | **Génération 2** (UEFI) |
| RAM | **4 Go minimum**, 8 Go recommandés pour faire tourner des VM |
| Processeurs | 2 vCPU ou plus |
| Disque | VHDX de 32 à 64 Go minimum (128 Go dans ce guide) |
| ISO | Proxmox VE, à télécharger sur le [site officiel](https://www.proxmox.com/en/downloads) |

## Partie 1 : Préparer la VM Hyper-V (côté Windows)

Créez d'abord la VM dans **Hyper-V Manager** (*New → Virtual Machine*) avec les paramètres du tableau ci-dessus, puis connectez l'ISO Proxmox comme lecteur CD/DVD virtuel. **Ne la démarrez pas encore.**

Ouvrez ensuite **PowerShell en administrateur** et exécutez ces commandes (adaptez `ProxMox` au nom de votre VM) :

```powershell
# 1) Activer la virtualisation imbriquée
Set-VMProcessor -VMName "ProxMox" -ExposeVirtualizationExtensions $true

# 2) Désactiver la mémoire dynamique et fixer 4 Go minimum
Set-VMMemory -VMName "ProxMox" -DynamicMemoryEnabled $false -StartupBytes 4GB

# 3) Activer le spoofing MAC (nécessaire pour le réseau des VM imbriquées)
Get-VMNetworkAdapter -VMName "ProxMox" | Set-VMNetworkAdapter -MacAddressSpoofing On

# 4) Désactiver Secure Boot (évite un blocage au démarrage de Proxmox)
Set-VMFirmware -VMName "ProxMox" -EnableSecureBoot Off
```

![Configuration PowerShell](<images/power shell confugurations.png>)

### Choisir le réseau

Dans **Hyper-V Manager** → paramètres de la VM → **Network Adapter** :

| Switch virtuel | Effet |
|---|---|
| **Default Switch** | IP en DHCP via Windows, Internet partagé (le plus simple) |
| **External Switch** | Proxmox obtient une IP dans le même réseau que votre PC |

> 💡 La mémoire dynamique doit être **désactivée** : les VM imbriquées fonctionnent mal avec elle.

## Partie 2 : Installer Proxmox dans la VM

Démarrez la VM : elle démarre sur l'installateur.

**1. Lancer l'installation.** Sélectionnez **Install Proxmox VE (Graphical)**.

![Menu de démarrage](<images/proxmos stet one .png>)

**2. Accepter la licence.** Lisez le contrat (EULA) puis acceptez pour continuer.

![Licence](<images/proxmox step tree.png>)

**3. Choisir le disque et le partitionnement.** Cliquez sur **Options** pour régler le système de fichiers et les tailles. Exemple pour un disque de **128 Go** et **8 Go de RAM** :

| Paramètre | Valeur | Rôle |
|---|---|---|
| `filesystem` | `ext4` | Simple, stable et performant dans Hyper-V |
| `hdsize` | `128` | Taille du disque utilisé |
| `swapsize` | `8` | Swap équivalent à la RAM (mettez `4` pour économiser de la place) |
| `maxroot` | `32` | Partition système (Proxmox + journaux) |
| `minfree` | `1` | Espace laissé libre (≈ 1 %) |
| `maxvz` | `~87` | Le reste, pour vos VM et conteneurs |

```text
+---------------------------------------------------+ 128 Go au total
| Système Proxmox VE                                | 32 Go  (maxroot)
+---------------------------------------------------+
| Swap (mémoire virtuelle)                          |  8 Go  (swapsize)
+---------------------------------------------------+
| Espace pour VM et conteneurs (LXC / KVM)          | ~87 Go (maxvz)
+---------------------------------------------------+
| Espace réservé                                    | ~1 Go  (minfree)
+---------------------------------------------------+
```

![Partitionnement](<images/Step four vrais partition.png>)

**4. Localisation.** Choisissez le pays, le fuseau horaire et la disposition du clavier (détectés automatiquement dans la plupart des cas).

![Fuseau horaire](<images/proxmox step five.png>)

**5. Compte administrateur.** Choisissez un mot de passe **fort** pour `root`, confirmez-le et saisissez une adresse e-mail pour les notifications.

![Mot de passe](<images/proxmox step six password.png>)

**6. Réseau.** Sélectionnez l'interface de gestion et renseignez le nom d'hôte, une adresse IP disponible, la passerelle et le DNS.

![Réseau](<images/proxmox step seven network.png>)

**7. Récapitulatif.** Vérifiez vos choix puis cliquez sur **Install**.

![Installation](<images/proxmox step nine installation.png>)

**8. Premier démarrage.** Après le redémarrage, choisissez **Proxmox VE GNU/Linux** dans le menu GRUB. La console affiche l'adresse pour accéder à l'interface web.

![Console Proxmox](<images/Proxmos console tara.png>)

**9. Se connecter.** Ouvrez l'adresse affichée dans un navigateur :

```text
https://<IP-du-serveur>:8006
```

Connectez-vous avec l'utilisateur `root` et le mot de passe défini à l'étape 5.

![Interface Proxmox](<images/proxmox interface graficas.png>)

**10. Message d'abonnement.** Une fenêtre indique qu'aucun abonnement n'est actif : c'est un service optionnel, cliquez simplement sur **OK**.

![Dialogue d'abonnement](<images/promox bingoo.png>)

🎉 **Félicitations**, Proxmox VE est installé !

## Partie 3 : Passer le réseau en DHCP

Si vous avez configuré une IP statique mais préférez le DHCP (cas du *Default Switch*), connectez-vous à la console de la VM (via Hyper-V) et éditez :

```bash
nano /etc/network/interfaces
```

Modifiez `vmbr0` pour utiliser `dhcp` au lieu de `static` :

```text
auto lo
iface lo inet loopback

iface eth0 inet manual

auto vmbr0
iface vmbr0 inet dhcp
        bridge-ports eth0
        bridge-stp off
        bridge-fd 0

source /etc/network/interfaces.d/*
```

![Réseau en DHCP](<images/proxmox cinfuguration networks.png>)

Enregistrez (`Ctrl+O`, `Entrée`, `Ctrl+X`) puis appliquez :

```bash
systemctl restart networking
```

(ou redémarrez avec `reboot`).

## 🔧 Dépannage

| Symptôme | Solution |
|---|---|
| La VM ne démarre pas sur l'ISO | Désactivez **Secure Boot** (commande n°4 de la partie 1) |
| Impossible de démarrer des VM dans Proxmox | Vérifiez `ExposeVirtualizationExtensions $true` et la mémoire dynamique désactivée |
| Les VM imbriquées n'ont pas de réseau | Activez le **MAC address spoofing** (commande n°3) |
| Proxmox bloqué par Windows | Désactivez *Memory Integrity / Core isolation* si elle empêche la virtualisation imbriquée |
| Interface web inaccessible | Utilisez bien **https** et le port **8006**, et vérifiez l'IP avec `ip a` dans la console |

## 🔒 Bonnes pratiques de sécurité

- [ ] Mot de passe `root` fort et unique
- [ ] Ne pas exposer le port **8006** sur Internet
- [ ] Mettre à jour Proxmox régulièrement (*Updates* dans l'interface)
- [ ] Activer l'authentification à deux facteurs pour `root@pam`

## 📖 Références

- [Documentation officielle Proxmox VE](https://pve.proxmox.com/pve-docs/)
- [Téléchargement de Proxmox VE](https://www.proxmox.com/en/downloads)
- [Virtualisation imbriquée sur Hyper-V (Microsoft)](https://learn.microsoft.com/fr-fr/virtualization/hyper-v-on-windows/user-guide/nested-virtualization)

---

⬅️ [Retour à l'accueil du dépôt](../README.md)
