# Le langage visuel d'ETEA

Ce document est la référence pour tout ce qui sera ajouté à ETEA : widgets, panneaux, fonctionnalités, thèmes. Une nouvelle surface doit se construire avec les briques ci-dessous, sans inventer son propre style.

## L'idée

**Chaque surface est un hublot sur le monde.** Une carte n'est pas un rectangle avec du texte : c'est un morceau de ciel vivant, dessiné à la main, qui prend la couleur de ce qu'il montre et réagit à ce qu'on fait.

## Les cinq règles

1. **La couleur vient du contenu.** Pochette, appli, état de la machine : une carte ne choisit jamais sa couleur au hasard.
2. **La donnée devient image.** Avant d'afficher un chiffre, chercher ce qu'il peut faire bouger : un horizon, une orbite, des étoiles qui s'allument, une lune.
3. **Tout répond au geste.** Survol, clic et ouverture ont une réponse visible, et cette réponse arrive tout de suite.
4. **L'étoile à 4 branches est la seule forme signature.** Ouverture, fermeture, sélection, valeur d'un curseur : c'est toujours elle.
5. **Le quotidien est rapide, les moments rares prennent leur temps.** Une action répétée ne doit jamais faire attendre.

## Les briques

| Brique | Fichier | Rôle |
|---|---|---|
| Hublot | `modules/bar/HandCard.qml` | Le fond de toute carte : ciel vivant et trait à la main. Propriétés : `seed`, `tint`, `rise`, `alive` |
| Couleur du contenu | `modules/bar/ContentTint.qml` | Tire une couleur d'une image, ou donne une teinte fixe à un nom |
| Étoile | `modules/bar/Star.qml` | La forme signature, avec son halo |
| Masque en étoile | `modules/stage/StarMask.qml` | Toute apparition de carte ou de fenêtre |
| Entrée en scène | `modules/bar/Entrance.qml` | Le contenu arrive de haut en bas, un élément après l'autre |
| Éclat au clic | `modules/bar/StarRipple.qml` | La réponse à un clic |
| Icône | `modules/bar/Icon.qml` | Material Symbols Rounded, teintée |
| Curseur, interrupteur, ligne | `modules/bar/menus/` | `MenuSlider`, `MenuSwitch`, `MenuRow`, `StarLevel` |
| Réglages | `modules/settings/` | `SettingRow`, `SettingSlider`, `SettingChoice`, `SettingSwitch` |

## Les valeurs

Toute couleur, taille ou durée vient de `config/Theme.qml`. Aucune couleur écrite en dur dans un module, sauf une teinte d'état explicite. Le mouvement utilise `Theme.expressive`, une courbe qui dépasse légèrement sa cible avant de se poser, et la police est toujours `Theme.font`.

Un réglage modifiable va dans `config/Config.qml`, et il apparaît dans la page Réglages.

## Ajouter un widget

1. Créer le fichier dans `modules/widgets/`, avec un `HandCard` pour fond.
2. Passer `alive: Planet.pageEmpty` : rien ne s'anime quand personne ne regarde.
3. Choisir sa couleur avec `ContentTint` ou un état réel.
4. Chercher ce que la donnée peut faire bouger, avant d'écrire du texte.
5. L'ajouter à la table de `modules/widgets/Widgets.qml`, à `Config.widgets` et à la page Bureau des Réglages.

## Ajouter un thème

Ajouter une entrée dans `config/Planets.qml` : un nom, une phrase, trois couleurs de ciel, quatre couleurs de terrain et une lumière. La planète apparaît alors dans le système et dans les Réglages.

## Avant de valider une nouvelle surface

- Elle reste lisible sur les quatre planètes.
- Elle tient dans une petite fenêtre et sur un grand écran.
- Elle a un état vide, et il a du caractère.
- Elle s'arrête de s'animer quand elle n'est pas visible.
- Le texte reste en premier plan : le ciel reste un fond.
