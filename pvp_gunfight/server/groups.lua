print('^2[PVP SERVER GROUPS]^7 Module chargé')

-- Système de groupes
local groups = {}
local playerGroups = {} -- [playerId] = groupId
local pendingInvites = {} -- [playerId] = inviterId

-- Fonction pour créer un groupe
local function CreateGroup(leaderId)
    local groupId = #groups + 1
    
    groups[groupId] = {
        id = groupId,
        leaderId = leaderId,
        members = {leaderId},
        ready = {[leaderId] = false}
    }
    
    playerGroups[leaderId] = groupId
    
    return groupId
end

-- Fonction pour obtenir le groupe d'un joueur
local function GetPlayerGroup(playerId)
    local groupId = playerGroups[playerId]
    if groupId then
        return groups[groupId]
    end
    return nil
end

-- Fonction pour broadcast au groupe
local function BroadcastToGroup(groupId)
    local group = groups[groupId]
    if not group then return end
    
    for _, memberId in ipairs(group.members) do
        local groupData = GetGroupData(memberId)
        TriggerClientEvent('pvp:updateGroupUI', memberId, groupData)
    end
end

-- Fonction pour obtenir les données du groupe formatées
function GetGroupData(playerId)
    local group = GetPlayerGroup(playerId)
    if not group then return nil end
    
    local members = {}
    for _, memberId in ipairs(group.members) do
        local xPlayer = ESX.GetPlayerFromId(memberId)
        if xPlayer then
            table.insert(members, {
                id = memberId,
                name = xPlayer.getName(),
                isLeader = memberId == group.leaderId,
                isReady = group.ready[memberId] or false,
                isYou = memberId == playerId,
                yourId = playerId
            })
        end
    end
    
    return {
        id = group.id,
        leaderId = group.leaderId,
        members = members
    }
end

-- Event: Inviter un joueur
RegisterNetEvent('pvp:inviteToGroup', function(targetId)
    local src = source
    print(string.format('^2[PVP SERVER]^7 %s invite le joueur %s', src, targetId))
    
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if not xPlayer then
        print('^1[PVP SERVER]^7 Source invalide')
        return
    end
    
    if not xTarget then
        print('^1[PVP SERVER]^7 Joueur cible introuvable')
        TriggerClientEvent('esx:showNotification', src, '~r~Joueur introuvable - ID ' .. targetId .. ' n\'est pas sur le serveur')
        return
    end
    
    -- Vérifier si le joueur est déjà dans un groupe
    if GetPlayerGroup(targetId) then
        TriggerClientEvent('esx:showNotification', src, '~r~Ce joueur est déjà dans un groupe')
        return
    end
    
    -- Créer un groupe si le leader n'en a pas
    local group = GetPlayerGroup(src)
    if not group then
        CreateGroup(src)
        group = GetPlayerGroup(src)
    end
    
    -- Vérifier si c'est le leader
    if group.leaderId ~= src then
        TriggerClientEvent('esx:showNotification', src, '~r~Seul le leader peut inviter')
        return
    end
    
    -- Vérifier la limite de membres (4 max)
    if #group.members >= 4 then
        TriggerClientEvent('esx:showNotification', src, '~r~Groupe complet (4 joueurs max)')
        return
    end
    
    -- Envoyer l'invitation
    pendingInvites[targetId] = src
    TriggerClientEvent('pvp:receiveInvite', targetId, xPlayer.getName(), src)
    TriggerClientEvent('esx:showNotification', src, '~b~Invitation envoyée à ' .. xTarget.getName())
end)

-- Event: Accepter une invitation
RegisterNetEvent('pvp:acceptInvite', function(inviterId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not pendingInvites[src] or pendingInvites[src] ~= inviterId then
        TriggerClientEvent('esx:showNotification', src, '~r~Invitation expirée')
        return
    end
    
    pendingInvites[src] = nil
    
    -- Vérifier si le joueur est déjà dans un groupe
    if GetPlayerGroup(src) then
        TriggerClientEvent('esx:showNotification', src, '~r~Vous êtes déjà dans un groupe')
        return
    end
    
    local group = GetPlayerGroup(inviterId)
    if not group then
        TriggerClientEvent('esx:showNotification', src, '~r~Le groupe n\'existe plus')
        return
    end
    
    -- Vérifier la limite
    if #group.members >= 4 then
        TriggerClientEvent('esx:showNotification', src, '~r~Groupe complet')
        return
    end
    
    -- Ajouter au groupe
    table.insert(group.members, src)
    group.ready[src] = false
    playerGroups[src] = group.id
    
    TriggerClientEvent('esx:showNotification', src, '~g~Vous avez rejoint le groupe')
    
    local xInviter = ESX.GetPlayerFromId(inviterId)
    if xInviter then
        TriggerClientEvent('esx:showNotification', inviterId, '~g~' .. xPlayer.getName() .. ' a rejoint le groupe')
    end
    
    BroadcastToGroup(group.id)
end)

-- Event: Quitter le groupe
RegisterNetEvent('pvp:leaveGroup', function()
    local src = source
    local group = GetPlayerGroup(src)
    
    if not group then
        TriggerClientEvent('esx:showNotification', src, '~r~Vous n\'êtes dans aucun groupe')
        return
    end
    
    -- Retirer du groupe
    for i, memberId in ipairs(group.members) do
        if memberId == src then
            table.remove(group.members, i)
            break
        end
    end
    
    group.ready[src] = nil
    playerGroups[src] = nil
    
    -- Si c'était le leader et qu'il reste des membres
    if group.leaderId == src and #group.members > 0 then
        group.leaderId = group.members[1]
        TriggerClientEvent('esx:showNotification', group.leaderId, '~b~Vous êtes maintenant le leader du groupe')
    end
    
    -- Si le groupe est vide, le supprimer
    if #group.members == 0 then
        groups[group.id] = nil
    else
        BroadcastToGroup(group.id)
    end
    
    TriggerClientEvent('esx:showNotification', src, '~y~Vous avez quitté le groupe')
    TriggerClientEvent('pvp:updateGroupUI', src, nil)
end)

-- Event: Kick un joueur
RegisterNetEvent('pvp:kickFromGroup', function(targetId)
    local src = source
    local group = GetPlayerGroup(src)
    
    if not group or group.leaderId ~= src then
        TriggerClientEvent('esx:showNotification', src, '~r~Vous n\'êtes pas le leader')
        return
    end
    
    -- Vérifier que le joueur est dans le groupe
    local found = false
    for i, memberId in ipairs(group.members) do
        if memberId == targetId then
            table.remove(group.members, i)
            found = true
            break
        end
    end
    
    if not found then
        TriggerClientEvent('esx:showNotification', src, '~r~Joueur introuvable dans le groupe')
        return
    end
    
    group.ready[targetId] = nil
    playerGroups[targetId] = nil
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if xTarget then
        TriggerClientEvent('esx:showNotification', targetId, '~r~Vous avez été exclu du groupe')
        TriggerClientEvent('pvp:updateGroupUI', targetId, nil)
    end
    
    TriggerClientEvent('esx:showNotification', src, '~y~Joueur exclu du groupe')
    BroadcastToGroup(group.id)
end)

-- Event: Toggle ready
RegisterNetEvent('pvp:toggleReady', function()
    local src = source
    print(string.format('^2[PVP SERVER]^7 %s toggle ready', src))
    
    local group = GetPlayerGroup(src)
    
    if not group then
        print('^2[PVP SERVER]^7 Pas de groupe, création auto')
        -- Créer un groupe solo
        CreateGroup(src)
        group = GetPlayerGroup(src)
    end
    
    group.ready[src] = not group.ready[src]
    
    local status = group.ready[src] and '~g~Prêt' or '~r~Pas prêt'
    print(string.format('^2[PVP SERVER]^7 Nouveau statut de %s: %s', src, group.ready[src] and 'READY' or 'NOT READY'))
    
    TriggerClientEvent('esx:showNotification', src, 'Statut: ' .. status)
    
    BroadcastToGroup(group.id)
end)

-- Callback: Obtenir les infos du groupe
ESX.RegisterServerCallback('pvp:getGroupInfo', function(source, cb)
    local groupData = GetGroupData(source)
    cb(groupData)
end)

-- Nettoyer quand un joueur se déconnecte
AddEventHandler('playerDropped', function()
    local src = source
    local group = GetPlayerGroup(src)
    
    if group then
        -- Retirer du groupe
        for i, memberId in ipairs(group.members) do
            if memberId == src then
                table.remove(group.members, i)
                break
            end
        end
        
        group.ready[src] = nil
        playerGroups[src] = nil
        
        -- Si c'était le leader
        if group.leaderId == src and #group.members > 0 then
            group.leaderId = group.members[1]
        end
        
        -- Si le groupe est vide
        if #group.members == 0 then
            groups[group.id] = nil
        else
            BroadcastToGroup(group.id)
        end
    end
    
    -- Nettoyer les invitations
    pendingInvites[src] = nil
end)