# GeoRide Perl

![Logo GeoRide](https://github.com/Ximmer00/Georide-Perl/blob/master/logo_transparent.png)

> Projet pour la Licence MI ASSR, module mi4 (Perl), projet personnel et projet pour la communauté GeoRide.

## À quoi ça sert ?

Ce script perl permet de :

-   Voir l'état du tracker
-   Verrouiller le tracker de sa moto
-   Le déverouiller
-   Localiser sa moto

## Utilisation

Pour utiliser le script, il faut avoir un tracker ([Site de GeoRide](https://georide.fr/ "Site de GeoRide")) ou avoir un ami qui partage le sien.

Installation des dépendances perl :

```
chmod +x ./pre_install.sh
./pre_install.sh
```

Lancement du script :

```
perl Script.pl
```
Pour comprendre le fonctionnement voici la documentation de l'utilisation de l'API se trouve [ici](https://api.georide.fr "Doc de l'API").

## Fonctionnement
Les identifiants (email et mot de passe) sont demandés, et vérifiés. Ils sont ensuite, selon le choix de l'utilisateur, stockés dans un fichier de config. Le token d'autorisation est chiffré pour le stockage.

Le script propose les différentes fonctions présentées auparavant.

## Contribution
Toute proposition d'amélioration est la bienvenue. Si vous rencontrez un problème ou souhaitez ajouter de nouvelles fonctionnalités, n'hésitez pas à envoyer une pull request.


### Futures améliorations
- [x] Intégration de l'affichage actuel de la moto
- [ ] Ajout de la gestion pour plusieurs trackers
- [ ] Intégration du socketIO pour avoir des alertes en temps réel
- [ ] Ajout d'un mode verbeux
- [ ] Ajout du support de langue


✌️ 🇫🇷 🏍️
