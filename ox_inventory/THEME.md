# Thème de l'inventaire — ox_inventory

L'interface a été entièrement redessinée :

- **Poches à gauche**, **personnage au centre**, **coffre / sol à droite**. Le personnage reste au milieu de l'écran.
- **Tenue** (touche de l'inventaire sans rien autour) : les vêtements en colonne à gauche du personnage
  (chapeau, veste, t-shirt, gilet, pantalon, chaussures) et les accessoires à droite
  (masque, lunettes, oreilles, chaîne, bracelet, montre, sac).
- **Titre** au-dessus de chaque grille (nom du joueur, « Par terre », nom du coffre) avec le poids à droite.
- **Filtres** dans une barre verticale sur le côté de chaque grille : Tout, Armes, Vêtements, Divers
  (les autres objets sont estompés).
- **Raccourcis 1 à 5** : petit numéro dans le coin, liseré de couleur en bas.
- **Tenue** : cases carrées sombres avec une icône au trait, sans texte (le nom apparaît au survol).
  Vêtements à gauche du personnage (chapeau, t-shirt, veste, gilet, pantalon, chaussures),
  accessoires à droite (masque, lunettes, oreilles, chaîne, montre, bracelet), et en bas le sac
  et la case **« Tenue complète »** : déposez-y un objet Tenue pour l'enfiler d'un coup ; elle y reste tant que
  vous la portez, et la glisser vers vos poches retire toute la tenue en un seul objet.
- **Barre du bas** : quantité, Utiliser, Donner, Fermer, et la pastille de couleur du joueur.

Seul `web/build/index.html` porte le design (bloc `<style id="kirito-theme">` et script `kirito-theme-script`).
Le code compilé (`web/build/assets`) n'est pas touché.

---

## Régler le thème dans `server.cfg`

Ajoutez ces lignes **avant** `ensure ox_inventory`. Il faut `setr` (et pas `set`) pour que les joueurs reçoivent la valeur.

```cfg
# Thème : ombre | verre | liquide | neon | brut | clair
setr inventory:theme "ombre"

# Couleur principale en hexadécimal. Vide = couleur par défaut du thème.
setr inventory:accent "#4F8CFF"

# true : chaque joueur peut choisir sa couleur (pastille en bas). false : couleur du serveur imposée.
setr inventory:couleurlibre "true"

# Taille de l'interface en % (60 à 140)
setr inventory:echelle "100"

# Conseillé avec ce design : pas de flou sur le jeu quand l'inventaire est ouvert
setr inventory:screenblur "false"
```

Changement à chaud : tapez par exemple `setr inventory:theme "neon"` dans la console du serveur.
Le nouveau thème s'applique à la prochaine ouverture de l'inventaire, sans redémarrage.

#### Cacher la HUD quand l'inventaire est ouvert

```cfg
setr inventory:cacherhud "true"                 # false : la HUD reste affichée
setr inventory:hudexport "ma_hud:toggleHud"     # export de votre HUD qui l'affiche / la cache (reçoit true / false)
setr inventory:hudevent  ""                     # ou un événement client de votre HUD (reçoit true / false)
```

La mini-carte de GTA est cachée automatiquement. Les jauges (faim, soif…) viennent de votre ressource de HUD :
indiquez son export ou son événement ci-dessus. Pour une HUD faite maison, écoutez l'événement client
`kirito:inventaire` (true = inventaire ouvert). **modern_hud** le fait déjà (version 2.1.1) : rien à régler.

## Les 6 thèmes

| Nom | Style | Couleur par défaut |
|---|---|---|
| `ombre` | Cases carrées gris fumé posées directement sur le jeu, sans panneau (par défaut) | bleu `#4F8CFF` |
| `verre` | Panneaux givrés translucides, coins arrondis, textes en minuscules | lavande `#7C9CFF` |
| `liquide` | Verre liquide : cases translucides épaisses, reflets blancs sur les bords, coins très ronds, liseré irisé, boutons en pilule, cadre du personnage en capsule | bleu `#0A84FF` |
| `neon` | Fond nuit, contours et lueurs de la couleur principale | cyan `#22D3EE` |
| `brut` | Panneaux noirs pleins, angles vifs, police condensée | rouge `#DC2626` |
| `clair` | Cases blanches laiteuses, textes sombres | bleu `#2563EB` |

Si le nom du thème est inconnu, `ombre` est utilisé. Si la couleur n'est pas au format `#RRGGBB`,
la couleur du thème est utilisée.

---

## Menu d'apparence (illenium-appearance)

Le magasin de vêtements, le coiffeur et la création du personnage suivent le même thème et la même couleur
(y compris la couleur choisie par le joueur). Voir `illenium-appearance/THEME.md`.

## Créer votre propre thème

1. Dans `web/build/index.html`, copiez un bloc `html[data-theme="..."] { ... }` (par exemple celui d'`ombre`).
2. Renommez-le, par exemple `html[data-theme="monserveur"]`, et changez les valeurs :
   - `--police`, `--police-titre` : polices (à charger dans la ligne Google Fonts en haut du fichier) ;
   - `--texte`, `--texte-2`, `--texte-3` : couleurs des textes (principal, secondaire, discret) ;
   - `--case-fond`, `--case-plein`, `--case-bord`, `--case-rayon` : cases vides, cases occupées, contour, arrondi ;
   - `--tenue-fond`, `--icone` : cases de la Tenue et leurs icônes ;
   - `--panneau`, `--panneau-bord`, `--panneau-rayon`, `--pad` : fond derrière les grilles (`transparent` et `0px` pour aucun) ;
   - `--menu-fond`, `--menu-bord`, `--menu-rayon` : infobulle et menu du clic droit.
3. Dans le script en bas du fichier, ajoutez le nom dans la liste `THEMES` avec sa couleur par défaut :
   `monserveur: '#FF6A00',`
4. Dans `server.cfg` : `setr inventory:theme "monserveur"`.

## Déplacer les cases de la Tenue

Les lignes `.tenue-mode .inventory-slot:nth-child(N) { left: ...; top: ...; }` placent chaque case.
`N` est le numéro de la catégorie dans `Config.Categories` de cfx_ts_vetements (1 = chapeau, 2 = lunettes…),
et 14 est la case « Tenue complète ». `top` compte en hauteurs de case :
`calc(2 * (var(--case) + var(--ecart)) + …)` = troisième rang. Les icônes des cases vides sont juste en dessous.

## Mesures

En haut du bloc de style (`:root`) : `--case` (taille d'une case), `--perso` (largeur du cadre du personnage),
`--centre` (espace entre les deux grilles). Le script lit les mêmes valeurs pour cadrer la caméra
du personnage : si vous changez `--case` (9.4), `--esp` (1.6) ou `--perso` (36), reportez-les dans la fonction
`marquer()` du script (`largeurCase`, `1.6 * u`, `36 * u`).

---

## Ce qui est conservé de l'ancienne version

- Panneau Tenue de cfx_ts_vetements (« Tout retirer » et « Créer une tenue » restent disponibles dans `/tenuemenu`) ;
- aperçu du personnage par caméra (la zone envoyée au jeu est le cadre entre les deux colonnes) ;
- clic droit sur un objet > **Mettre au sol** : l'objet est posé par terre, même avec la Tenue, un coffre ou un véhicule ouvert
  (la quantité tapée en bas est respectée, sinon toute la pile) ;
- couleur choisie par le joueur, mémorisée sur son PC (désactivable avec `inventory:couleurlibre "false"`).

L'ancienne colonne « Détail » est remplacée par l'infobulle qui suit la souris, et le grand titre
« INVENTAIRE » par la barre de filtres.

## Revenir à l'interface d'origine d'ox_inventory

Supprimez la ligne des polices Montserrat/Manrope…, le bloc `<style id="kirito-theme">` et le script
`kirito-theme-script` dans `web/build/index.html`, puis la fonction `envoyerTheme` et ses appels dans `client.lua`.

## Mise à jour d'ox_inventory

Après une mise à jour, recopiez `web/build/index.html` (bloc de style, script, ligne des polices),
la fonction `envoyerTheme()` de `client.lua` et ses appels (avant chaque `setupInventory` et après `init`),
les blocs marqués `cfx_ts_vetements` de `client.lua` et les objets `vet_*`.
