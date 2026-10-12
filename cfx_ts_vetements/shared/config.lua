Config = {}

-- Le panneau « Tenue » s'ouvre avec la touche de l'inventaire (F2 par défaut) quand il n'y a rien autour.
Config.CommandeMenu = 'tenuemenu'  -- /tenuemenu : ranger toute la tenue, tout retirer (false pour désactiver)
Config.DureeAnimation = 1500       -- durée de l'animation quand on utilise un vêtement (ms)
Config.Cooldown = 400              -- délai minimum entre deux changements (ms)

-- Magasin de vêtements : les pièces remplacées par un achat reviennent dans l'inventaire
Config.MagasinRendAnciens = true

-- Anti-duplication : les vêtements ne changent que par les objets d'inventaire ou un achat payé.
-- illenium-appearance laisse le client enregistrer son apparence lui-même ; avec ce verrou, les vêtements
-- qu'il envoie sont ignorés (visage, cheveux, tatouages... restent enregistrés normalement).
-- Effet secondaire voulu : une tenue de métier n'écrase plus vos vêtements enregistrés.
-- false : comportement d'origine (déconseillé si les vêtements ont une valeur sur votre serveur).
Config.VerrouVetements = true

-- Tenues enregistrées en objets (menu du magasin / vestiaire d'illenium-appearance) :
--   « Enregistrer ma tenue » : tout ce que vous portez devient UN objet « Tenue « nom » »
--   « Retirer ma tenue »     : la tenue portée redevient un objet (elle garde son nom)
-- On la remet en utilisant l'objet ou en le glissant sur la Tenue.
-- false : menu des tenues d'origine d'illenium (tenues enregistrées en base, sans objet).
Config.TenuesEnObjets = true

-- Aperçu du personnage au centre du panneau Tenue
Config.Apercu = {
    Actif = true,          -- false pour garder un cadre vide
    -- Une caméra filme le personnage de face, cadrée sur la fenêtre de la Tenue.
    ChampVision = 50.0,    -- champ de vision de la caméra (degrés)
    Hauteur = 2.1,         -- hauteur filmée en mètres (le personnage + un peu de marge)
    FlouDecor = true,      -- flou d'arrière-plan : le personnage reste net, le décor est flouté
}

Config.ItemTenue = 'vet_tenue'     -- objet "Tenue complète"

-- Chaque catégorie correspond à un objet ox_inventory.
-- pieces : ce que l'objet contient. La première pièce sert à savoir si la catégorie est portée.
--   type 'component' = SetPedComponentVariation (id 0 à 11)
--   type 'prop'      = SetPedPropIndex (id 0, 1, 2, 6, 7)
-- La veste embarque aussi les bras (composant 3) pour que les manches restent assorties.
Config.Categories = {
    { key = 'chapeau',    item = 'vet_chapeau',    label = 'Chapeau',            icone = 'hat-cowboy',    pieces = { { type = 'prop', id = 0 } } },
    { key = 'lunettes',   item = 'vet_lunettes',   label = 'Lunettes',           icone = 'glasses',       pieces = { { type = 'prop', id = 1 } } },
    { key = 'oreilles',   item = 'vet_oreilles',   label = "Boucles d'oreilles", icone = 'ear-listen',    pieces = { { type = 'prop', id = 2 } } },
    { key = 'masque',     item = 'vet_masque',     label = 'Masque',             icone = 'masks-theater', pieces = { { type = 'component', id = 1 } } },
    { key = 'chaine',     item = 'vet_chaine',     label = 'Chaîne',             icone = 'link',          pieces = { { type = 'component', id = 7 } } },
    { key = 'veste',      item = 'vet_veste',      label = 'Veste',              icone = 'shirt',         pieces = { { type = 'component', id = 11 }, { type = 'component', id = 3 } } },
    { key = 'tshirt',     item = 'vet_tshirt',     label = 'T-shirt',            icone = 'shirt',         pieces = { { type = 'component', id = 8 } } },
    { key = 'gilet',      item = 'vet_gilet',      label = 'Gilet',              icone = 'vest',          pieces = { { type = 'component', id = 9 } } },
    { key = 'sac',        item = 'vet_sac',        label = 'Sac',                icone = 'suitcase',      pieces = { { type = 'component', id = 5 } } },
    { key = 'montre',     item = 'vet_montre',     label = 'Montre',             icone = 'clock',         pieces = { { type = 'prop', id = 6 } } },
    { key = 'bracelet',   item = 'vet_bracelet',   label = 'Bracelet',           icone = 'ring',          pieces = { { type = 'prop', id = 7 } } },
    { key = 'pantalon',   item = 'vet_pantalon',   label = 'Pantalon',           icone = 'person',        pieces = { { type = 'component', id = 4 } } },
    { key = 'chaussures', item = 'vet_chaussures', label = 'Chaussures',         icone = 'shoe-prints',   pieces = { { type = 'component', id = 6 } } },
}

-- Valeurs "sans vêtement" pour chaque composant : { modèle, texture }.
-- Ce sont les valeurs GTA de base les plus courantes. Si vos packs de vêtements
-- utilisent d'autres numéros (sous-vêtements, pieds nus...), ajustez-les ici.
-- Les accessoires (props) n'ont pas besoin de valeur : -1 = retiré.
Config.Nu = {
    ['mp_m_freemode_01'] = {
        composants = {
            [1]  = { 0, 0 },   -- masque
            [3]  = { 15, 0 },  -- bras
            [4]  = { 61, 0 },  -- pantalon (sous-vêtement)
            [5]  = { 0, 0 },   -- sac
            [6]  = { 34, 0 },  -- chaussures (pieds nus)
            [7]  = { 0, 0 },   -- chaîne
            [8]  = { 15, 0 },  -- t-shirt
            [9]  = { 0, 0 },   -- gilet
            [11] = { 15, 0 },  -- veste (torse nu)
        },
    },
    ['mp_f_freemode_01'] = {
        composants = {
            [1]  = { 0, 0 },
            [3]  = { 15, 0 },
            [4]  = { 15, 0 },
            [5]  = { 0, 0 },
            [6]  = { 35, 0 },
            [7]  = { 0, 0 },
            [8]  = { 14, 0 },
            [9]  = { 0, 0 },
            [11] = { 15, 0 },
        },
    },
}
