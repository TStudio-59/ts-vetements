# Thème de l'apparence — illenium-appearance

Le menu d'apparence (magasin de vêtements, coiffeur, création du personnage) utilise **les mêmes thèmes
que l'inventaire**, réglés par les **mêmes lignes de `server.cfg`** :

```cfg
setr inventory:theme   "ombre"     # ombre | verre | liquide | neon | brut | clair
setr inventory:accent  "#4F8CFF"   # couleur principale (vide = celle du thème)
setr inventory:echelle "100"       # taille en %
setr inventory:couleurlibre "true" # la couleur choisie par le joueur dans l'inventaire est reprise ici
```

Changer de thème dans la console du serveur (`setr inventory:theme "liquide"`) s'applique à la prochaine
ouverture du menu, sans redémarrage.

## HUD cachée pendant le menu

Quand le menu d'apparence est ouvert (magasin de vêtements, coiffeur, tatoueur, création du personnage), la HUD est
cachée avec les mêmes règles que l'inventaire : toute la HUD de GTA, **esx_hud** automatiquement, les HUD qui écoutent
`kirito:inventaire`, et celles indiquées dans `inventory:hudexport` / `inventory:hudevent`
(voir `ox_inventory/THEME.md`). `setr inventory:cacherhud "false"` la laisse affichée.

## Fichiers modifiés

- `web/dist/index.html` : polices, bloc `<style id="kirito-theme">` (les 6 thèmes) et script `kirito-theme-script`.
  La base de mise en page (panneau à droite, colonne d'outils à gauche) reste le bloc `<style id="da-circuit">`.
- `game/customization.lua` : à l'ouverture du menu, envoi du thème à l'interface (repère « Thème « Kirito » ») ;
  HUD cachée pendant le menu (`cacherHud`).
- `client/client.lua` : menu des tenues en objets (voir cfx_ts_vetements).

La couleur du joueur est gardée par ox_inventory (`exports.ox_inventory:couleurJoueur()`).
Le code JavaScript compilé n'est pas modifié.

## Créer votre propre thème

Ajoutez un bloc `html.kt[data-theme="monserveur"] { ... }` dans `kirito-theme` (copiez celui d'`ombre`),
ajoutez le même nom dans `THEMES` du script en bas de `web/dist/index.html`, et faites pareil dans l'inventaire
(voir `ox_inventory/THEME.md`).

## Attention en cas de mise à jour d'illenium-appearance

Le style cible les éléments de cette version précise de l'interface (`index.b8e72b46.js`, classes `sc-…`).
Après une mise à jour, ces noms peuvent changer : il faudra réadapter le bloc de style.
