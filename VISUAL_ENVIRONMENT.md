# ETEA SHELL — Environnement visuel et mécanismes

ETEA : *Exit The Earth Atmosphere*.

## Intention

> « Ce que je ressens dans ce shell, c'est le désir de quitter son monde pour en coloniser de nouveaux. »

ETEA SHELL doit aussi réunir une **communauté**. Il n'est donc pas conçu pour une seule machine, et il devient un nouveau but en tant que designer.

## Décisions validées pour la v1

- **Barre :** en haut, décalée du bord, sans aucun cadre : les éléments flottent sur le ciel. Elle réserve son espace aux fenêtres.
- **Gauche :** 6 pages en constellations. Chaque fenêtre ouverte est une étoile, reliée à la suivante. Les étoiles de la page active s'illuminent. Le nom et l'icône de l'appli apparaissent au survol.
- **Centre :** heure, date et média en cours, illuminés sur le ciel.
- **Droite :** informations système configurables, avec le minimum pour la v1.
- **Fenêtres :** elles occupent tout l'espace sous la barre. Le terrain se voit sur une page vide et pendant la rotation.
- **Changement de page :** la planète tourne, et les fenêtres suivent la courbe du sol.
- **Ouverture :** naissance d'une étoile à l'endroit de la fenêtre, révélée par le masque, et son étoile apparaît dans la barre.
- **Fermeture :** la fenêtre se referme en étoile, monte vers sa place dans la barre et s'y éteint.
- **Focus :** la fenêtre active s'illumine, sans soleil.
- **Rythme :** Quotidien par défaut, configurable.
- **Terrain :** généré, avec hauteur et relief réglables, sans décorations. Les calques pour le parallaxe et les widgets viendront en v1.1.
- **Ciel :** le dégradé et le grain de la maquette. Un widget affiche des PNG ou SVG dans le ciel, pour que chacun le décore sans limite.
- **Hublots :** chaque carte est un hublot sur un ciel vivant, dans un trait à la main doublé interrompu par des étoiles. Sa couleur vient du contenu, et les données font partie de l'image : horizon lié à la batterie et au volume, étoile qui longe le temps restant d'une notification, orbites pour le système.
- **Lanceur :** `Super + Espace`. Le ciel s'assombrit, la question « Où veux-tu aller ? » apparaît et les applis forment une constellation.
- **Notifications :** comètes qui arrivent du bord de l'écran, se posent et s'ouvrent. Le journal s'ouvre depuis la cloche, un clic droit active Ne pas déranger.
- **Menus de la barre :** calendrier, média, son, réseau, Bluetooth, énergie et luminosité.
- **Widgets :** cadran céleste, système et média, visibles sur une page vide. Sur une page vide, la musique dessine des courbes de niveau qui prolongent la crête des montagnes, sans déplacer le terrain, choisis dans `Config.widgets`.
- **Icônes :** Material Symbols Rounded, version pleine.
- **Altitude :** l'orbite montre les pages, le système montre les thèmes.
- **Thèmes :** chaque thème est une planète. Installer un thème, c'est atterrir pour la première fois sur une nouvelle planète.

## À propos de ce document

Ce document liste tout ce qui doit exister dans le shell. Il décrit des **besoins**, jamais des formes : aucune barre, aucun dock et aucun menu n'est présupposé. Pour chaque élément, c'est toi qui décides de ce qu'il devient.

## Comment le remplir

- Chaque élément a un identifiant (`F01`, `E04`, `M12`…) pour qu'on puisse en parler précisément.
- Remplis les champs après les deux-points, avec autant de détails que tu veux.
- Si tu n'as pas encore d'idée, écris `à explorer`. Si un élément ne t'intéresse pas, écris `retiré`.
- Tu peux ajouter tes propres éléments, ou fusionner et supprimer ceux de cette liste.
- Tu peux répondre par un croquis ou une image : range-les dans `references/` et cite le nom du fichier.

**Priorités :** `Essentiel` = le shell n'est pas utilisable au quotidien sans lui. `Important` = il manquera vite. `Bonus` = il rend l'expérience unique, mais peut attendre.

**Ordre conseillé :** remplis d'abord la partie 1, car elle guide tout le reste. Passe ensuite aux éléments `Essentiel` des parties 2 à 4.

---

## Partie 1 — Fondations visuelles

Ce sont les règles communes à tout le shell.

### Identité

- **F01 · Univers :** quel monde visite-t-on ? Quelle est l'histoire ?
- **F02 · Sens du nom :** comment « sortir de l'atmosphère » se traduit-il concrètement à l'écran ?
- **F03 · Ressenti :** trois à cinq mots que l'utilisateur doit ressentir.
- **F04 · Ce qu'ETEA n'est pas :** ce qu'il faut absolument éviter.
- **F05 · Références :** images, films, jeux, livres, interfaces ou artistes qui t'inspirent.

### Style

- **F06 · Palette :** couleurs principales, couleurs d'accent, couleurs d'état (succès, alerte, erreur).
- **F07 · Variantes de couleurs :** une seule ambiance, un mode clair et sombre, ou des couleurs tirées du fond d'écran ?
- **F08 · Typographie :** Poppins pour tout le texte du shell.
- **F09 · Formes :** géométriques, organiques, angulaires, arrondies, irrégulières ?
- **F10 · Matières :** verre, papier, métal, encre, lumière pure, autre ?
- **F11 · Lumière et ombres :** d'où vient la lumière ? Les éléments brillent-ils, projettent-ils une ombre ?
- **F12 · Profondeur :** à plat, en couches, en perspective, en vraie 3D ?
- **F13 · Texture et grain :** surfaces propres, ou grain et imperfections visibles ?
- **F14 · Densité :** interface aérée et minimale, ou riche en détails ?

### Illustration

- **F15 · Style d'illustration :** vectoriel avec texture, réalisé dans Krita. Reste à définir : traits, couleurs, niveau de détail.
- **F16 · Personnage ou mascotte :** y en a-t-il un ? Quel est son rôle ?
- **F17 · Présence des illustrations :** décor de fond, objets d'interface, ou les deux ?
- **F18 · Interaction :** les illustrations réagissent-elles à la souris, au clavier, à la musique, à l'heure ?

### Mouvement et son

- **F19 · Caractère des animations :** lent, nerveux, fluide, mécanique, élastique, en apesanteur ?
- **F20 · Vitesse :** durées pour une petite réaction, une ouverture et une grande transition.
- **F21 · Logique d'apparition :** d'où viennent les éléments et où partent-ils ?
- **F22 · Mouvement au repos :** l'écran reste-t-il vivant quand on ne fait rien ?
- **F23 · Sons :** une identité sonore (clics, notifications, démarrage) ou le silence ?

---

## Partie 2 — Environnement visuel

Ce sont les éléments visibles à concevoir, indépendamment de leur fonction.

### Scène et bureau

#### E01 · Fond du bureau `Essentiel`
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### E02 · Évolution de la scène `Bonus`
Le fond peut changer selon l'heure, la météo, l'activité ou la batterie.
- **Ce qui change :** 
- **Animation :** 
- **Assets :** 

#### E03 · Bureau vide `Important`
Ce qu'on voit lorsqu'aucune fenêtre n'est ouverte : la scène seule, ou quelque chose de plus ?
- **Apparence :** 
- **Animation :** 
- **Assets :** 

### Fenêtres et applications

#### E04 · Cadre des fenêtres `Essentiel`
Coins, bordure, ombre, transparence, espace entre les fenêtres.
- **Fenêtre active :** 
- **Fenêtre inactive :** 
- **Assets :** 

#### E05 · Couleurs des applications `Important`
Le style donné aux applis et au terminal. Voir les limites dans la partie 5.
- **Apparence :** 

#### E06 · Curseur de la souris `Bonus`
- **Apparence :** 
- **Assets :** 

### Conteneurs et composants

#### E07 · Conteneurs `Essentiel`
Ce qui porte le contenu du shell. Ce n'est pas forcément un panneau rectangulaire.
- **Forme et matière :** 
- **Apparition et disparition :** 
- **Assets :** 

#### E08 · Composants d'interface `Essentiel`
Ils apparaissent partout, donc leur style compte beaucoup.

| Composant | Ta vision |
|---|---|
| Bouton | |
| Bouton icône | |
| Interrupteur (activé / désactivé) | |
| Réglette (volume, luminosité) | |
| Champ de texte | |
| Case à cocher | |
| Liste et élément de liste | |
| Onglets | |
| Menu contextuel | |
| Infobulle | |
| Barre ou anneau de progression | |
| Indicateur de chargement | |
| Barre de défilement | |
| Pastille de compteur | |
| Séparateur | |

#### E09 · États communs `Essentiel`
Comment un élément montre-t-il son état ?

| État | Ta vision |
|---|---|
| Normal | |
| Survol | |
| Appui | |
| Sélectionné ou actif | |
| Focus clavier | |
| Désactivé | |
| Chargement | |
| Erreur | |

### Icônes et illustrations de situation

#### E10 · Icônes système `Essentiel`
Son, réseau, batterie, bluetooth, alimentation, etc.
- **Style :** 
- **Assets :** 

#### E11 · Icônes d'applications `Bonus`
Garder celles de chaque appli, leur appliquer un traitement, ou en dessiner certaines ?
- **Approche :** 
- **Assets :** 

#### E12 · Illustrations de situation `Important`
Ces images remplacent un écran vide ou un simple message.

| Situation | Ta vision |
|---|---|
| Aucune notification | |
| Aucun résultat de recherche | |
| Pas de réseau | |
| Rien en cours de lecture | |
| Batterie faible | |
| Erreur | |

---

## Partie 3 — Informations à rendre visibles

Sans barre, chaque information doit trouver sa propre place. Pour chacune, précise si elle est **permanente**, **à la demande** ou **seulement quand c'est utile**, puis comment elle s'affiche.

| ID | Information | Priorité | Visibilité | Ta vision |
|---|---|---|---|---|
| I01 | Heure | `Essentiel` | | |
| I02 | Date | `Important` | | |
| I03 | Espace de travail actif | `Essentiel` | | |
| I04 | Applications ouvertes | `Essentiel` | | |
| I05 | Fenêtre active | `Important` | | |
| I06 | Batterie et charge | `Essentiel` | | |
| I07 | Réseau | `Essentiel` | | |
| I08 | Bluetooth | `Important` | | |
| I09 | Volume | `Essentiel` | | |
| I10 | Luminosité | `Important` | | |
| I11 | Lecture en cours | `Important` | | |
| I12 | Notifications non lues | `Essentiel` | | |
| I13 | Mode Ne pas déranger | `Important` | | |
| I14 | Micro ou caméra en cours d'utilisation | `Important` | | |
| I15 | Enregistrement d'écran en cours | `Important` | | |
| I16 | Applis en arrière-plan | `Important` | | |
| I17 | Disposition du clavier | `Bonus` | | |
| I18 | Météo | `Bonus` | | |
| I19 | Processeur, mémoire, température | `Bonus` | | |
| I20 | Mises à jour disponibles | `Bonus` | | |

---

## Partie 4 — Mécanismes

Ce sont les actions que le shell doit permettre. Pour chacune, décris ce que tu veux vivre.

Champs à remplir pour chaque mécanisme :

- **Déclenchement :** raccourci, geste, zone de l'écran, automatique ?
- **Apparence :** ce qu'on voit.
- **Animation :** comment ça arrive, réagit et disparaît.
- **Assets :** ce que tu dois produire.

### Lancer et se déplacer

#### M01 · Lancer une application `Essentiel`
À prévoir : recherche, résultats, applis fréquentes, aucun résultat.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M02 · Passer d'une application à l'autre `Essentiel`
À prévoir : aperçus, sélection au clavier, plusieurs fenêtres d'une même appli.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M03 · Changer d'espace de travail `Essentiel`
À prévoir : aller à un espace, y envoyer une fenêtre, transition entre espaces.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M04 · Tout voir d'un coup `Important`
À prévoir : tous les espaces et leurs fenêtres, déplacement de fenêtres, ouverture directe.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M05 · Recherche universelle `Bonus`
À prévoir : fichiers, calculs, commandes, émojis, recherche web.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

### Être informé

#### M06 · Recevoir une notification `Essentiel`
À prévoir : image, actions, urgence, plusieurs notifications à la suite.
- **Déclenchement :** automatique
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M07 · Consulter les notifications `Essentiel`
À prévoir : historique, regroupement, suppression, liste vide.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M08 · Retour instantané `Essentiel`
La réaction visible quand on change le volume ou la luminosité, ou quand on active Verr. Maj.
- **Déclenchement :** automatique
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M09 · Alertes système `Important`
À prévoir : batterie faible, batterie critique, chargeur branché, connexion perdue ou retrouvée.
- **Déclenchement :** automatique
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M10 · Calendrier et agenda `Bonus`
À prévoir : mois, événements, rappels.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

### Contrôler le système

#### M11 · Contrôles rapides `Essentiel`
À prévoir : volume, luminosité, Ne pas déranger, lumière nocturne, mode d'alimentation.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M12 · Gérer le réseau `Essentiel`
À prévoir : liste des réseaux, force du signal, mot de passe, échec de connexion.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M13 · Gérer le Bluetooth `Important`
À prévoir : appareils, appairage, batterie des appareils.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M14 · Gérer le son `Important`
À prévoir : sorties et entrées audio, volume par application.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M15 · Lecture média `Important`
À prévoir : pochette, lecture, pause, piste suivante, progression, réaction à la musique.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M16 · Applis en arrière-plan `Important`
À prévoir : leurs icônes et leurs menus.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

### Sécurité et session

#### M17 · Écran de verrouillage `Essentiel`
À prévoir : attente, saisie du mot de passe, vérification, erreur, déverrouillage.

La même scène sert à la connexion et au verrouillage.

- **Déclenchement :** la première page montre seulement l'image de fond, sans texte. Une touche révèle la seconde page. Après une période d'inactivité, on retourne au fond avec le mouvement inverse : la femme redescend et l'étoile se referme.
- **Apparence :** la seconde page est un ciel étoilé. Une femme de dos tend la main comme pour se protéger de la lumière. Elle est au premier plan et floue ; sa main, derrière elle, est nette et passe devant les étoiles. Les étoiles apparaissent dans une zone en arc de cercle autour de l'épaule, assez proches les unes des autres pour que la main bouge peu. Un lien fin relie chaque étoile à la suivante, dans l'ordre d'apparition. Les actions de connexion sont réparties en bas à gauche et en bas à droite. Aucune validation n'est visible. La sélection d'utilisateur est retirée de la première version.
- **Animation :** un masque en forme d'étoile à 4 branches part du centre et s'agrandit très rapidement pour révéler la seconde page. La femme et la main arrivent du bas de l'écran dans un mouvement lisse, lent-rapide-lent. À chaque touche, une étoile apparaît et brille, et le bras tourne autour de l'épaule pour la cacher avec la main. À la touche suivante, la main va vers la nouvelle étoile et la précédente baisse légèrement. Pour effacer, la main repart dans le sens inverse.
- **Validation :** la touche Entrée valide. Si le mot de passe est faux, les étoiles disparaissent et on recommence. S'il est correct, on arrive directement sur le bureau.
- **Compte bloqué :** le ciel s'assombrit et un compte à rebours s'affiche.
- **Verr. Maj :** les étoiles brillent davantage.
- **Assets :** ciel étoilé, étoile et sa lueur, corps de la femme, bras et main séparés du corps, icônes des actions, forme de l'étoile du masque.
- **Règles de sécurité :** la position d'une étoile ne dépend jamais de la touche tapée. Entrée sur un champ vide ne fait rien. Le retour au fond efface la saisie. La touche qui révèle la seconde page et celles tapées pendant la transition comptent dans le mot de passe.
- **À tester :** durée du masque (départ à 300 ms), lisibilité de Verr. Maj avec une seule étoile, compte à rebours avec un vrai blocage.

#### M18 · Menu de session `Essentiel`
À prévoir : verrouiller, déconnecter, veille, redémarrer, éteindre, confirmation.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M19 · Demande d'autorisation `Important`
Quand une appli demande ton mot de passe pour une action sensible.
- **Déclenchement :** automatique
- **Apparence :** 
- **Animation :** 
- **Assets :** 

### Moments forts

#### M20 · Démarrage de l'ordinateur `Bonus`
Ce qu'on voit avant d'arriver à la connexion.
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M21 · Écran de connexion `Essentiel`
Pas d'écran distinct : la connexion automatique de SDDM ouvre la session, puis la scène `M17` s'affiche. L'image de la première page sera configurable dans les réglages.

#### M22 · Arrivée sur le bureau `Bonus`
La séquence d'ouverture une fois la session lancée.
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M23 · Veille et réveil `Bonus`
- **Mise en veille :** 
- **Réveil :** 
- **Assets :** 

#### M24 · Inactivité `Bonus`
Ce qui se passe quand personne ne touche à l'ordinateur.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M25 · Extinction `Bonus`
La séquence de fin avant que l'écran s'éteigne.
- **Apparence :** 
- **Animation :** 
- **Assets :** 

### Outils

#### M26 · Capture d'écran `Important`
À prévoir : zone, fenêtre, écran entier, confirmation.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M27 · Enregistrement d'écran `Bonus`
À prévoir : démarrage, durée, arrêt.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M28 · Presse-papiers `Important`
À prévoir : historique, textes et images, recherche.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M29 · Changer d'ambiance `Important`
À prévoir : choix du fond ou du thème, aperçu, transition.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M30 · Réglages du shell `Important`
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

#### M31 · Aide et raccourcis `Important`
Sans barre ni dock, il faut un moyen de découvrir les commandes.
- **Déclenchement :** 
- **Apparence :** 
- **Animation :** 
- **Assets :** 

### Comportements particuliers

#### M32 · Plein écran et jeux `Essentiel`
Que devient le shell ? Quelles alertes restent visibles ?
- **Comportement :** 

#### M33 · Écrans multiples et tailles différentes `Essentiel`
Que se passe-t-il avec un second écran, ou un écran plus grand, plus dense, ultralarge ou vertical ?
- **Comportement :** 

#### M34 · Première utilisation `Essentiel`
Comment une nouvelle personne découvre-t-elle ETEA et ses commandes ?
- **Apparence :** 
- **Animation :** 
- **Assets :** 

---

## Partie 5 — Limites à connaître

Ces limites ne doivent pas brider tes idées : décris ce que tu veux, et on trouvera la meilleure solution ensemble.

**Ce qui est très libre**

- Le shell n'est pas obligé d'être rectangulaire ni collé aux bords. Il peut utiliser des formes libres, de la transparence et des zones où les clics traversent.
- Il peut afficher des illustrations, des animations et des effets visuels sur mesure.

**Ce qui dépend d'un autre outil**

| Élément | Outil concerné | Conséquence |
|---|---|---|
| E04 Cadre des fenêtres | Hyprland | Coins, bordures, ombres, flou et animations sont réglables. Un cadre illustré reste à valider techniquement. |
| E05 Applications | Chaque appli | Le shell ne redessine pas leur contenu. On peut appliquer des couleurs et un thème à beaucoup d'entre elles. |
| M20 Démarrage | Système | Cette étape se passe avant Hyprland et demande un outil séparé. |
| M21 Connexion | Système | Elle se passe aussi avant la session et demande une configuration séparée. |

**Ce qui demande de la prudence**

- **Performance :** ta machine sert de référence, avec un écran 1920×1080 à 60 Hz et une carte graphique intégrée. Les grandes animations plein écran doivent s'arrêter lorsqu'elles ne sont pas visibles.
- **Diversité des machines :** la communauté aura d'autres écrans et d'autres cartes graphiques. Aucune composition ne doit dépendre d'une seule taille d'écran.
- **Lisibilité :** le texte doit rester lisible sur chaque illustration.
- **Rapidité :** une action répétée cent fois par jour, comme changer d'appli, doit rester instantanée. Les grandes animations sont faites pour les moments rares.

---

## Partie 6 — Assets à produire

### Formats conseillés

| Type d'asset | Format | Remarque |
|---|---|---|
| Illustration | SVG pour les formes | Exporter chaque partie mobile à part, et garder de la marge sur les côtés pour les formats plus larges |
| Texture | PNG répétable en niveaux de gris | Séparée du SVG : le shell la répète sans l'étirer, pour qu'elle reste nette en 4K |
| Icône | SVG | Formes simples |
| Animation dessinée | Planche de sprites | Bon contrôle image par image |
| Animation vectorielle | Lottie | Support installé, à tester dans Quickshell |
| Grand fond animé | Vidéo ou shader | À choisir selon le rendu et la performance |

### Effets SVG testés avec Qt 6.12

- **Rendus correctement :** dégradés, contours, masques, flou gaussien.
- **Ignorés :** bruit `feTurbulence`, modes de fusion `mix-blend-mode`.
- **Image intégrée au SVG :** elle s'affiche, mais se pixellise quand on agrandit le SVG.

### Inventaire

Ce tableau se remplira au fil de tes descriptions.

| ID | Asset | Lié à | Type | Dimensions | État |
|---|---|---|---|---|---|
| A001 | | | | | à faire |

---

## Partie 7 — Communauté

Ce qui devient nécessaire dès que d'autres personnes utilisent ETEA.

| ID | Besoin | Priorité | Ta vision |
|---|---|---|---|
| C01 | Nom et logo : vérifier que le nom est disponible, dessiner l'identité | `Essentiel` | |
| C02 | Page du projet : présentation, vidéo, captures | `Essentiel` | |
| C03 | Installation | `Essentiel` | |
| C04 | Mises à jour, y compris quand Hyprland change | `Essentiel` | |
| C05 | Licences : une pour le code, une autre pour tes illustrations | `Essentiel` | |
| C06 | Personnalisation : ce que chacun peut modifier | `Important` | |
| C07 | Langues de l'interface | `Important` | |
| C08 | Guide de contribution : code et design | `Important` | |
| C09 | Lieu de la communauté | `Important` | |
| C10 | Première présentation publique | `Important` | |
| C11 | Mondes créés par la communauté : ouverts, sélectionnés ou réservés à toi | `Bonus` | |
