# Modifications apportées à illenium-appearance

Ce dossier est une version modifiée d'**illenium-appearance 5.7.0** (snakewiz & iLLeniumStudios),
distribuée avec cfx_ts_vetements. Projet original : https://github.com/iLLeniumStudios/illenium-appearance —
licence MIT (voir `LICENSE`).

## Correctifs de sécurité

| Faille d'origine | Correctif (`server/server.lua` sauf mention) |
|---|---|
| N'importe quel joueur pouvait modifier, supprimer ou partager la tenue d'un autre joueur. | Vérification du propriétaire (`playerOwnsOutfit`). |
| N'importe quel joueur pouvait créer ou supprimer les tenues d'un métier ou d'un gang. | Réservé au patron du métier / gang (`canManageOutfits`). |
| Le prix d'un tatouage était envoyé par le client. | Prix lu dans `shared/tattoos.lua` côté serveur. |
| Un achat de vêtements pouvait changer le modèle du personnage. | Le magasin refuse un changement de modèle. |
| Payer échouait mais les habits restaient portés. | Apparence enregistrée remise si le paiement échoue. |
| (QBCore) N'importe quel joueur pouvait réécrire l'apparence de n'importe quel personnage via l'événement de migration. | Réservé à ceux qui ont le droit `/migrateskins` (`server/framework/qb/migrate.lua`). |
| Avec cfx_ts_vetements : l'apparence envoyée gratuitement par le client permettait de créer des vêtements à l'infini. | Les vêtements de l'apparence envoyée sont ignorés (`verrouillerVetements`, réglable avec `Config.VerrouVetements`). |

## Autres modifications

| Fichier | Modification |
|---|---|
| `server/server.lua` | Exports `getSavedAppearance` et `saveAppearanceFor`, achat en magasin `purchaseClothingItems` (les pièces remplacées reviennent en objets). |
| `server/framework/esx/main.lua` | `SaveAppearance` renvoie le résultat ; apparence vide (nouveau personnage) gérée sans erreur. |
| `server/database/managementoutfits.lua` | `GetByID` (contrôle des tenues de métier). |
| `client/client.lua` | Achat en magasin par `purchaseClothingItems`, menu « Enregistrer ma tenue » / « Retirer ma tenue » en objets. |
| `game/customization.lua` | Envoi du thème de l'inventaire à l'interface ; HUD cachée pendant le menu d'apparence. |
| `web/dist/index.html`, `shared/theme.lua` | Thèmes (voir `THEME.md`). Le code compilé n'est pas modifié. |
| `locales/fr.lua` | Traductions corrigées (« Modèle », « Accessoires », « Tatouages »…). |
| `shared/config.lua` | Noms des blips en français ; section « Ped » cachée à la création du personnage. |
