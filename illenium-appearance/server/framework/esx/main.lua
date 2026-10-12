if not Framework.ESX() then return end

local ESX = exports["es_extended"]:getSharedObject()

function Framework.GetPlayerID(src)
    local Player = ESX.GetPlayerFromId(src)
    if Player then
        return Player.identifier
    end
end

function Framework.HasMoney(src, type, money)
    if type == "cash" then
        type = "money"
    end
    local Player = ESX.GetPlayerFromId(src)
    return Player.getAccount(type).money >= money
end

function Framework.RemoveMoney(src, type, money)
    if type == "cash" then
        type = "money"
    end
    local Player = ESX.GetPlayerFromId(src)
    if Player.getAccount(type).money >= money then
        Player.removeAccountMoney(type, money)
        return true
    end
    return false
end

function normalizeGrade(job)
    job.grade = {
        level = job.grade
    }
    return job
end

function Framework.GetJob(src)
    local Player = ESX.GetPlayerFromId(src)
    return normalizeGrade(Player.getJob())
end

function Framework.GetGang(src)
    local Player = ESX.GetPlayerFromId(src)
    return normalizeGrade(Player.getJob())
end

-- Renvoie false si la requête SQL a échoué (utilisé par l'export saveAppearanceFor)
function Framework.SaveAppearance(appearance, citizenID)
    return Database.Users.UpdateSkinForUser(citizenID, json.encode(appearance)) ~= nil
end

function Framework.GetAppearance(citizenID)
    local user = Database.Users.GetSkinByCitizenID(citizenID)
    -- users.skin est vide (NULL) pour un nouveau personnage : json.decode(nil) plantait
    if user and type(user.skin) == "string" and user.skin ~= "" then
        local ok, skin = pcall(json.decode, user.skin)
        if ok and type(skin) == "table" then
            skin.sex = skin.model == "mp_m_freemode_01" and 0 or 1
            return skin
        end
    end
    return nil
end
