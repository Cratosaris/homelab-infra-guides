# 📘 IPFire : présentation

> Tout ce qu'il faut savoir sur IPFire avant de l'installer. Prêt à passer à la pratique ? Rendez-vous au [**guide d'installation**](./README.md).

## Qu'est-ce qu'IPFire ?

**IPFire** est un **pare-feu dédié** installable dans n'importe quel réseau, d'un centre de données jusqu'à votre domicile. Il est sécurisé, rapide et très polyvalent. En plus d'être un pare-feu à **inspection dynamique** (*stateful inspection*), il peut faire office de passerelle VPN, analyser les paquets grâce à son système de prévention des intrusions (**IPS**) et s'étendre avec de nombreux modules.

Il s'installe en quelques minutes et se configure via une **interface web**.

## Pour qui ?

IPFire est utilisé :

- dans les **centres de données**, en transférant des dizaines de gigabits par seconde,
- dans les **entreprises**, de quelques centaines d'employés aux télétravailleurs,
- comme **passerelle IoT** en environnement industriel,
- à la **maison**.

> 🎓 Quelques connaissances de base en réseau sont utiles. L'équipe d'IPFire encourage à prendre la sécurité au sérieux : tout est expliqué dans leur [wiki](https://wiki.ipfire.org/).

## Un système d'exploitation complet

IPFire est un système d'exploitation à part entière, **basé sur Linux** mais pas sur une distribution existante (Debian, Fedora...). Il est **durci** et optimisé pour son rôle de pare-feu. Chaque composant est sélectionné par les développeurs et compilé depuis les sources, souvent modifié pour améliorer la sécurité et réduire la surface d'attaque.

## Fonctionnalités principales

| Fonction | Ce qu'elle apporte |
|---|---|
| 🧱 **Pare-feu** | Facile mais puissant : groupes de réseaux, d'hôtes et de services pour écrire une seule règle applicable à de grandes parties du réseau. Limitation de débit et journalisation. |
| ⚡ **QoS** (qualité de service) | Attribue la bonne bande passante aux applications critiques (VoIP...) et limite les usages abusifs. |
| 🕵️ **IPS** (prévention d'intrusions) | Analyse en profondeur, compare à une base de signatures de malwares et détecte les comportements suspects. |
| 🌐 **Proxy web** | Filtre chaque client web, met le contenu en cache (y compris les mises à jour de systèmes d'exploitation), filtre les URL (très utilisé dans les écoles). |
| 🔐 **VPN** | Relie plusieurs sites via **IPsec** ou **OpenVPN**, jusqu'à 10 Gbit/s avec accélération cryptographique. Compatible avec Cisco, Juniper, Lancom... |
| 🧭 **DNS sécurisé** | Proxy DNS interne avec **DNSSEC**, cache des réponses et **DNS-over-TLS** vers les serveurs amont. |

## IPFire expliqué simplement

Imaginez IPFire comme une **boîte de sécurité** placée entre votre réseau et Internet. Elle :

- **filtre** ce qui entre et ce qui sort (pare-feu),
- **crée** des connexions sécurisées (VPN),
- **analyse** les attaques (IPS),
- **accélère** Internet et gère la bande passante (QoS),
- **bloque** les sites interdits ou dangereux (proxy + filtrage web),
- **sécurise** le DNS pour éviter les détournements (DNSSEC).

## Les zones réseau d'IPFire

IPFire organise le réseau en **zones de couleur** :

| Couleur | Zone | Usage |
|---|---|---|
| 🔴 **RED** | Internet / WAN | Côté externe, non fiable |
| 🟢 **GREEN** | LAN | Votre réseau interne de confiance |
| 🔵 **BLUE** | Wi-Fi | Réseau sans fil isolé *(optionnel)* |
| 🟠 **ORANGE** | DMZ | Serveurs exposés à Internet *(optionnel)* |

Le guide d'installation de ce dépôt utilise la configuration **GREEN + RED**, la plus simple.

## Après l'installation

Une fois IPFire installé, connectez-vous à l'interface web (`https://<IP-GREEN>:444`) avec l'utilisateur **`admin`**. Vous pourrez alors configurer :

- les **règles du pare-feu**
- le **proxy web**
- les **VPN**
- le **DNS sécurisé** (DNSSEC)
- l'**IPS**

## 📖 Références

- [Site officiel d'IPFire](https://www.ipfire.org/)
- [Wiki IPFire](https://wiki.ipfire.org/)

---

⬅️ [Retour au guide d'installation](./README.md) · [Accueil du dépôt](../README.md)
