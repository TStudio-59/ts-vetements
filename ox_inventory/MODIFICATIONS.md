# Modifications apportées à ox_inventory

Ce dossier est une version modifiée d'**ox_inventory 2.48.0** (Overextended), distribuée avec cfx_ts_vetements.
Projet original : https://github.com/overextended/ox_inventory — licence GPL‑3.0 (voir `LICENSE` et `NOTICE.md`).
Ces modifications sont distribuées sous la même licence.

Tous les fichiers serveur sont identiques à la version officielle 2.48.0. Fichiers modifiés :

| Fichier | Modification |
|---|---|
| `client.lua` | Envoi du thème à l'interface (`envoyerTheme`), panneau « Sol » nommé, touche de l'inventaire qui ouvre la Tenue de cfx_ts_vetements quand il n'y a rien autour, HUD cachée pendant l'inventaire, correctif « jeter dans l'eau sans fond » (les déplacements restaient bloqués), points d'entrée `kiritoTenue`, `kiritoApercu`, `kiritoCouleur` et export `couleurJoueur`. |
| `data/items.lua` | Ajout des 14 objets `vet_*` à la fin du fichier (objets d'origine inchangés). |
| `web/images/vet_*.png` | Images des 14 objets vêtements. |
| `web/build/index.html` | Nouveau design : bloc `<style id="kirito-theme">`, script `kirito-theme-script`, polices. Le code compilé (`web/build/assets`) n'est pas modifié. |
| `locales/fr.json` | « Jeter » devient « Mettre au sol ». |

Détails du thème et réglages : voir `THEME.md`.
