# cfx_ts_vetements — Vêtements en objets

**Version 1.6.2** · ESX Legacy · ox_inventory · illenium-appearance · ox_lib

Chaque vêtement devient un **objet d'inventaire**. On le retire, on le range dans ses poches, on le donne, on le jette,
on le met dans un coffre, puis on le remet sur soi. Une tenue complète peut aussi être rangée dans un seul objet.

L'inventaire affiche un **panneau « Tenue »** à côté de vos poches : les 13 emplacements de vêtements autour de votre
personnage, visible en direct. On s'habille et on se déshabille par glisser-déposer.

---

## Sommaire

1. [Fonctionnalités](#fonctionnalités)
2. [Dépendances](#dépendances)
3. [Installation](#installation)
4. [Utilisation en jeu](#utilisation-en-jeu)
5. [Réglages](#réglages-configlua)
6. [Ajouter ou modifier une catégorie](#ajouter-ou-modifier-une-catégorie)
7. [Sécurité](#sécurité)
8. [Pour les développeurs](#pour-les-développeurs)
9. [Dépannage](#dépannage)
10. [Limites connues](#limites-connues)
11. [Historique des versions](#historique-des-versions)

---

## Fonctionnalités

- **13 catégories de vêtements** : chapeau, lunettes, boucles d'oreilles, masque, chaîne, veste, t-shirt, gilet, sac,
  montre, bracelet, pantalon, chaussures. Chacune est un objet ox_inventory (`vet_*`).
- **Tenue complète** (`vet_tenue`) : tout ce que vous portez rangé dans un seul objet, qu'on remet d'un coup.
- **Tenues enregistrées en objets** : au magasin ou au vestiaire, « Enregistrer ma tenue » range tout ce que vous portez
  dans un objet nommé (« Tenue « Soirée » »). « Retirer ma tenue » la range à nouveau, en gardant son nom.
- **Panneau « Tenue » dans l'inventaire** : glissez un vêtement de vos poches vers la Tenue pour l'enfiler, glissez une
  pièce de la Tenue vers vos poches pour la retirer. La pièce se range toute seule dans la bonne case.
- **Aperçu du personnage** au centre de la Tenue : une caméra le filme de face, décor flouté. Chaque changement se voit.
- **Clic droit > Mettre au sol** sur un objet de vos poches, même Tenue ouverte.
- **Tout retirer / Créer une tenue** : dans le menu `/tenuemenu`.
- **Magasin de vêtements** (illenium-appearance) : vous portez ce que vous achetez, et les pièces remplacées reviennent
  dans votre inventaire (ou sont posées à vos pieds s'il est plein).
- **Utiliser un vêtement** (clic droit > Utiliser) marche aussi, avec l'animation d'habillage.
- **Contrôle serveur** : c'est le serveur qui fait chaque changement, jamais le client. Si une étape échoue,
  toute l'action est annulée (pas de vêtement en double).

---

## Dépendances

| Ressource | Rôle |
|---|---|
| `es_extended` (ESX Legacy) | framework |
| `ox_lib` | callbacks, menus, notifications, barres de progression |
| `ox_inventory` | objets, panneau Tenue (**version 2.48.0 modifiée fournie**) |
| `illenium-appearance` | apparence du personnage (**version 5.7.0 modifiée fournie**) |

Le pack contient des versions **déjà modifiées** d'`ox_inventory` et d'`illenium-appearance`. Si vous partez de vos
propres versions, les modifications à reporter sont détaillées aux étapes 3 et 4 ci-dessous, et chaque dossier
contient un fichier `MODIFICATIONS.md` qui liste les fichiers modifiés.

**Remplacer `ox_inventory` ne touche pas à vos objets** : `data/items.lua` du pack est celui d'origine plus les
14 objets `vet_*`. Si vous avez ajouté vos propres objets, gardez votre `data/items.lua` et ajoutez-y seulement
les lignes de l'étape 3a.

---

## Installation

### 1. Copier les ressources

Placez `cfx_ts_vetements` dans votre dossier `resources`, et remplacez `ox_inventory` et `illenium-appearance` par
ceux du pack.

### 2. `server.cfg`

L'ordre compte : `cfx_ts_vetements` doit démarrer **après** ses dépendances.

```cfg
# Langue française (inventaire et menu d'apparence)
setr ox:locale "fr"
setr illenium-appearance:locale "fr"

ensure ox_lib
ensure es_extended
ensure ox_inventory
ensure illenium-appearance
ensure cfx_ts_vetements
```

### 3. ox_inventory (déjà fait dans le pack)

Si vous utilisez votre propre ox_inventory, reportez ces éléments :

**a) Les 14 objets**, à la fin de `data/items.lua` (avant la dernière accolade) :

```lua
	-- Vêtements en objets (cfx_ts_vetements)
	['vet_chapeau'] = { label = 'Chapeau', weight = 150, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_lunettes'] = { label = 'Lunettes', weight = 50, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_oreilles'] = { label = 'Boucles d\'oreilles', weight = 20, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_masque'] = { label = 'Masque', weight = 150, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_chaine'] = { label = 'Chaîne', weight = 50, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_veste'] = { label = 'Veste', weight = 800, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_tshirt'] = { label = 'T-shirt', weight = 200, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_gilet'] = { label = 'Gilet', weight = 1500, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_sac'] = { label = 'Sac', weight = 500, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_montre'] = { label = 'Montre', weight = 100, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_bracelet'] = { label = 'Bracelet', weight = 50, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_pantalon'] = { label = 'Pantalon', weight = 500, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_chaussures'] = { label = 'Chaussures', weight = 700, stack = false, close = true, consume = 0, description = 'Utilisez-le pour le porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
	['vet_tenue'] = { label = 'Tenue', weight = 2500, stack = false, close = true, consume = 0, description = 'Utilisez-la pour la porter.', client = { export = 'cfx_ts_vetements.utiliser' } },
```

**b) Les 14 images** `vet_*.png` dans `web/images/`.

**c) `client.lua`** : les blocs marqués `cfx_ts_vetements` :
- dans le raccourci `inv` (touche de l'inventaire) : sans rien autour, il ouvre la Tenue au lieu du sol ;
- `defaultInventory` avec `label = 'Sol'` (pour les onglets Tenue | Sol) ;
- à la fin du fichier : les points d'entrée `kiritoTenue` (boutons de la Tenue, onglets, barre de recherche) et
  `kiritoApercu` (aperçu du personnage), et l'événement `cfx_ts_vetements:interface`.

**d) `web/build/index.html`** : le style de l'inventaire et le script qui met en page le panneau Tenue
(voir `THEME.md` dans ox_inventory : thèmes et réglages dans `server.cfg`).

### 4. illenium-appearance (déjà fait dans le pack)

Si vous utilisez votre propre illenium-appearance, reportez dans `server/server.lua` :

- deux exports serveur : `getSavedAppearance(src)` (apparence enregistrée du joueur) et
  `saveAppearanceFor(src, appearance)` (enregistre une apparence) ;
- l'événement `purchaseClothingItems` (achat en magasin) : il lit l'apparence avant l'achat, refuse un changement
  de modèle, encaisse, enregistre, puis appelle :

```lua
    if avant and GetResourceState('cfx_ts_vetements') == 'started' then
        pcall(function() exports.cfx_ts_vetements:achatMagasin(src, avant, appearance) end)
    end
```

- dans l'événement `saveAppearance`, **avant** `Framework.SaveAppearance` (indispensable contre la duplication) :

```lua
    if GetResourceState("cfx_ts_vetements") == "started" then
        local okAvant, avant = pcall(Framework.GetAppearance, citizenID)
        if not okAvant then return end
        local ok, filtree = pcall(function()
            return exports.cfx_ts_vetements:verrouillerVetements(avant, appearance)
        end)
        if not ok or type(filtree) ~= "table" then return end
        appearance = filtree
    end
```

`saveAppearanceFor` doit renvoyer `true` **seulement** si l'enregistrement a réussi : c'est ce qui permet à
cfx_ts_vetements d'annuler une action dont la sauvegarde a échoué. Voir `server/server.lua` du pack.

### 5. Vérifier

Redémarrez le serveur, connectez-vous et ouvrez la console **F8** : vous devez voir
`[cfx_ts_vetements] version 1.6.2`. Si ce message n'apparaît pas, c'est une ancienne version qui tourne.

---

## Utilisation en jeu

| Action | Comment |
|---|---|
| Ouvrir la Tenue | Touche de l'inventaire (F2 par défaut) sans rien autour. Dans un véhicule ou près d'un coffre, l'inventaire s'ouvre comme d'habitude. |
| Enfiler un vêtement | Glissez-le de vos poches vers la Tenue, ou clic droit > Utiliser. |
| Retirer un vêtement | Glissez-le de la Tenue vers vos poches. |
| Remettre une tenue complète | Glissez l'objet « Tenue » sur la case « Tenue complète » (en bas, à côté du sac), ou utilisez-le. La tenue reste affichée dans cette case tant que vous la portez. |
| Retirer toute la tenue | Glissez la case « Tenue complète » vers vos poches : tout ce que vous portez redevient un seul objet (il garde son nom). |
| Créer une tenue | `/tenuemenu` (tout ce que vous portez devient un seul objet « Tenue »). |
| Poser un objet par terre | Clic droit > Mettre au sol. |
| Enregistrer une tenue | Magasin ou vestiaire > **Enregistrer ma tenue**, donnez-lui un nom : tout ce que vous portez devient un objet « Tenue « nom » ». |
| Remettre une tenue enregistrée | Utilisez l'objet, ou glissez-le sur la Tenue. Ce que vous portiez est rangé en un objet « Tenue ». |
| Retirer sa tenue | Magasin ou vestiaire > **Retirer ma tenue** : elle redevient un objet et garde son nom (si vous n'avez rien changé). |
| Menu de secours | `/tenuemenu` : les mêmes actions dans un menu ox_lib. |
| Magasin de vêtements | Vous payez et portez vos nouveaux vêtements ; les pièces remplacées reviennent dans l'inventaire. |

---

## Réglages (`config.lua`)

| Réglage | Par défaut | Rôle |
|---|---|---|
| `Config.CommandeMenu` | `'tenuemenu'` | Commande du menu de secours. `false` pour la désactiver. |
| `Config.DureeAnimation` | `1500` | Durée de l'animation quand on utilise un vêtement (ms). |
| `Config.Cooldown` | `400` | Délai minimum entre deux changements (ms), contre le spam. |
| `Config.MagasinRendAnciens` | `true` | `false` : les vêtements remplacés en magasin disparaissent (comportement d'origine). |
| `Config.VerrouVetements` | `true` | Anti-duplication : les vêtements ne changent que par les objets ou un achat payé. `false` : déconseillé. |
| `Config.Apercu.Actif` | `true` | `false` : pas d'aperçu du personnage (cadre vide). |
| `Config.Apercu.ChampVision` | `50.0` | Champ de vision de la caméra. Plus petit = moins de déformation, caméra plus loin. |
| `Config.Apercu.Hauteur` | `2.1` | Hauteur filmée en mètres. Plus grand = personnage plus petit dans le cadre. |
| `Config.Apercu.FlouDecor` | `true` | Flou d'arrière-plan derrière le personnage. |
| `Config.ItemTenue` | `'vet_tenue'` | Nom de l'objet « Tenue complète ». |
| `Config.TenuesEnObjets` | `true` | Menu des tenues du magasin / vestiaire : « Enregistrer ma tenue » et « Retirer ma tenue » en objets. `false` : menu d'origine d'illenium. |
| `Config.Categories` | 13 catégories | Voir la section suivante. |
| `Config.Nu` | valeurs GTA | Valeurs « sans vêtement » pour chaque modèle (sous-vêtements, pieds nus…). |

---

## Ajouter ou modifier une catégorie

Chaque entrée de `Config.Categories` relie une catégorie à un objet :

```lua
{ key = 'veste', item = 'vet_veste', label = 'Veste', icone = 'shirt',
  pieces = { { type = 'component', id = 11 }, { type = 'component', id = 3 } } },
```

- `pieces` : ce que l'objet contient. La **première** pièce sert à savoir si la catégorie est portée.
- `type = 'component'` : composant GTA (id 0 à 11). `type = 'prop'` : accessoire (id 0, 1, 2, 6, 7).
- La veste embarque aussi les bras (composant 3) pour que les manches restent assorties.

**Important** : l'ordre de `Config.Categories` est aussi l'ordre des cases du panneau Tenue (case 1 = chapeau…).
Si vous le changez, mettez aussi à jour les noms et positions des cases dans le style d'ox_inventory (`web/build/index.html`,
lignes `.tenue-mode .inventory-slot:nth-child(...)`).

Si les sous-vêtements ou les pieds nus ne sont pas bons avec vos packs de vêtements, ajustez `Config.Nu`
(`{ modèle, texture }` pour chaque composant, par modèle de personnage).

---

## Sécurité

- **Le serveur décide de tout** : la source de vérité est l'apparence enregistrée côté serveur. Le client ne fait
  qu'afficher.
- **Déplacements contrôlés** : dans le panneau Tenue, le déplacement brut d'ox_inventory est toujours refusé, puis
  rejoué par le chemin sécurisé (hook `swapItems`).
- **Personne d'autre** ne peut ouvrir ou modifier la Tenue d'un joueur (hook `openInventory`).
- **Vérifications** : métadonnées de chaque vêtement validées, vêtement refusé si le sexe ne correspond pas au
  personnage, verrou par joueur et délai minimum entre deux actions, poids et cases de l'inventaire respectés.
- **Annulation complète** : si l'enregistrement de l'apparence échoue, les objets donnés sont repris et l'objet
  utilisé est rendu. Un vêtement ne peut pas exister à la fois sur le personnage et dans l'inventaire.
- **Anti-duplication** (`Config.VerrouVetements`) : illenium-appearance laisse le client enregistrer lui-même son
  apparence, gratuitement. Quand il le fait, les vêtements qu'il envoie sont ignorés et remplacés par ceux enregistrés
  côté serveur. Un vêtement ne peut donc apparaître que par un objet d'inventaire ou par un achat payé en magasin.
  Le reste de l'apparence (visage, cheveux, maquillage, tatouages) est enregistré normalement.
- **Création de personnage** : un personnage sans apparence enregistrée choisit librement ses premiers vêtements
  (une seule fois, c'est le fonctionnement normal de la création).
- **Magasin** : un achat ne peut pas changer le modèle du personnage, et le paiement est encaissé avant tout
  enregistrement.

---

## Pour les développeurs

**Export serveur**

```lua
-- Rendre en objets les pièces remplacées lors d'un achat (appelé par illenium-appearance)
exports.cfx_ts_vetements:achatMagasin(source, apparenceAvant, apparenceApres)
```

**Export client**

```lua
-- Utilisé par ox_inventory quand on utilise un objet vet_* (data/items.lua)
exports.cfx_ts_vetements:utiliser(data, slot)
```

**Callbacks serveur** (ox_lib, protégés par un verrou par joueur) :
`cfx_ts_vetements:equiper`, `cfx_ts_vetements:retirer`, `cfx_ts_vetements:rangerTenue`, `cfx_ts_vetements:toutRetirer`.

**Événements**

| Événement | Côté | Rôle |
|---|---|---|
| `cfx_ts_vetements:ouvrirTenue` | serveur (net) | Ouvre l'inventaire avec le panneau Tenue. |
| `cfx_ts_vetements:appliquer` | client (net) | Applique les pièces validées par le serveur. |
| `cfx_ts_vetements:ouvrirNormal` | client (net) | Ouvre l'inventaire normal si la Tenue ne peut pas s'ouvrir. |
| `cfx_ts_vetements:actionPanneau` | client (local) | Boutons « Tout retirer » / « Créer une tenue ». |
| `cfx_ts_vetements:apercu` | client (local) | Position de la fenêtre d'aperçu, envoyée par l'interface. |

---

## Dépannage

**L'inventaire s'ouvre puis se referme tout seul, ou ne s'ouvre plus.**
Une ancienne version (aperçu en mode « menu ») tourne encore. Supprimez le dossier `cfx_ts_vetements`
(config comprise), remettez celui du pack, redémarrez, puis reconnectez-vous. Vérifiez le message
`version 1.6.2` dans la console F8.

**Le personnage n'est pas centré dans la Tenue, ou il est trop grand / trop petit.**
Ajustez `Config.Apercu.Hauteur` (plus grand = personnage plus petit) et `Config.Apercu.ChampVision`.

**Des blocs noirs apparaissent dans l'inventaire.**
Un effet de flou que FiveM ne sait pas afficher. Le style fourni n'en utilise plus : remplacez
`ox_inventory/web/build/index.html` par celui du pack.

**Retirer un vêtement donne un mauvais sous-vêtement ou des chaussures bizarres.**
Vos packs de vêtements utilisent d'autres numéros : ajustez `Config.Nu`.

**Utiliser un vêtement ne fait rien.**
Vérifiez que les objets `vet_*` ont bien `client = { export = 'cfx_ts_vetements.utiliser' }` dans
`ox_inventory/data/items.lua`, et que `cfx_ts_vetements` démarre après `ox_inventory`.

**« Pas assez de place dans votre inventaire ».**
Le vêtement retiré ne rentre pas dans vos poches (poids ou cases) : libérez de la place.

---

## Limites connues

- ox_inventory n'affiche que **deux inventaires à la fois** : la Tenue et un coffre ne peuvent pas être ouverts ensemble.
- Les vêtements créés par les toutes premières versions gardent leur ancienne description sur une ligne.
- Tenues de métier d'illenium : elles s'affichent sur le personnage mais ne remplacent plus les vêtements
  enregistrés (verrou anti-duplication). Le panneau Tenue montre donc vos vêtements civils ; à la reconnexion,
  ce sont eux que vous portez. Évitez de changer de vêtement depuis la Tenue en uniforme (les deux se mélangent
  à l'écran jusqu'au prochain rechargement).
- Changement de modèle (menu des peds, homme ↔ femme) : le personnage repart sans vêtements, ceux de l'autre
  modèle ne lui vont pas.
- `Config.TenuesEnObjets = false` avec le verrou actif : les tenues d'origine d'illenium s'affichent mais ne sont plus
  enregistrées. Gardez `true`.
- **ESX uniquement** pour le moment.
- Après une mise à jour d'ox_inventory ou d'illenium-appearance, il faut reporter les modifications
  (étapes 3 et 4).

---

## Licences

| Ressource | Licence | Revente |
|---|---|---|
| `cfx_ts_vetements` | Licence gratuite non commerciale (fichier `LICENSE`) | **Interdite** |
| `illenium-appearance` | Code d'origine : MIT (`LICENSE`). Modifications du pack : même licence que cfx_ts_vetements (`LICENSE-MODIFICATIONS`) | **Interdite** pour les modifications du pack |
| `ox_inventory` | GPL‑3.0 (`LICENSE`, `NOTICE.md`), imposée par ses auteurs | Ne peut pas être interdite par la GPL, mais le code doit toujours rester ouvert et gratuit à redistribuer |

En résumé : utilisez, modifiez et partagez gratuitement, en citant l'auteur. Ne vendez pas ce pack.

---

## Historique des versions

**1.6.2**
- illenium-appearance : la HUD est aussi cachée pendant le menu d'apparence (magasin de vêtements, coiffeur,
  tatoueur, création du personnage), avec les mêmes règles que l'inventaire (esx_hud automatique, mêmes réglages
  `server.cfg`). Elle revient à la fermeture du menu, que le joueur valide ou annule.
- Création du personnage : la section « Ped » est cachée par défaut (un ped spécial ne peut pas porter les vêtements
  en objets). Remettez `Ped = true` dans `illenium-appearance/shared/config.lua` si vous en avez besoin.
- Installation : lignes `setr ox:locale "fr"` et `setr illenium-appearance:locale "fr"` ajoutées au `server.cfg`
  conseillé (sinon l'interface est en partie en anglais).

**1.6.1**
- HUD cachée automatiquement à chaque ouverture de l'inventaire : toute la HUD de GTA est masquée tant que
  l'inventaire est ouvert, et `inventory:hudexport` / `inventory:hudevent` acceptent plusieurs HUD séparées par
  des virgules (voir `ox_inventory/THEME.md`).
- esx_hud (HUD officielle d'ESX) est cachée automatiquement, sans réglage.

**1.6.0** (sécurité et nettoyage du pack)
- ox_inventory mis à jour en **2.48.0 officielle** (le pack était basé sur la 2.47.9, affichée par erreur 2.48.4) :
  correctifs officiels des coffres de véhicule (identifiant envoyé par le client refusé), de l'utilisation d'un objet
  pendant un autre, de l'attente du personnage côté serveur, retour de l'export `GetInventories` et de
  `inventory:gloveboxseatrestriction`.
- Anti-duplication : les vêtements envoyés par le client via illenium-appearance sont ignorés (`Config.VerrouVetements`).
  Effet secondaire : une tenue de métier n'écrase plus les vêtements enregistrés.
- Magasin : un achat ne peut plus changer le modèle du personnage.
- illenium-appearance (QBCore) : l'événement de migration des apparences est réservé aux administrateurs.
- ox_inventory redémarré : les crochets de la Tenue se réenregistrent tout seuls (plus besoin de redémarrer
  cfx_ts_vetements).
- Pack : `data/items.lua` d'origine + objets `vet_*` (les objets d'un serveur privé ont été retirés), prix et blips
  d'illenium par défaut, licences et `NOTICE.md` remis, fichiers `MODIFICATIONS.md` ajoutés, anciennes notes de design
  (`DA_*.md`) supprimées, numéro de version unique.

**1.5.2**
- Case « Tenue complète » : la tenue enfilée y reste affichée (au lieu de disparaître). On la sort vers les poches
  pour tout retirer d'un coup, on la remet quand on veut. Changer une pièce met la tenue à jour.
- Un vêtement retiré vers une case déjà prise des poches se range dans une autre case au lieu d'échouer.

**1.5.1**
- Panneau Tenue : une 14ᵉ case « Tenue complète » sous le personnage, pour y déposer un objet Tenue.

**1.5.0** (tenues enregistrées en objets)
- Magasin et vestiaire : « Enregistrer ma tenue » range tout ce que vous portez dans un seul objet nommé ;
  « Retirer ma tenue » la remet en objet en gardant son nom.
- Les options d'origine d'illenium (changer, mettre à jour, partager, supprimer, importer une tenue en base)
  sont masquées quand `Config.TenuesEnObjets = true` : elles créaient des vêtements sans objet.
  Les anciennes tenues restent en base ; remettez `false` pour les retrouver.

**1.4.1** (audit et correctifs)
- Magasin : illenium appelait `kirito_vetements` au lieu de `cfx_ts_vetements`, les pièces remplacées étaient perdues.
  Quand l'inventaire est plein, elles sont maintenant posées à vos pieds.
- Anti-duplication : chaque action est annulée en entier si l'apparence ne peut pas être enregistrée.
- Le poids maximum de l'inventaire est respecté (retirer, tout retirer, créer une tenue, magasin).
- Panneau Tenue : seules les cases modifiées sont mises à jour (au lieu de tout vider puis tout remettre).
- Un glisser-déposer refusé ne déclenche plus de requête en base de données.
- Aperçu : la caméra n'est recalculée que si le personnage bouge ; une seule boucle de suivi à la fois.
- La version affichée en console (F8) est lue dans `fxmanifest.lua`.
- illenium-appearance : apparence ESX vide (nouveau personnage) gérée, paiement échoué = habits d'origine remis,
  tenues protégées (seul le propriétaire peut les modifier, supprimer ou partager), tenues de métier réservées au
  patron, prix des tatouages fixé par le serveur.
- ox_inventory : jeter un objet dans l'eau sans fond ne bloque plus les déplacements ; l'onglet « Tenue » vérifie
  que l'inventaire peut s'ouvrir (mort, menotté…).

**1.4.0**
- Suppression complète de l'aperçu en mode « menu » (menu pause GTA), qui faisait refermer l'inventaire.
- Aperçu par caméra avec flou d'arrière-plan, message de version dans la console F8.

**1.3.0**
- Aperçu du personnage au centre de la Tenue, onglets « Tenue | Sol », « Jeter » fonctionnel Tenue ouverte.
- Boutons « Tout retirer » / « Créer une tenue » sous la Tenue, fiches vêtements en lignes (Modèle, Texture, Taille).

**1.2.0**
- Panneau « Tenue » dans l'inventaire avec glisser-déposer, ouverture par la touche de l'inventaire.
- Magasin de vêtements : les pièces remplacées reviennent en objets.

**1.0.0**
- Vêtements en objets, tenue complète, menu de la tenue, contrôle serveur et anti-duplication.
