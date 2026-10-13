# ts-vetements

**Vêtements en objets pour FiveM (ESX)** : chaque vêtement devient un objet ox_inventory. On le retire, on le range,
on le donne, on le met dans un coffre, puis on le remet. Panneau « Tenue » en glisser-déposer dans l'inventaire,
aperçu du personnage en direct et 6 thèmes d'interface.

**Version 1.6.1** · ESX Legacy · ox_inventory 2.48.0 · illenium-appearance 5.7.0 · ox_lib

## Contenu du dépôt

| Dossier | Rôle |
|---|---|
| `cfx_ts_vetements` | La ressource : vêtements en objets, panneau Tenue, magasin, anti-duplication |
| `ox_inventory` | ox_inventory 2.48.0 modifié (thèmes, panneau Tenue, objets `vet_*`) |
| `illenium-appearance` | illenium-appearance 5.7.0 modifié (thèmes, correctifs de sécurité, intégration) |

## Installation rapide

1. Copiez les trois dossiers dans `resources` (remplacez votre `ox_inventory` et votre `illenium-appearance`).
2. Dans `server.cfg` :

```cfg
ensure ox_lib
ensure es_extended
ensure ox_inventory
ensure illenium-appearance
ensure cfx_ts_vetements
```

3. Redémarrez et vérifiez `[cfx_ts_vetements] version 1.6.1` dans la console F8.

Documentation complète : [`cfx_ts_vetements/README.md`](cfx_ts_vetements/README.md).
Thèmes de l'interface : [`ox_inventory/THEME.md`](ox_inventory/THEME.md).

## Licences

- `cfx_ts_vetements` : gratuit, **revente interdite** (voir [`LICENSE`](cfx_ts_vetements/LICENSE)).
- `illenium-appearance` : code d'origine sous MIT, modifications du pack sous la même licence que cfx_ts_vetements.
- `ox_inventory` : GPL‑3.0 (licence de ses auteurs, Overextended).

Merci à [Overextended](https://github.com/overextended/ox_inventory) et à
[iLLeniumStudios](https://github.com/iLLeniumStudios/illenium-appearance) pour leurs ressources.
