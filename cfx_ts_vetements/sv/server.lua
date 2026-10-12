local ox = exports.ox_inventory
local illenium = exports['illenium-appearance']
-- Une case par catégorie, plus une case « Tenue complète » (toujours vide : on y dépose un objet Tenue pour l'enfiler)
local NB_CASES = #Config.Categories + 1

local MSG_PLEIN = 'Pas assez de place dans votre inventaire (poids ou cases).'
local MSG_ECHEC = "Impossible d'enregistrer votre tenue pour le moment, réessayez."

------------------------------------------------------------------------
-- Index des catégories
------------------------------------------------------------------------

local parCle, parItem, categorieDePiece = {}, {}, {}

for _, cat in ipairs(Config.Categories) do
    parCle[cat.key] = cat
    parItem[cat.item] = cat
    for _, p in ipairs(cat.pieces) do
        categorieDePiece[p.type .. ':' .. p.id] = cat.key
    end
end

------------------------------------------------------------------------
-- Verrou par joueur (une action à la fois + délai minimum)
------------------------------------------------------------------------

local occupe, derniere = {}, {}

local function verrouiller(src)
    local maintenant = GetGameTimer()
    if occupe[src] or (derniere[src] and maintenant - derniere[src] < Config.Cooldown) then
        return false
    end
    occupe[src] = true
    return true
end

local function liberer(src)
    occupe[src] = nil
    derniere[src] = GetGameTimer()
end

local function notifier(src, texte, typ)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Vêtements', description = texte, type = typ or 'inform' })
end

------------------------------------------------------------------------
-- Lecture / écriture de l'apparence enregistrée (source de vérité)
------------------------------------------------------------------------

local function lireApparence(src)
    local ok, a = pcall(function() return illenium:getSavedAppearance(src) end)
    if not ok or type(a) ~= 'table' or type(a.model) ~= 'string' or type(a.components) ~= 'table' then
        return nil, "Apparence introuvable : ouvrez une fois le menu d'apparence puis réessayez."
    end
    if not Config.Nu[a.model] then
        return nil, 'Votre personnage ne peut pas porter de vêtements en objets.'
    end
    if type(a.props) ~= 'table' then a.props = {} end
    return a
end

-- Renvoie true uniquement si l'apparence a bien été enregistrée.
-- En cas d'échec, l'appelant annule ce qu'il a fait dans l'inventaire (pas de duplication).
local function sauver(src, a)
    a.sex = nil
    local ok, resultat = pcall(function() return illenium:saveAppearanceFor(src, a) end)
    if not ok then
        print(('^1[cfx_ts_vetements] enregistrement de l\'apparence (joueur %s) : %s^0'):format(src, resultat))
        return false
    end
    return resultat == true
end

local function liste(a, typ)
    return typ == 'prop' and a.props or a.components
end

local function cleId(typ)
    return typ == 'prop' and 'prop_id' or 'component_id'
end

local function trouver(a, typ, id)
    local l, k = liste(a, typ), cleId(typ)
    for i = 1, #l do
        if l[i][k] == id then return l[i] end
    end
end

local function valeurNue(modele, typ, id)
    if typ == 'prop' then return -1, -1 end
    local v = Config.Nu[modele].composants[id]
    if v then return v[1], v[2] end
    return 0, 0
end

local function lirePieces(a, cat)
    local pieces = {}
    for _, p in ipairs(cat.pieces) do
        local e = trouver(a, p.type, p.id)
        local d, t = valeurNue(a.model, p.type, p.id)
        pieces[#pieces + 1] = {
            type = p.type,
            id = p.id,
            drawable = e and e.drawable or d,
            texture = e and e.texture or t,
        }
    end
    return pieces
end

local function piecesNues(modele, cat)
    local pieces = {}
    for _, p in ipairs(cat.pieces) do
        local d, t = valeurNue(modele, p.type, p.id)
        pieces[#pieces + 1] = { type = p.type, id = p.id, drawable = d, texture = t }
    end
    return pieces
end

local function estPorte(a, cat)
    local p = cat.pieces[1]
    local e = trouver(a, p.type, p.id)
    if not e or type(e.drawable) ~= 'number' then return false end
    if p.type == 'prop' then return e.drawable >= 0 end
    local d = valeurNue(a.model, p.type, p.id)
    return e.drawable ~= d
end

local function ecrirePieces(a, pieces)
    for _, p in ipairs(pieces) do
        local e = trouver(a, p.type, p.id)
        if not e then
            e = { [cleId(p.type)] = p.id }
            local l = liste(a, p.type)
            l[#l + 1] = e
        end
        e.drawable = p.drawable
        e.texture = p.texture
    end
end

local function ajouter(dest, pieces)
    for _, p in ipairs(pieces) do dest[#dest + 1] = p end
end

------------------------------------------------------------------------
-- Métadonnées des objets
------------------------------------------------------------------------

local function sexe(modele)
    return modele == 'mp_f_freemode_01' and 'Femme' or 'Homme'
end

local function metaVetement(cat, modele, pieces)
    local p = pieces[1]
    return {
        label = cat.label,
        description = ('**Modèle** %s  \n**Texture** %s  \n**Taille** %s'):format(p.drawable, p.texture, sexe(modele)),
        modele = modele,
        categorie = cat.key,
        pieces = pieces,
    }
end

local function metaTenue(modele, pieces, nombre, nom)
    return {
        label = nom and ('Tenue « %s »'):format(nom) or 'Tenue',
        description = ('**Pièces** %d  \n**Taille** %s'):format(nombre, sexe(modele)),
        modele = modele,
        pieces = pieces,
        nom = nom,
    }
end

------------------------------------------------------------------------
-- Tenues enregistrées (magasin / vestiaire) : nom de la tenue portée
-- On retient le nom de la dernière tenue enfilée et la liste exacte de ses pièces.
-- Si le joueur la retire telle quelle, l'objet rendu garde son nom.
------------------------------------------------------------------------

-- Nom choisi par le joueur : sans caractères de mise en forme, une trentaine de caractères au plus
local function nettoyerNom(nom)
    if type(nom) ~= 'string' then return nil end
    nom = nom:gsub('[%c%*_`#<>%[%]|\\~]', ''):gsub('%s+', ' '):match('^%s*(.-)%s*$')
    if nom == '' then return nil end
    if #nom > 48 then nom = nom:sub(1, 48):gsub('[\128-\191]*$', ''):gsub('[\192-\255]$', '') end
    return nom
end

-- Empreinte de ce que le joueur porte (catégories portées, dans l'ordre de Config.Categories)
local function empreinte(a)
    local morceaux = {}
    for _, c in ipairs(Config.Categories) do
        if estPorte(a, c) then
            for _, p in ipairs(lirePieces(a, c)) do
                morceaux[#morceaux + 1] = ('%s%d:%d:%d'):format(p.type == 'prop' and 'p' or 'c', p.id, p.drawable, p.texture)
            end
        end
    end
    return table.concat(morceaux, ',')
end

local function cleMemoire(src)
    local licence = GetPlayerIdentifierByType(src, 'license')
    return licence and ('cfx_ts_vetements:tenue:' .. licence) or nil
end

-- Tenue portée : enregistrée quand on enfile un objet Tenue, mise à jour à chaque pièce changée,
-- effacée quand on retire tout. actif = false pour l'effacer.
local function memoriserTenue(src, a, actif, nom)
    local cle = cleMemoire(src)
    if not cle then return end
    if actif then
        SetResourceKvp(cle, json.encode({ nom = nom or '', model = a.model, empreinte = empreinte(a) }))
    else
        DeleteResourceKvp(cle)
    end
end

-- Nom de la tenue portée, seulement si le joueur porte exactement les mêmes pièces
-- Tenue portée, seulement si le joueur porte exactement ce qu'on a retenu
-- (sinon l'apparence a changé ailleurs : magasin, autre personnage...)
local function tenuePortee(src, a)
    local cle = cleMemoire(src)
    local brut = cle and GetResourceKvpString(cle)
    if not brut then return nil end
    local ok, m = pcall(json.decode, brut)
    if not ok or type(m) ~= 'table' or m.model ~= a.model or m.empreinte ~= empreinte(a) then return nil end
    return { nom = nettoyerNom(m.nom) }
end

local function nomTenuePortee(src, a)
    local m = tenuePortee(src, a)
    return m and m.nom or nil
end

-- Tout ce que le joueur porte, réuni en un objet Tenue (nil s'il ne porte rien)
local function tenueComplete(a, nom)
    local portees, nombre = {}, 0
    for _, c in ipairs(Config.Categories) do
        if estPorte(a, c) then
            nombre += 1
            ajouter(portees, lirePieces(a, c))
        end
    end
    if nombre == 0 then return nil end
    return metaTenue(a.model, portees, nombre, nom)
end

-- Vérifie et nettoie les pièces lues dans un objet (on ne fait jamais confiance au contenu brut).
local function piecesValides(pieces, cleAttendue)
    if type(pieces) ~= 'table' or #pieces == 0 or #pieces > 32 then return nil end

    local propres = {}
    for i = 1, #pieces do
        local p = pieces[i]
        if type(p) ~= 'table' or (p.type ~= 'prop' and p.type ~= 'component') then return nil end

        local id, d, t = tonumber(p.id), tonumber(p.drawable), tonumber(p.texture)
        if not id or not d or not t then return nil end
        id, d, t = math.floor(id), math.floor(d), math.floor(t)

        local cle = categorieDePiece[p.type .. ':' .. id]
        if not cle or (cleAttendue and cle ~= cleAttendue) then return nil end
        if d < -1 or d > 2000 or t < -1 or t > 255 then return nil end

        propres[#propres + 1] = { type = p.type, id = id, drawable = d, texture = t }
    end
    return propres
end

------------------------------------------------------------------------
-- Objets rendus au joueur (avec annulation possible)
------------------------------------------------------------------------

-- Donne un vêtement en respectant le poids et les cases (AddItem seul ne vérifie pas le poids).
-- Renvoie de quoi le reprendre si la suite échoue, ou nil si ça ne rentre pas.
local function donner(src, nom, meta, case)
    if not ox:CanCarryItem(src, nom, 1, meta) then return nil end

    local ok, reponse = ox:AddItem(src, nom, 1, meta, case)
    if not ok and case then
        -- Case visée déjà prise : on range ailleurs dans les poches
        ok, reponse = ox:AddItem(src, nom, 1, meta)
    end
    if not ok then return nil end

    local placee = type(reponse) == 'table' and (reponse.slot or (type(reponse[1]) == 'table' and reponse[1].slot)) or nil
    return { nom = nom, meta = meta, case = placee }
end

local function reprendre(src, don)
    if not don then return end
    if don.case then
        ox:RemoveItem(src, don.nom, 1, nil, don.case)
    else
        ox:RemoveItem(src, don.nom, 1, don.meta)
    end
end

------------------------------------------------------------------------
-- Panneau « Tenue » : un coffre temporaire par joueur, reflet de ce qu'il porte
------------------------------------------------------------------------

local tenueDe, proprietaire = {}, {}   -- joueur -> coffre, coffre -> joueur

-- Contenu du coffre, ou nil s'il n'existe plus (ex. redémarrage d'ox_inventory)
local function objetsDuCoffre(id)
    local ok, objets = pcall(function() return ox:GetInventoryItems(id) end)
    if ok and type(objets) == 'table' then return objets end
end

local function coffreTenue(src)
    local id = tenueDe[src]
    if id and objetsDuCoffre(id) then return id end
    if id then proprietaire[id] = nil end

    id = ox:CreateTemporaryStash({ label = 'Tenue', slots = NB_CASES, maxWeight = 1000000, items = {} })
    if not id then return nil end

    tenueDe[src] = id
    proprietaire[id] = src
    return id
end

local function memeContenu(actuel, nom, meta)
    if type(actuel) ~= 'table' or actuel.name ~= nom then return false end
    local m = actuel.metadata
    if type(m) ~= 'table' or m.modele ~= meta.modele or type(m.pieces) ~= 'table' then return false end
    if #m.pieces ~= #meta.pieces then return false end
    for i = 1, #meta.pieces do
        local p, q = meta.pieces[i], m.pieces[i]
        if type(q) ~= 'table' or q.type ~= p.type or q.id ~= p.id or q.drawable ~= p.drawable or q.texture ~= p.texture then
            return false
        end
    end
    return true
end

-- Met le panneau à jour à partir de l'apparence enregistrée (case i = catégorie i).
-- Seules les cases qui ont changé sont modifiées : moins d'échanges réseau et pas de clignotement.
local function rafraichirTenue(src, a)
    local id = tenueDe[src]
    if not id then return end

    if not a then
        a = lireApparence(src)                  -- lecture en base : peut attendre
        if tenueDe[src] ~= id then return end   -- joueur parti entre-temps
    end

    local objets = objetsDuCoffre(id)
    if not objets then return end

    local actuels = {}
    for k, v in pairs(objets) do
        local n = tonumber(k)
        if n and type(v) == 'table' then actuels[n] = v end
    end

    for case, objet in pairs(actuels) do
        if case > NB_CASES then ox:RemoveItem(id, objet.name, objet.count or 1, nil, case) end
    end

    for i, cat in ipairs(Config.Categories) do
        local meta = a and estPorte(a, cat) and metaVetement(cat, a.model, lirePieces(a, cat)) or nil
        local actuel = actuels[i]
        if not (meta and memeContenu(actuel, cat.item, meta)) then
            if actuel then ox:RemoveItem(id, actuel.name, actuel.count or 1, nil, i) end
            if meta then ox:AddItem(id, cat.item, 1, meta, i) end
        end
    end

    -- Dernière case : la tenue enfilée (tout ce qui est porté, en un seul objet).
    -- La sortir vers les poches retire toute la tenue ; y déposer un objet Tenue l'enfile.
    local tenue = a and tenuePortee(src, a)
    local meta = tenue and tenueComplete(a, tenue.nom) or nil
    local actuel = actuels[NB_CASES]
    if not (meta and memeContenu(actuel, Config.ItemTenue, meta) and (actuel.metadata or {}).label == meta.label) then
        if actuel then ox:RemoveItem(id, actuel.name, actuel.count or 1, nil, NB_CASES) end
        if meta then ox:AddItem(id, Config.ItemTenue, 1, meta, NB_CASES) end
    end
end

local function supprimerTenue(src)
    local id = tenueDe[src]
    if not id then return end
    tenueDe[src] = nil
    proprietaire[id] = nil
    ox:RemoveInventory(id)
end

------------------------------------------------------------------------
-- Actions
------------------------------------------------------------------------

local function equiper(src, slot)
    local item = ox:GetSlot(src, slot)
    if not item then return false end

    local cat = parItem[item.name]
    local estTenue = item.name == Config.ItemTenue
    if not cat and not estTenue then return false end

    local meta = item.metadata or {}
    local pieces = piecesValides(meta.pieces, cat and cat.key)
    if not pieces then
        notifier(src, 'Ce vêtement est vide ou abîmé.', 'error')
        return false
    end

    local a, err = lireApparence(src)
    if not a then notifier(src, err, 'error') return false end
    local tenueAvant = tenuePortee(src, a)

    if meta.modele and meta.modele ~= a.model then
        notifier(src, ('Ce vêtement est taillé pour un personnage %s.'):format(sexe(meta.modele):lower()), 'error')
        return false
    end

    -- Ce que le joueur porte actuellement et qui va être remplacé
    local ancien
    if estTenue then
        local portees, nombre = {}, 0
        for _, c in ipairs(Config.Categories) do
            if estPorte(a, c) then
                nombre += 1
                ajouter(portees, lirePieces(a, c))
            end
        end
        if nombre > 0 then
            ancien = { item = Config.ItemTenue, meta = metaTenue(a.model, portees, nombre, nomTenuePortee(src, a)) }
        end
    elseif estPorte(a, cat) then
        ancien = { item = cat.item, meta = metaVetement(cat, a.model, lirePieces(a, cat)) }
    end

    -- La suppression vérifie aussi que l'objet est toujours dans cette case, avec ce contenu
    if not ox:RemoveItem(src, item.name, 1, item.metadata, slot) then return false end

    local rendu
    if ancien then
        rendu = donner(src, ancien.item, ancien.meta)
        if not rendu then
            ox:AddItem(src, item.name, 1, item.metadata, slot)
            notifier(src, MSG_PLEIN, 'error')
            return false
        end
    end

    local appliquees = {}
    if estTenue then
        for _, c in ipairs(Config.Categories) do
            local nues = piecesNues(a.model, c)
            ecrirePieces(a, nues)
            ajouter(appliquees, nues)
        end
    end
    ecrirePieces(a, pieces)
    ajouter(appliquees, pieces)

    if not sauver(src, a) then
        reprendre(src, rendu)
        ox:AddItem(src, item.name, 1, item.metadata, slot)
        notifier(src, MSG_ECHEC, 'error')
        return false
    end

    -- Tenue enfilée : elle s'affiche dans la case « Tenue complète ».
    -- Une seule pièce changée : la tenue portée (s'il y en a une) est mise à jour.
    if estTenue then
        memoriserTenue(src, a, true, nettoyerNom(meta.nom))
    elseif tenueAvant then
        memoriserTenue(src, a, true, tenueAvant.nom)
    end

    rafraichirTenue(src, a)
    return { ok = true, pieces = appliquees }
end

local function retirer(src, cle, caseCible)
    local cat = parCle[cle]
    if not cat then return false end

    local a, err = lireApparence(src)
    if not a then notifier(src, err, 'error') return false end

    if not estPorte(a, cat) then
        notifier(src, ('Vous ne portez pas de %s.'):format(cat.label:lower()))
        return false
    end
    local tenueAvant = tenuePortee(src, a)

    local don = donner(src, cat.item, metaVetement(cat, a.model, lirePieces(a, cat)), caseCible)
    if not don then
        notifier(src, MSG_PLEIN, 'error')
        return false
    end

    local nues = piecesNues(a.model, cat)
    ecrirePieces(a, nues)

    if not sauver(src, a) then
        reprendre(src, don)
        notifier(src, MSG_ECHEC, 'error')
        return false
    end

    -- La tenue portée perd cette pièce (elle disparaît de sa case s'il ne reste plus rien)
    if tenueAvant then
        memoriserTenue(src, a, tenueComplete(a) ~= nil, tenueAvant.nom)
    end

    rafraichirTenue(src, a)
    return { ok = true, pieces = nues }
end

local function rangerTenue(src, nomChoisi, caseCible)
    local a, err = lireApparence(src)
    if not a then notifier(src, err, 'error') return false end

    local nom = nomChoisi or nomTenuePortee(src, a)

    local portees, categories = {}, {}
    for _, c in ipairs(Config.Categories) do
        if estPorte(a, c) then
            categories[#categories + 1] = c
            ajouter(portees, lirePieces(a, c))
        end
    end

    if #categories == 0 then
        notifier(src, 'Vous ne portez rien à ranger.')
        return false
    end

    local don = donner(src, Config.ItemTenue, metaTenue(a.model, portees, #categories, nom), caseCible)
    if not don then
        notifier(src, MSG_PLEIN, 'error')
        return false
    end

    local appliquees = {}
    for _, c in ipairs(categories) do
        local nues = piecesNues(a.model, c)
        ecrirePieces(a, nues)
        ajouter(appliquees, nues)
    end

    if not sauver(src, a) then
        reprendre(src, don)
        notifier(src, MSG_ECHEC, 'error')
        return false
    end

    memoriserTenue(src, a, false)
    notifier(src, nom and ('Tenue « %s » rangée dans votre inventaire.'):format(nom)
        or 'Votre tenue est rangée dans votre inventaire.', 'success')

    rafraichirTenue(src, a)
    return { ok = true, pieces = appliquees }
end

local function toutRetirer(src)
    local a, err = lireApparence(src)
    if not a then notifier(src, err, 'error') return false end

    local appliquees, dons, plein = {}, {}, false
    for _, c in ipairs(Config.Categories) do
        if estPorte(a, c) then
            local don = donner(src, c.item, metaVetement(c, a.model, lirePieces(a, c)))
            if don then
                dons[#dons + 1] = don
                local nues = piecesNues(a.model, c)
                ecrirePieces(a, nues)
                ajouter(appliquees, nues)
            else
                plein = true
                break
            end
        end
    end

    if #dons == 0 then
        notifier(src, plein and MSG_PLEIN or 'Vous ne portez rien à retirer.', plein and 'error' or 'inform')
        return false
    end

    if not sauver(src, a) then
        for i = 1, #dons do reprendre(src, dons[i]) end
        notifier(src, MSG_ECHEC, 'error')
        return false
    end

    if plein then
        notifier(src, 'Inventaire plein : une partie de la tenue est restée sur vous.', 'error')
    end

    memoriserTenue(src, a, false)

    rafraichirTenue(src, a)
    return { ok = true, pieces = appliquees }
end

------------------------------------------------------------------------
-- Callbacks
------------------------------------------------------------------------

local function proteger(nom, fn)
    lib.callback.register(nom, function(src, ...)
        if not verrouiller(src) then return false end
        local ok, resultat = pcall(fn, src, ...)
        liberer(src)
        if not ok then
            print(('^1[cfx_ts_vetements] %s : %s^0'):format(nom, resultat))
            return false
        end
        return resultat
    end)
end

proteger('cfx_ts_vetements:equiper', function(src, slot)
    if type(slot) ~= 'number' or slot < 1 or slot ~= math.floor(slot) then return false end
    return equiper(src, slot)
end)

proteger('cfx_ts_vetements:retirer', function(src, cle)
    if type(cle) ~= 'string' then return false end
    return retirer(src, cle)
end)

proteger('cfx_ts_vetements:rangerTenue', function(src) return rangerTenue(src) end)

-- Magasin / vestiaire : « Enregistrer ma tenue » -> tout ce qui est porté devient un objet nommé
proteger('cfx_ts_vetements:enregistrerTenue', function(src, nom)
    nom = nettoyerNom(nom)
    if not nom then
        notifier(src, 'Donnez un nom à votre tenue.', 'error')
        return false
    end
    return rangerTenue(src, nom)
end)
proteger('cfx_ts_vetements:toutRetirer', toutRetirer)

------------------------------------------------------------------------
-- Glisser-déposer entre les poches et le panneau « Tenue »
------------------------------------------------------------------------

-- Toutes les actions passent par le même chemin sécurisé que l'utilisation d'un objet :
-- on refuse le déplacement brut d'ox_inventory, puis on fait l'action nous-mêmes.
local function actionDepuisInventaire(src, fn, ...)
    -- Action déjà en cours ou trop rapprochée : ox_inventory a déjà annulé le déplacement
    -- à l'écran, et l'action en cours remettra le panneau à jour. Pas de lecture en base ici,
    -- sinon chaque glisser-déposer répété déclencherait une requête SQL.
    if not verrouiller(src) then return end

    local ok, resultat = pcall(fn, src, ...)
    liberer(src)

    if not ok then
        print(('^1[cfx_ts_vetements] glisser-déposer : %s^0'):format(resultat))
        rafraichirTenue(src)
        return
    end

    if type(resultat) == 'table' and resultat.ok then
        TriggerClientEvent('cfx_ts_vetements:appliquer', src, resultat.pieces)
    else
        rafraichirTenue(src)
    end
end

local function enregistrerCrochets()
    ox:registerHook('swapItems', function(payload)
        local src = payload.source
        local depuis = proprietaire[tostring(payload.fromInventory)]
        local vers = proprietaire[tostring(payload.toInventory)]
        if not depuis and not vers then return end

        -- Seul le propriétaire, et uniquement entre ses poches et sa tenue
        if (depuis and depuis ~= src) or (vers and vers ~= src) then return false end
        if depuis and vers then return false end

        if vers then
            local objet = payload.fromSlot
            if payload.fromInventory ~= src or type(objet) ~= 'table' then return false end

            if not parItem[objet.name] and objet.name ~= Config.ItemTenue then
                notifier(src, 'Seuls les vêtements vont dans la tenue.', 'error')
                return false
            end

            local case = objet.slot
            SetTimeout(0, function() actionDepuisInventaire(src, equiper, case) end)
            return false
        end

        if payload.toInventory ~= src then return false end

        local objet = payload.fromSlot
        local caseCible = type(payload.toSlot) == 'number' and payload.toSlot or nil

        -- Case « Tenue complète » sortie vers les poches : toute la tenue est retirée en un objet
        if type(objet) == 'table' and objet.slot == NB_CASES then
            SetTimeout(0, function() actionDepuisInventaire(src, rangerTenue, nil, caseCible) end)
            return false
        end

        local cat = type(objet) == 'table' and Config.Categories[objet.slot]
        if not cat then return false end

        local cle = cat.key
        SetTimeout(0, function() actionDepuisInventaire(src, retirer, cle, caseCible) end)
        return false
    end, { inventoryFilter = { '^temp%-' } })

    -- Personne d'autre ne peut ouvrir la tenue d'un joueur
    ox:registerHook('openInventory', function(payload)
        local proprio = proprietaire[tostring(payload.inventoryId)]
        if proprio and proprio ~= payload.source then return false end
    end, { inventoryFilter = { '^temp%-' } })
end

enregistrerCrochets()

-- ox_inventory redémarré : ses crochets et ses coffres temporaires sont perdus, on les remet en place
AddEventHandler('onServerResourceStart', function(ressource)
    if ressource ~= 'ox_inventory' then return end
    for _, id in pairs(tenueDe) do proprietaire[id] = nil end
    tenueDe = {}
    -- Petit délai : ox_inventory finit de démarrer
    SetTimeout(1000, function()
        local ok, err = pcall(enregistrerCrochets)
        if not ok then print(('^1[cfx_ts_vetements] crochets ox_inventory : %s^0'):format(err)) end
    end)
end)

-- Appelé par ox_inventory quand le joueur appuie sur la touche de l'inventaire sans rien autour
local derniereOuverture = {}

RegisterNetEvent('cfx_ts_vetements:ouvrirTenue', function()
    local src = source
    local maintenant = GetGameTimer()
    if derniereOuverture[src] and maintenant - derniereOuverture[src] < 500 then return end
    derniereOuverture[src] = maintenant

    local id = coffreTenue(src)
    if id then
        -- Si une action est en cours, c'est elle qui remettra le panneau à jour
        if not occupe[src] then rafraichirTenue(src) end
        if ox:forceOpenInventory(src, 'stash', id) then return end
    end

    TriggerClientEvent('cfx_ts_vetements:ouvrirNormal', src)
end)

------------------------------------------------------------------------
-- Magasin de vêtements (appelé par illenium-appearance après un achat)
------------------------------------------------------------------------

local function memesPieces(a, b)
    for i = 1, #a do
        if not b[i] or a[i].drawable ~= b[i].drawable or a[i].texture ~= b[i].texture then
            return false
        end
    end
    return true
end

-- Ce qui ne rentre pas dans l'inventaire est posé au sol plutôt que perdu
local function poserAuSol(src, objets)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local ok, id = pcall(function()
        return ox:CustomDrop('Vêtements', objets, GetEntityCoords(ped), math.max(#objets, 5), 100000, Player(src).state.instance)
    end)
    return ok and id ~= nil
end

exports('achatMagasin', function(src, avant, apres)
    if not Config.MagasinRendAnciens then return end
    if type(avant) ~= 'table' or type(apres) ~= 'table' then return end
    if type(avant.components) ~= 'table' or type(apres.components) ~= 'table' then return end
    if avant.model ~= apres.model or not Config.Nu[avant.model] then return end
    if type(avant.props) ~= 'table' then avant.props = {} end
    if type(apres.props) ~= 'table' then apres.props = {} end

    local ranges, auSol = 0, {}
    for _, cat in ipairs(Config.Categories) do
        if estPorte(avant, cat) then
            local anciennes = lirePieces(avant, cat)
            if not memesPieces(anciennes, lirePieces(apres, cat)) then
                local meta = metaVetement(cat, avant.model, anciennes)
                if donner(src, cat.item, meta) then
                    ranges += 1
                else
                    auSol[#auSol + 1] = { cat.item, 1, meta }
                end
            end
        end
    end

    if ranges > 0 then
        notifier(src, ranges > 1 and ('%d anciens vêtements ont été rangés dans votre inventaire.'):format(ranges)
            or 'Votre ancien vêtement a été rangé dans votre inventaire.', 'success')
    end

    local n = #auSol
    if n > 0 then
        local s = n > 1 and 's' or ''
        if poserAuSol(src, auSol) then
            notifier(src, ('Inventaire plein : %d ancien%s vêtement%s posé%s à vos pieds.'):format(n, s, s, s), 'error')
        else
            notifier(src, ('Inventaire plein : %d ancien%s vêtement%s n\'%s pas pu être rangé%s.'):format(
                n, s, s, n > 1 and 'ont' or 'a', s), 'error')
        end
    end
end)

------------------------------------------------------------------------
-- Verrou des vêtements (anti-duplication)
-- Appelé par illenium-appearance avant d'enregistrer une apparence envoyée par le client
-- (événement gratuit : création, coiffeur, tatoueur, chirurgien, tenues...).
-- Les pièces gérées par Config.Categories reprennent leur valeur enregistrée : un vêtement ne peut
-- apparaître que par un objet d'inventaire ou un achat payé. Le reste de l'apparence passe tel quel.
-- Renvoie l'apparence à enregistrer (les tables d'un export sont copiées, on la renvoie donc).
------------------------------------------------------------------------

exports('verrouillerVetements', function(avant, apres)
    if type(apres) ~= 'table' or type(apres.model) ~= 'string' then return nil end
    if Config.VerrouVetements == false then return apres end

    -- Pas d'apparence enregistrée : création du personnage, on laisse passer
    if type(avant) ~= 'table' or type(avant.model) ~= 'string' then return apres end

    if type(apres.components) ~= 'table' then apres.components = {} end
    if type(apres.props) ~= 'table' then apres.props = {} end

    if avant.model == apres.model then
        if not Config.Nu[apres.model] then return apres end -- ped spécial : pas de vêtements en objets
        if type(avant.components) ~= 'table' then avant.components = {} end
        if type(avant.props) ~= 'table' then avant.props = {} end
        for _, cat in ipairs(Config.Categories) do
            ecrirePieces(apres, lirePieces(avant, cat))
        end
        return apres
    end

    -- Changement de modèle (menu des peds, changement de sexe) : les vêtements ne suivent pas,
    -- le personnage repart sans vêtements (sinon on pourrait passer par un autre modèle pour en créer).
    if Config.Nu[apres.model] then
        for _, cat in ipairs(Config.Categories) do
            ecrirePieces(apres, piecesNues(apres.model, cat))
        end
    end
    return apres
end)

------------------------------------------------------------------------
-- Nettoyage
------------------------------------------------------------------------

AddEventHandler('playerDropped', function()
    local src = source
    occupe[src] = nil
    derniere[src] = nil
    derniereOuverture[src] = nil
    supprimerTenue(src)
end)

AddEventHandler('onResourceStop', function(ressource)
    if ressource ~= GetCurrentResourceName() then return end
    for src in pairs(tenueDe) do
        supprimerTenue(src)
    end
end)
