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

-- Fonction pour obtenir le groupe d'un joueur (MAINTENANT EXPORTÉE)
function GetPlayerGroup(playerId)
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
    
    print(string.format('^2[PVP SERVER]^7 Broadcast au groupe %d avec %d membres', groupId, #group.members))
    
    for _, memberId in ipairs(group.members) do
        local groupData = GetGroupData(memberId)
        print(string.format('^2[PVP SERVER]^7 Envoi données groupe à %d: %s', memberId, json.encode(groupData)))
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

-- Fonction pour retirer un joueur de son groupe (EXPORTÉE)
function RemovePlayerFromGroup(playerId)
    local group = GetPlayerGroup(playerId)
    if not group then 
        print(string.format('^3[PVP SERVER]^7 Joueur %d n\'est dans aucun groupe', playerId))
        return 
    end
    
    print(string.format('^2[PVP SERVER]^7 Retrait du joueur %d du groupe %d', playerId, group.id))
    
    -- Retirer du groupe
    for i, memberId in ipairs(group.members) do
        if memberId == playerId then
            table.remove(group.members, i)
            break
        end
    end
    
    group.ready[playerId] = nil
    playerGroups[playerId] = nil
    
    -- Notifier le joueur
    TriggerClientEvent('pvp:updateGroupUI', playerId, nil)
    
    -- Si le groupe est vide, le supprimer complètement
    if #group.members == 0 then
        groups[group.id] = nil
        print(string.format('^2[PVP SERVER]^7 Groupe %d supprimé (vide)', group.id))
    else
        -- Si c'était le leader, transférer
        if group.leaderId == playerId and #group.members > 0 then
            group.leaderId = group.members[1]
            TriggerClientEvent('esx:showNotification', group.leaderId, '~b~Vous êtes maintenant le leader du groupe')
        end
        BroadcastToGroup(group.id)
    end
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
    
    -- Si le joueur cible est déjà dans un groupe, le retirer automatiquement
    if GetPlayerGroup(targetId) then
        print(string.format('^2[PVP SERVER]^7 Le joueur %d est déjà dans un groupe, retrait automatique', targetId))
        RemovePlayerFromGroup(targetId)
        TriggerClientEvent('esx:showNotification', targetId, '~y~Vous avez été retiré de votre groupe précédent')
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
    
    print(string.format('^2[PVP SERVER]^7 %s accepte l\'invitation de %s', src, inviterId))
    
    if not pendingInvites[src] or pendingInvites[src] ~= inviterId then
        TriggerClientEvent('esx:showNotification', src, '~r~Invitation expirée')
        return
    end
    
    pendingInvites[src] = nil
    
    -- Vérifier si le joueur est déjà dans un groupe (double sécurité)
    if GetPlayerGroup(src) then
        print(string.format('^3[PVP SERVER]^7 Joueur %d déjà dans un groupe lors de l\'acceptation, retrait', src))
        RemovePlayerFromGroup(src)
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
    
    print(string.format('^2[PVP SERVER]^7 %s ajouté au groupe %d', src, group.id))
    
    TriggerClientEvent('esx:showNotification', src, '~g~Vous avez rejoint le groupe')
    
    local xInviter = ESX.GetPlayerFromId(inviterId)
    if xInviter then
        TriggerClientEvent('esx:showNotification', inviterId, '~g~' .. xPlayer.getName() .. ' a rejoint le groupe')
    end
    
    -- Broadcast immédiat à TOUS les membres
    Wait(200)
    BroadcastToGroup(group.id)
    
    -- Double sécurité
    Wait(100)
    local groupData = GetGroupData(src)
    TriggerClientEvent('pvp:updateGroupUI', src, groupData)
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

-- EXPORTS pour les autres fichiers
exports('GetPlayerGroup', GetPlayerGroup)
exports('RemovePlayerFromGroup', RemovePlayerFromGroup)
