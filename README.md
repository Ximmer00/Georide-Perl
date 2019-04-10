# GeoRide Perl

![Logo GeoRide](https://cdn.discordapp.com/attachments/476152053975089152/560858899503382528/logo_transparent_blanc.png)

> Projet pour la Licence MI ASSR, module mi4 (Perl)
>
> Mais aussi projet personnel et pour la communauté GeoRide.

## À quoi ça sert ?

Ce script perl permet de :

-   Voir l'état du tracker.
-   Verrouiller le tracker de sa moto,
-   Le déverouiller,
-   Localiser sa moto.

Pour cela il faut avoir un tracker ([Site de GeoRide](https://georide.fr/ "Site de GeoRide")) ou avoir un ami qui partage le sien.

La doc de l'utilisation de l'API ce trouve [ici](https://api.georide.fr "Doc de l'API").

## Utilisation

Installation des dépendances perl :

```
chmod +x ./pre_install.sh
./pre_install.sh
```

Lancement du script :

```
perl Script.pl
```

## Fonctionnement
Les identifiants (email et mot de passe) sont demandés, et vérifiés. Ils sont ensuite, selon le choix de l'utilisateur, stockés dans un fichier de config. Le token d'autorisation est chiffré pour le stockage.

Le script propose les différentes fonctions présentées auparavant.

## Contribution
Toute proposition d'amélioration est la bienvenue. Si vous rencontrez un problème ou souhaitez ajouter de nouvelles fonctionnalités, n'hésitez pas à envoyer une pull request.


### Futures améliorations
- [x] Intégration de l'affichage actuel de la moto
- [ ] Intégration du socketIO pour avoir des alertes en temps réel
- [ ] Amélioration de l'affichage sur google maps
- [ ] Ajout d'un mode verbeux


✌️ 🇫🇷 🏍️
