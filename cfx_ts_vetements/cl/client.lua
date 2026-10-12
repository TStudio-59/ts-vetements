local illenium = exports['illenium-appearance']
local enCours = false

local rafraichirApercu -- défini plus bas (aperçu du personnage)

-- Applique sur le personnage les pièces renvoyées par le serveur
local function appliquer(pieces)
    local ped = cache.ped
    for _, p in ipairs(pieces or {}) do
        if p.type == 'prop' then
            illenium:setPedProp(ped, { prop_id = p.id, drawable = p.drawable, texture = p.texture })
        else
            illenium:setPedComponent(ped, { component_id = p.id, drawable = p.drawable, texture = p.texture })
        end
    end
    if rafraichirApercu then rafraichirApercu() end
end

local function animation()
    return lib.progressBar({
        duration = Config.DureeAnimation,
        label = 'Vous vous changez...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true },
        anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
    })
end

local function executer(callback, ...)
    if enCours then return end
    enCours = true

    if animation() then
        local resultat = lib.callback.await(callback, false, ...)
        if type(resultat) == 'table' and resultat.ok then
            appliquer(resultat.pieces)
        end
    end

    enCours = false
end

-- Petit geste d'habillage qui ne bloque pas l'inventaire
local function geste()
    if not cache.vehicle and pcall(lib.requestAnimDict, 'clothingshirt', 1000) then
        TaskPlayAnim(cache.ped, 'clothingshirt', 'try_shirt_positive_d', 8.0, -8.0, 1200, 48, 0, false, false, false)
        RemoveAnimDict('clothingshirt')
    end
end

-- Glisser-déposer dans le panneau Tenue : le serveur a validé, on applique
RegisterNetEvent('cfx_ts_vetements:appliquer', function(pieces)
    appliquer(pieces)
    geste()
end)

-- Boutons « Tout retirer » et « Créer une tenue » du panneau Tenue (transmis par ox_inventory)
AddEventHandler('cfx_ts_vetements:actionPanneau', function(action)
    if enCours or (action ~= 'toutRetirer' and action ~= 'rangerTenue') then return end
    enCours = true

    local resultat = lib.callback.await('cfx_ts_vetements:' .. action, false)
    if type(resultat) == 'table' and resultat.ok then
        appliquer(resultat.pieces)
        geste()
    end

    enCours = false
end)

-- Tenues enregistrées : appelés par le menu du magasin / vestiaire d'illenium-appearance
-- « Enregistrer ma tenue » : tout ce que vous portez devient un seul objet, avec le nom choisi
AddEventHandler('cfx_ts_vetements:enregistrerTenue', function(nom)
    if type(nom) ~= 'string' then return end
    CreateThread(function()
        executer('cfx_ts_vetements:enregistrerTenue', nom)
    end)
end)

-- « Retirer ma tenue » : la tenue portée redevient un objet (elle garde son nom)
AddEventHandler('cfx_ts_vetements:retirerTenue', function()
    CreateThread(function()
        executer('cfx_ts_vetements:rangerTenue')
    end)
end)

-- Lu par illenium-appearance pour savoir s'il doit afficher les tenues en objets
exports('tenuesEnObjets', function()
    return Config.TenuesEnObjets ~= false
end)

-- Appelé par ox_inventory quand on utilise un vêtement (client.export dans data/items.lua)
exports('utiliser', function(_, slot)
    if not slot or not slot.slot then return end
    local numero = slot.slot
    CreateThread(function()
        executer('cfx_ts_vetements:equiper', numero)
    end)
end)

------------------------------------------------------------------------
-- Menu "Tenue" : ce que le personnage porte, pièce par pièce
------------------------------------------------------------------------

local MODELES = {
    [`mp_m_freemode_01`] = 'mp_m_freemode_01',
    [`mp_f_freemode_01`] = 'mp_f_freemode_01',
}

-- Affichage uniquement : c'est le serveur qui vérifie réellement
local function estPorte(cat)
    local modele = MODELES[GetEntityModel(cache.ped)]
    if not modele then return false end

    local p = cat.pieces[1]
    if p.type == 'prop' then
        return GetPedPropIndex(cache.ped, p.id) ~= -1
    end

    local nu = Config.Nu[modele].composants[p.id]
    return GetPedDrawableVariation(cache.ped, p.id) ~= (nu and nu[1] or 0)
end

local function ouvrirMenu()
    if enCours then return end

    local options, actions = {}, {}

    for _, cat in ipairs(Config.Categories) do
        local porte = estPorte(cat)
        options[#options + 1] = {
            label = cat.label,
            description = porte and 'Porté · Entrée pour le retirer' or 'Rien',
            icon = cat.icone,
            close = porte,
        }
        if porte then
            local cle = cat.key
            actions[#options] = function() executer('cfx_ts_vetements:retirer', cle) end
        end
    end

    options[#options + 1] = {
        label = 'Ranger toute la tenue',
        description = 'Tout ce que vous portez devient un seul objet « Tenue »',
        icon = 'box',
    }
    actions[#options] = function() executer('cfx_ts_vetements:rangerTenue') end

    options[#options + 1] = {
        label = 'Tout retirer',
        description = 'Chaque vêtement devient un objet séparé',
        icon = 'layer-group',
    }
    actions[#options] = function() executer('cfx_ts_vetements:toutRetirer') end

    lib.registerMenu({
        id = 'cfx_ts_vetements',
        title = 'Tenue',
        position = 'top-left',
        options = options,
    }, function(selected)
        local action = actions[selected]
        if action then CreateThread(action) end
    end)

    lib.showMenu('cfx_ts_vetements')
end

if Config.CommandeMenu then
    RegisterCommand(Config.CommandeMenu, ouvrirMenu, false)
end

-- Si la Tenue ne peut pas s'ouvrir, TAB ouvre l'inventaire normal
RegisterNetEvent('cfx_ts_vetements:ouvrirNormal', function()
    exports.ox_inventory:openInventory()
end)

------------------------------------------------------------------------
-- Aperçu du personnage dans le panneau Tenue
-- Une caméra filme le personnage de face, cadrée sur la fenêtre transparente
-- de l'inventaire (sa position est envoyée par l'interface d'ox_inventory).
------------------------------------------------------------------------

local camera, zoneApercu = nil, nil
local generation = 0      -- une seule boucle de suivi active à la fois
local dernierePose = nil  -- dernière position cadrée (évite de recalculer si rien n'a bougé)

local function arreterApercu()
    zoneApercu = nil
    dernierePose = nil
    generation += 1
    if camera then
        RenderScriptCams(false, true, 250, true, false)
        DestroyCam(camera, false)
        camera = nil
    end
end

-- Distance disponible devant le personnage avant un mur ou un objet
local function distanceLibre(depart, direction, distance)
    local arrivee = depart + direction * distance
    local rayon = StartExpensiveSynchronousShapeTestLosProbe(depart.x, depart.y, depart.z + 0.4, arrivee.x, arrivee.y, arrivee.z + 0.4, 1 + 16, cache.ped, 7)
    local _, touche, point = GetShapeTestResult(rayon)
    if touche == true or touche == 1 then
        return math.max(0.9, #(point - vector3(depart.x, depart.y, depart.z + 0.4)) - 0.35)
    end
    return distance
end

-- Position, orientation et champ de vision pour que le personnage remplisse la fenêtre
local function cadrer(zone)
    local ped = cache.ped
    local centre = GetEntityCoords(ped) - vector3(0.0, 0.0, 0.08)
    local avant = GetEntityForwardVector(ped)
    local droite = vector3(-avant.y, avant.x, 0.0)
    local aspect = GetAspectRatio(false)

    local hauteurVue = Config.Apercu.Hauteur / zone.h
    local fov = Config.Apercu.ChampVision
    local distance = hauteurVue / (2.0 * math.tan(math.rad(fov / 2.0)))

    local libre = distanceLibre(centre, avant, distance)
    if libre < distance then
        distance = libre
        fov = math.min(90.0, math.deg(2.0 * math.atan(hauteurVue / (2.0 * distance))))
        hauteurVue = 2.0 * distance * math.tan(math.rad(fov / 2.0))
    end

    local largeurVue = hauteurVue * aspect
    local decalage = (0.5 - (zone.x + zone.w / 2.0)) * largeurVue
    local hauteur = ((zone.y + zone.h / 2.0) - 0.5) * hauteurVue

    local position = centre + avant * distance + droite * decalage + vector3(0.0, 0.0, hauteur)
    return position, GetEntityHeading(ped) + 180.0, fov, distance
end

local function placer(force)
    -- Le lancer de rayon de cadrer() est coûteux : on ne recadre que si le personnage
    -- a bougé, a tourné, ou si la fenêtre d'aperçu a changé.
    local pos, heading = GetEntityCoords(cache.ped), GetEntityHeading(cache.ped)
    local p = dernierePose
    if not force and p and p.zone == zoneApercu and #(pos - p.pos) < 0.02 and math.abs(heading - p.cap) < 0.5 then
        return
    end
    dernierePose = { pos = pos, cap = heading, zone = zoneApercu }

    local position, cap, fov, distance = cadrer(zoneApercu)
    SetCamCoord(camera, position.x, position.y, position.z)
    SetCamRot(camera, 0.0, 0.0, cap, 2)
    SetCamFov(camera, fov)

    -- Flou d'arrière-plan : net autour du personnage, flou devant et derrière
    if Config.Apercu.FlouDecor ~= false then
        SetCamUseShallowDofMode(camera, true)
        SetCamNearDof(camera, math.max(0.1, distance - 0.8))
        SetCamFarDof(camera, distance + 0.8)
        SetCamDofStrength(camera, 1.0)
    end
end

local function suivre(gen)
    local image, sansFocus = 0, 0
    while gen == generation and zoneApercu and camera do
        if Config.Apercu.FlouDecor ~= false then SetUseHiDof() end

        image += 1
        if image % 5 == 0 then
            placer()

            -- Sécurité : si l'inventaire n'a plus le focus, on coupe la caméra
            if IsNuiFocused() then
                sansFocus = 0
            else
                sansFocus += 1
                if sansFocus > 12 then break end
            end
        end

        Wait(0)
    end
    -- Si une nouvelle caméra a pris le relais, on ne la coupe pas
    if gen == generation then arreterApercu() end
end

AddEventHandler('cfx_ts_vetements:apercu', function(data)
    if not Config.Apercu or not Config.Apercu.Actif then return end
    if type(data) ~= 'table' or not data.visible then return arreterApercu() end
    if cache.vehicle then return end

    local x, y, w, h = tonumber(data.x), tonumber(data.y), tonumber(data.w), tonumber(data.h)
    if not x or not y or not w or not h or w < 0.02 or h < 0.05 or w > 1 or h > 1 then return end

    zoneApercu = { x = x, y = y, w = w, h = h }
    if camera then return end

    camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    generation += 1
    local gen = generation
    placer(true)
    RenderScriptCams(true, true, 300, true, false)

    -- L'inventaire floute l'écran : on retire le flou pour voir le personnage
    if IsScreenblurFadeRunning() then DisableScreenblurFade() end
    TriggerScreenblurFadeOut(0.0)

    CreateThread(function() suivre(gen) end)
end)

AddEventHandler('onResourceStop', function(ressource)
    if ressource ~= GetCurrentResourceName() then return end
    arreterApercu()
end)

-- Sécurité : une ancienne version (mode « menu ») pouvait laisser le menu GTA ouvert,
-- ce qui fait refermer ox_inventory tout seul. On le referme au démarrage.
CreateThread(function()
    Wait(1000)
    local version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '?'
    print(('^2[cfx_ts_vetements] version %s - apercu camera (sans menu pause)^0'):format(version))
    if IsPauseMenuActive() and GetCurrentFrontendMenuVersion() == `FE_MENU_VERSION_EMPTY_NO_BACKGROUND` then
        ClearPedInPauseMenu()
        SetFrontendActive(false)
    end
end)
