local outfitCache = {}
local uniformCache = {}

local function getMoneyForShop(shopType)
    local money = 0
    if shopType == "clothing" then
        money = Config.ClothingCost
    elseif shopType == "barber" then
        money = Config.BarberCost
    elseif shopType == "tattoo" then
        money = Config.TattooCost
    elseif shopType == "surgeon" then
        money = Config.SurgeonCost
    end

    return money
end

local function getOutfitsForPlayer(citizenid)
    outfitCache[citizenid] = {}
    local result = Database.PlayerOutfits.GetAllByCitizenID(citizenid)
    for i = 1, #result, 1 do
        outfitCache[citizenid][#outfitCache[citizenid] + 1] = {
            id = result[i].id,
            name = result[i].outfitname,
            model = result[i].model,
            components = json.decode(result[i].components),
            props = json.decode(result[i].props)
        }
    end
end

local function GenerateUniqueCode()
    local code, exists
    repeat
        code = GenerateNanoID(Config.OutfitCodeLength)
        exists = Database.PlayerOutfitCodes.GetByCode(code)
    until not exists
    return code
end

-- [Correctif sécurité] La tenue doit appartenir au joueur qui la modifie / supprime / partage
local function playerOwnsOutfit(citizenID, outfitID)
    if not citizenID or not tonumber(outfitID) then return false end
    local outfit = Database.PlayerOutfits.GetByID(outfitID)
    return outfit ~= nil and outfit.citizenid == citizenID
end

-- [Correctif sécurité] Seul le patron du métier / gang concerné peut gérer ses tenues
local function canManageOutfits(src, mType, jobName)
    if not Config.BossManagedOutfits then return false end
    if mType ~= "Job" and mType ~= "Gang" then return false end

    local ok, job = pcall(mType == "Gang" and Framework.GetGang or Framework.GetJob, src)
    if not ok or type(job) ~= "table" or not job.name or job.name ~= jobName then return false end

    if Framework.ESX() then
        local grades = Database.JobGrades.GetByJobName(job.name)
        if not grades or not grades[1] then return false end
        local highest = grades[1].grade
        for i = 2, #grades do
            if grades[i].grade > highest then highest = grades[i].grade end
        end
        return tonumber(job.grade and job.grade.level) == highest
    end

    return job.isboss == true
end

-- [Correctif sécurité] Le prix d'un tatouage vient de shared/tattoos.lua, jamais du client
local tattooCosts
local function getTattooCost(tattoo)
    if type(tattoo) ~= "table" or type(tattoo.name) ~= "string" then return nil end
    if not tattooCosts then
        tattooCosts = {}
        for _, zone in pairs(Config.Tattoos or {}) do
            for i = 1, #zone do
                local t = zone[i]
                if t.name then tattooCosts[t.name] = tonumber(t.cost) or Config.TattooCost end
            end
        end
    end
    local cost = tattooCosts[tattoo.name]
    if cost and cost >= 0 then return cost end
end

-- Callback(s)

lib.callback.register("illenium-appearance:server:generateOutfitCode", function(source, outfitID)
    if not playerOwnsOutfit(Framework.GetPlayerID(source), outfitID) then return end
    local existingOutfitCode = Database.PlayerOutfitCodes.GetByOutfitID(outfitID)
    if not existingOutfitCode then
        local code = GenerateUniqueCode()
        local id = Database.PlayerOutfitCodes.Add(outfitID, code)
        if not id then
            print("Something went wrong while generating outfit code")
            return
        end
        return code
    end
    return existingOutfitCode.code
end)

lib.callback.register("illenium-appearance:server:importOutfitCode", function(source, outfitName, outfitCode)
    local citizenID = Framework.GetPlayerID(source)
    if not citizenID or type(outfitName) ~= "string" or type(outfitCode) ~= "string" then return end
    local existingOutfitCode = Database.PlayerOutfitCodes.GetByCode(outfitCode)
    if not existingOutfitCode then
        return nil
    end

    local playerOutfit = Database.PlayerOutfits.GetByID(existingOutfitCode.outfitid)
    if not playerOutfit then
        return
    end

    if playerOutfit.citizenid == citizenID then return end -- Validation when someone tried to duplicate own outfit
    if Database.PlayerOutfits.GetByOutfit(outfitName, citizenID) then return end -- Validation duplicate outfit name, if validate on local id, someone can "spam error" server-sided

    local id = Database.PlayerOutfits.Add(citizenID, outfitName, playerOutfit.model, playerOutfit.components, playerOutfit.props)

    if not id then
        print("Something went wrong while importing the outfit")
        return
    end

    -- Cache pas encore chargé : on le charge (il contient déjà la tenue importée)
    if outfitCache[citizenID] == nil then
        getOutfitsForPlayer(citizenID)
        return true
    end

    outfitCache[citizenID][#outfitCache[citizenID] + 1] = {
        id = id,
        name = outfitName,
        model = playerOutfit.model,
        components = json.decode(playerOutfit.components),
        props = json.decode(playerOutfit.props)
    }

    return true
end)

lib.callback.register("illenium-appearance:server:getAppearance", function(source, model)
    local citizenID = Framework.GetPlayerID(source)
    return Framework.GetAppearance(citizenID, model)
end)

lib.callback.register("illenium-appearance:server:hasMoney", function(source, shopType)
    local money = getMoneyForShop(shopType)
    if Framework.HasMoney(source, "cash", money) then
        return true, money
    else
        return false, money
    end
end)

lib.callback.register("illenium-appearance:server:payForTattoo", function(source, tattoo)
    local src = source
    local cost = getTattooCost(tattoo)

    if cost and Framework.RemoveMoney(src, "cash", cost) then
        lib.notify(src, {
            title = _L("purchase.tattoo.success.title"),
            description = string.format(_L("purchase.tattoo.success.description"), tattoo.label, cost),
            type = "success",
            position = Config.NotifyOptions.position
        })
        return true
    else
        lib.notify(src, {
            title = _L("purchase.tattoo.failure.title"),
            description = _L("purchase.tattoo.failure.description"),
            type = "error",
            position = Config.NotifyOptions.position
        })
        return false
    end
end)

lib.callback.register("illenium-appearance:server:getOutfits", function(source)
    local citizenID = Framework.GetPlayerID(source)
    if outfitCache[citizenID] == nil then
        getOutfitsForPlayer(citizenID)
    end
    return outfitCache[citizenID]
end)

lib.callback.register("illenium-appearance:server:getManagementOutfits", function(source, mType, gender)
    local job = Framework.GetJob(source)
    if mType == "Gang" then
        job = Framework.GetGang(source)
    end

    local grade = tonumber(job.grade.level)
    local managementOutfits = {}
    local result = Database.ManagementOutfits.GetAllByJob(mType, job.name, gender)

    for i = 1, #result, 1 do
        if grade >= result[i].minrank then
            managementOutfits[#managementOutfits + 1] = {
                id = result[i].id,
                name = result[i].name,
                model = result[i].model,
                gender = result[i].gender,
                components = json.decode(result[i].components),
                props = json.decode(result[i].props)
            }
        end
    end
    return managementOutfits
end)

lib.callback.register("illenium-appearance:server:getUniform", function(source)
    return uniformCache[Framework.GetPlayerID(source)]
end)

-- Accès à l'apparence enregistrée, utilisé par cfx_ts_vetements (vêtements en objets).
exports("getSavedAppearance", function(src)
    local citizenID = Framework.GetPlayerID(src)
    if not citizenID then return nil end
    return Framework.GetAppearance(citizenID)
end)

-- Renvoie true seulement si l'enregistrement a réussi : cfx_ts_vetements annule l'action sinon.
exports("saveAppearanceFor", function(src, appearance)
    local citizenID = Framework.GetPlayerID(src)
    if not citizenID or type(appearance) ~= "table" or type(appearance.model) ~= "string" then return false end
    local ok, result = pcall(Framework.SaveAppearance, appearance, citizenID)
    if not ok then
        print(("^1[illenium-appearance] saveAppearanceFor : %s^0"):format(result))
        return false
    end
    return result ~= false
end)

RegisterNetEvent('illenium-appearance:server:purchaseClothingItems', function(appearance)
    local src = source
    if type(appearance) ~= 'table' or type(appearance.model) ~= 'string' then return end

    -- Joueur vérifié avant de prendre l'argent
    local citizenID = Framework.GetPlayerID(src)
    if not citizenID then return end

    -- Apparence enregistrée avant l'achat (lue avant de prendre l'argent)
    local okAvant, avant = pcall(Framework.GetAppearance, citizenID)
    if not okAvant then avant = nil end

    -- [Correctif sécurité] Un magasin de vêtements ne change jamais le modèle du personnage.
    -- Sans ce contrôle, un tricheur pouvait changer de sexe / de ped au prix d'un vêtement.
    if type(avant) == 'table' and avant.model ~= appearance.model then
        TriggerClientEvent('illenium-appearance:client:reloadSkin', src, true)
        return
    end

    local money = getMoneyForShop('clothing')
    if not Framework.RemoveMoney(src, 'cash', money) then
        lib.notify(src, {
            title = _L('purchase.store.failure.title'),
            description = _L('purchase.store.failure.description'),
            type = 'error',
            position = Config.NotifyOptions.position
        })
        -- Pas payé : on remet l'apparence enregistrée (sinon les habits restent portés gratuitement)
        TriggerClientEvent('illenium-appearance:client:reloadSkin', src, true)
        return
    end

    Framework.SaveAppearance(appearance, citizenID)

    -- Vêtements en objets : les pièces remplacées reviennent dans l'inventaire
    if avant and GetResourceState('cfx_ts_vetements') == 'started' then
        local ok, err = pcall(function()
            exports.cfx_ts_vetements:achatMagasin(src, avant, appearance)
        end)
        if not ok then
            print(('^1[illenium-appearance] achatMagasin (cfx_ts_vetements) : %s^0'):format(err))
        end
    end

    lib.notify(src, {
        title = _L('purchase.store.success.title'),
        description = string.format(_L('purchase.store.success.description'), money, 'clothing'),
        type = 'success',
        position = Config.NotifyOptions.position
    })
end)

RegisterServerEvent("illenium-appearance:server:saveAppearance", function(appearance)
    local src = source
    local citizenID = Framework.GetPlayerID(src)
    if citizenID and type(appearance) == "table" and type(appearance.model) == "string" then
        -- [Correctif sécurité] cfx_ts_vetements : cet événement est envoyé par le client et ne coûte rien.
        -- Sans verrou, un tricheur pouvait « porter » n'importe quel vêtement puis le retirer en objet
        -- (vêtements à l'infini). Les vêtements ne changent donc que par les objets d'inventaire ou par
        -- un achat payé en magasin ; le reste (visage, cheveux, maquillage, tatouages) est enregistré normalement.
        if GetResourceState("cfx_ts_vetements") == "started" then
            local okAvant, avant = pcall(Framework.GetAppearance, citizenID)
            if not okAvant then return end -- lecture impossible : on n'enregistre rien plutôt que de laisser passer
            -- Les tables passées à un export sont copiées : on récupère l'apparence filtrée en retour
            local ok, filtree = pcall(function()
                return exports.cfx_ts_vetements:verrouillerVetements(avant, appearance)
            end)
            if not ok or type(filtree) ~= "table" or type(filtree.model) ~= "string" then
                print(("^1[illenium-appearance] verrouillerVetements (cfx_ts_vetements) : %s^0"):format(tostring(filtree)))
                return
            end
            appearance = filtree
        end
        Framework.SaveAppearance(appearance, citizenID)
    end
end)

RegisterServerEvent("illenium-appearance:server:chargeCustomer", function(shopType)
    local src = source
    local money = getMoneyForShop(shopType)
    if Framework.RemoveMoney(src, "cash", money) then
        lib.notify(src, {
            title = _L("purchase.store.success.title"),
            description = string.format(_L("purchase.store.success.description"), money, shopType),
            type = "success",
            position = Config.NotifyOptions.position
        })
    else
        lib.notify(src, {
            title = _L("purchase.store.failure.title"),
            description = _L("purchase.store.failure.description"),
            type = "error",
            position = Config.NotifyOptions.position
        })
    end
end)

RegisterNetEvent("illenium-appearance:server:saveOutfit", function(name, model, components, props)
    local src = source
    local citizenID = Framework.GetPlayerID(src)
    if not citizenID or type(name) ~= "string" then return end
    if outfitCache[citizenID] == nil then
        getOutfitsForPlayer(citizenID)
    end
    if model and components and props then
        local id = Database.PlayerOutfits.Add(citizenID, name, model, json.encode(components), json.encode(props))
        if not id then
            return
        end
        outfitCache[citizenID][#outfitCache[citizenID] + 1] = {
            id = id,
            name = name,
            model = model,
            components = components,
            props = props
        }

        lib.notify(src, {
            title = _L("outfits.save.success.title"),
            description = string.format(_L("outfits.save.success.description"), name),
            type = "success",
            position = Config.NotifyOptions.position
        })
    end
end)

RegisterNetEvent("illenium-appearance:server:updateOutfit", function(id, model, components, props)
    local src = source
    local citizenID = Framework.GetPlayerID(src)
    if not playerOwnsOutfit(citizenID, id) then return end
    if outfitCache[citizenID] == nil then
        getOutfitsForPlayer(citizenID)
    end
    if model and components and props then
        if not Database.PlayerOutfits.Update(id, model, json.encode(components), json.encode(props)) then return end
        local outfitName = ""
        for i = 1, #outfitCache[citizenID], 1 do
            local outfit = outfitCache[citizenID][i]
            if outfit.id == id then
                outfit.model = model
                outfit.components = components
                outfit.props = props
                outfitName = outfit.name
                break
            end
        end
        lib.notify(src, {
            title = _L("outfits.update.success.title"),
            description = string.format(_L("outfits.update.success.description"), outfitName),
            type = "success",
            position = Config.NotifyOptions.position
        })
    end
end)

RegisterNetEvent("illenium-appearance:server:saveManagementOutfit", function(outfitData)
    local src = source
    if type(outfitData) ~= "table" or not canManageOutfits(src, outfitData.Type, outfitData.JobName) then return end
    local id = Database.ManagementOutfits.Add(outfitData)
    if not id then
        return
    end

    lib.notify(src, {
        title = _L("outfits.save.success.title"),
            description = string.format(_L("outfits.save.success.description"), outfitData.Name),
        type = "success",
        position = Config.NotifyOptions.position
    })
end)

RegisterNetEvent("illenium-appearance:server:deleteManagementOutfit", function(id)
    local src = source
    local outfit = tonumber(id) and Database.ManagementOutfits.GetByID(id)
    if not outfit or not canManageOutfits(src, outfit.type, outfit.job_name) then return end
    Database.ManagementOutfits.DeleteByID(id)
end)

RegisterNetEvent("illenium-appearance:server:syncUniform", function(uniform)
    local src = source
    uniformCache[Framework.GetPlayerID(src)] = uniform
end)

RegisterNetEvent("illenium-appearance:server:deleteOutfit", function(id)
    local src = source
    local citizenID = Framework.GetPlayerID(src)
    if not playerOwnsOutfit(citizenID, id) then return end

    Database.PlayerOutfitCodes.DeleteByOutfitID(id)
    Database.PlayerOutfits.DeleteByID(id)

    if outfitCache[citizenID] then
        for k, v in ipairs(outfitCache[citizenID]) do
            if v.id == id then
                table.remove(outfitCache[citizenID], k)
                break
            end
        end
    end
end)

RegisterNetEvent("illenium-appearance:server:resetOutfitCache", function()
    local src = source
    local citizenID = Framework.GetPlayerID(src)
    if citizenID then
        outfitCache[citizenID] = nil
    end
end)

RegisterNetEvent("illenium-appearance:server:ChangeRoutingBucket", function()
    local src = source
    SetPlayerRoutingBucket(src, src)
end)

RegisterNetEvent("illenium-appearance:server:ResetRoutingBucket", function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
end)

if Config.EnablePedMenu then
    lib.addCommand("pedmenu", {
        help = _L("commands.pedmenu.title"),
        params = {
            {
                name = "playerID",
                type = "number",
                help = "Target player's server id",
                optional = true
            },
        },
        restricted = Config.PedMenuGroup
    }, function(source, args)
        local target = source
        if args.playerID then
            local citizenID = Framework.GetPlayerID(args.playerID)
            if citizenID then
                target = args.playerID
            else
                lib.notify(source, {
                    title = _L("commands.pedmenu.failure.title"),
                    description = _L("commands.pedmenu.failure.description"),
                    type = "error",
                    position = Config.NotifyOptions.position
                })
                return
            end
        end
        TriggerClientEvent("illenium-appearance:client:openClothingShopMenu", target, true)
    end)
end

if Config.EnableJobOutfitsCommand then
    lib.addCommand("joboutfits", { help = _L("commands.joboutfits.title"), }, function(source)
        TriggerClientEvent("illenium-apearance:client:outfitsCommand", source, true)
    end)

    lib.addCommand("gangoutfits", { help = _L("commands.gangoutfits.title"), }, function(source)
        TriggerClientEvent("illenium-apearance:client:outfitsCommand", source)
    end)
end

lib.addCommand("reloadskin", { help = _L("commands.reloadskin.title") }, function(source)
    TriggerClientEvent("illenium-appearance:client:reloadSkin", source)
end)

lib.addCommand("clearstuckprops", { help = _L("commands.clearstuckprops.title") }, function(source)
    TriggerClientEvent("illenium-appearance:client:ClearStuckProps", source)
end)

lib.versionCheck("iLLeniumStudios/illenium-appearance")
