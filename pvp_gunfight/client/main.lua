print('^2[PVP CLIENT]^7 Script chargé')

local pedSpawned = false
local pedEntity = nil
local uiOpen = false
local inQueue = false
local queueStartTime = 0
local inMatch = false

-- Fonction pour spawner le PED
local function SpawnPed()
    if pedSpawned then 
        print('^3[PVP CLIENT]^7 PED déjà spawné')
        return 
    end
    
    print('^2[PVP CLIENT]^7 Début spawn PED')
    local pedModel = GetHashKey(Config.PedLocation.model)
    
    print('^2[PVP CLIENT]^7 Requête modèle:', Config.PedLocation.model)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(100)
    end
    print('^2[PVP CLIENT]^7 Modèle chargé')
    
    pedEntity = CreatePed(4, pedModel, Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z - 1.0, Config.PedLocation.coords.w, false, true)
    print('^2[PVP CLIENT]^7 PED créé, entity:', pedEntity)
    
    SetEntityAsMissionEntity(pedEntity, true, true)
    SetPedFleeAttributes(pedEntity, 0, 0)
    SetPedDiesWhenInjured(pedEntity, false)
    SetPedKeepTask(pedEntity, true)
    SetBlockingOfNonTemporaryEvents(pedEntity, true)
    SetEntityInvincible(pedEntity, true)
    FreezeEntityPosition(pedEntity, true)
    
    if Config.PedLocation.scenario then
        TaskStartScenarioInPlace(pedEntity, Config.PedLocation.scenario, 0, true)
    end
    
    pedSpawned = true
    print('^2[PVP CLIENT]^7 PED spawné avec succès')
end

-- Fonction pour ouvrir l'UI
local function OpenUI()
    if uiOpen then 
        print('^3[PVP CLIENT]^7 UI déjà ouverte')
        return 
    end
    
    print('^2[PVP CLIENT]^7 Ouverture de l\'UI')
    
    SetNuiFocus(true, true)
    print('^2[PVP CLIENT]^7 SetNuiFocus(true, true) appelé')
    
    SendNUIMessage({
        action = 'openUI'
    })
    print('^2[PVP CLIENT]^7 Message openUI envoyé')
    
    uiOpen = true
    print('^2[PVP CLIENT]^7 UI ouverte (uiOpen = true)')
end

-- Fonction pour fermer l'UI
local function CloseUI()
    if not uiOpen then 
        print('^3[PVP CLIENT]^7 UI déjà fermée')
        return 
    end
    
    print('^2[PVP CLIENT]^7 Fermeture de l\'UI')
    
    SendNUIMessage({
        action = 'closeUI'
    })
    print('^2[PVP CLIENT]^7 Message closeUI envoyé au NUI')
    
    Wait(100)
    
    SetNuiFocus(false, false)
    print('^2[PVP CLIENT]^7 SetNuiFocus(false, false) appelé')
    
    SetNuiFocusKeepInput(false)
    print('^2[PVP CLIENT]^7 SetNuiFocusKeepInput(false) appelé')
    
    uiOpen = false
    print('^2[PVP CLIENT]^7 UI fermée (uiOpen = false)')
end

-- Callback NUI pour fermer l'interface
RegisterNUICallback('closeUI', function(data, cb)
    print('^2[PVP CLIENT]^7 Callback closeUI reçu du NUI')
    cb('ok')
    print('^2[PVP CLIENT]^7 Callback répondu')
    Wait(50)
    CloseUI()
end)

-- Event pour fermer l'UI depuis le serveur
RegisterNetEvent('pvp:forceCloseUI', function()
    print('^2[PVP CLIENT]^7 Event pvp:forceCloseUI reçu')
    CloseUI()
end)

-- Callback NUI pour rejoindre la queue
RegisterNUICallback('joinQueue', function(data, cb)
    print('^2[PVP CLIENT]^7 Callback joinQueue reçu - Mode:', data.mode)
    cb('ok')
    
    TriggerServerEvent('pvp:joinQueue', data.mode)
    print('^2[PVP CLIENT]^7 Event pvp:joinQueue envoyé au serveur')
end)

-- Callback NUI pour voir les stats
RegisterNUICallback('getStats', function(data, cb)
    print('^2[PVP CLIENT]^7 Callback getStats reçu')
    ESX.TriggerServerCallback('pvp:getPlayerStats', function(stats)
        print('^2[PVP CLIENT]^7 Stats reçues:', json.encode(stats))
        cb(stats)
    end)
end)

-- Callback NUI pour voir le leaderboard
RegisterNUICallback('getLeaderboard', function(data, cb)
    print('^2[PVP CLIENT]^7 Callback getLeaderboard reçu')
    ESX.TriggerServerCallback('pvp:getLeaderboard', function(leaderboard)
        print('^2[PVP CLIENT]^7 Leaderboard reçu:', #leaderboard, 'entrées')
        cb(leaderboard)
    end)
end)

-- Callback NUI pour inviter un joueur
RegisterNUICallback('invitePlayer', function(data, cb)
    local targetId = tonumber(data.targetId)
    print('^2[PVP CLIENT]^7 Callback invitePlayer reçu - Target ID:', targetId)
    cb('ok')
    
    TriggerServerEvent('pvp:inviteToGroup', targetId)
    print('^2[PVP CLIENT]^7 Event pvp:inviteToGroup envoyé')
end)

-- Callback NUI pour quitter le groupe
RegisterNUICallback('leaveGroup', function(data, cb)
    print('^2[PVP CLIENT]^7 Callback leaveGroup reçu')
    cb('ok')
    
    TriggerServerEvent('pvp:leaveGroup')
    print('^2[PVP CLIENT]^7 Event pvp:leaveGroup envoyé')
end)

-- Callback NUI pour kick un joueur du groupe
RegisterNUICallback('kickPlayer', function(data, cb)
    local targetId = tonumber(data.targetId)
    print('^2[PVP CLIENT]^7 Callback kickPlayer reçu - Target ID:', targetId)
    cb('ok')
    
    TriggerServerEvent('pvp:kickFromGroup', targetId)
    print('^2[PVP CLIENT]^7 Event pvp:kickFromGroup envoyé')
end)

-- Callback NUI pour changer son statut ready
RegisterNUICallback('toggleReady', function(data, cb)
    print('^2[PVP CLIENT]^7 Callback toggleReady reçu')
    cb('ok')
    
    TriggerServerEvent('pvp:toggleReady')
    print('^2[PVP CLIENT]^7 Event pvp:toggleReady envoyé')
end)

-- Callback NUI pour obtenir les infos du groupe
RegisterNUICallback('getGroupInfo', function(data, cb)
    print('^2[PVP CLIENT]^7 Callback getGroupInfo reçu')
    ESX.TriggerServerCallback('pvp:getGroupInfo', function(groupInfo)
        print('^2[PVP CLIENT]^7 GroupInfo reçu:', json.encode(groupInfo))
        cb(groupInfo)
    end)
end)

-- Callback pour accepter une invitation
RegisterNUICallback('acceptInvite', function(data, cb)
    local inviterId = tonumber(data.inviterId)
    print('^2[PVP CLIENT]^7 Callback acceptInvite reçu - Inviter ID:', inviterId)
    cb('ok')
    
    TriggerServerEvent('pvp:acceptInvite', inviterId)
    print('^2[PVP CLIENT]^7 Event pvp:acceptInvite envoyé')
end)

-- Callback pour refuser une invitation
RegisterNUICallback('declineInvite', function(data, cb)
    print('^2[PVP CLIENT]^7 Callback declineInvite reçu')
    cb('ok')
end)

-- Events pour mettre à jour l'UI du groupe
RegisterNetEvent('pvp:updateGroupUI', function(groupData)
    print('^2[PVP CLIENT]^7 Event pvp:updateGroupUI reçu:', json.encode(groupData))
    SendNUIMessage({
        action = 'updateGroup',
        group = groupData
    })
    print('^2[PVP CLIENT]^7 Message updateGroup envoyé au NUI')
end)

RegisterNetEvent('pvp:receiveInvite', function(inviterName, inviterId)
    print('^2[PVP CLIENT]^7 Event pvp:receiveInvite reçu de:', inviterName, '(ID:', inviterId, ')')
    
    ESX.ShowNotification('~b~' .. inviterName .. '~w~ vous invite à rejoindre son groupe!')
    
    -- NE PLUS afficher de popup automatiquement, juste envoyer au système de notifications
    SendNUIMessage({
        action = 'showInvite',
        inviterName = inviterName,
        inviterId = inviterId
    })
    print('^2[PVP CLIENT]^7 Message showInvite envoyé au NUI (queue système)')
end)

-- Event quand la recherche commence
RegisterNetEvent('pvp:searchStarted', function(mode)
    print('^2[PVP CLIENT]^7 Recherche commencée pour le mode:', mode)
    inQueue = true
    queueStartTime = GetGameTimer()
    
    SendNUIMessage({
        action = 'searchStarted',
        mode = mode
    })
end)

-- Event quand un match est trouvé
RegisterNetEvent('pvp:matchFound', function()
    print('^2[PVP CLIENT]^7 Match trouvé!')
    inQueue = false
    inMatch = true
    
    -- FERMER L'UI
    if uiOpen then
        print('^2[PVP CLIENT]^7 Fermeture de l\'UI (match trouvé)')
        CloseUI()
    end
    
    SendNUIMessage({
        action = 'matchFound'
    })
end)

-- Event quand la recherche est annulée
RegisterNetEvent('pvp:searchCancelled', function()
    print('^2[PVP CLIENT]^7 Recherche annulée')
    inQueue = false
    
    SendNUIMessage({
        action = 'searchCancelled'
    })
end)

-- Callback pour annuler la recherche
RegisterNUICallback('cancelSearch', function(data, cb)
    print('^2[PVP CLIENT]^7 Callback cancelSearch reçu')
    cb('ok')
    
    TriggerServerEvent('pvp:cancelSearch')
    print('^2[PVP CLIENT]^7 Event pvp:cancelSearch envoyé')
end)

-- Event pour téléporter à un spawn
RegisterNetEvent('pvp:teleportToSpawn', function(spawn, team, matchId)
    print(string.format('^2[PVP CLIENT]^7 Téléportation au spawn - Team: %s, Match: %d', team, matchId))
    print(string.format('^2[PVP CLIENT]^7 Coordonnées: %.2f, %.2f, %.2f, %.2f', spawn.x, spawn.y, spawn.z, spawn.w))
    
    local ped = PlayerPedId()
    
    -- Ressusciter si mort
    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    end
    
    -- Fade out
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Téléporter
    SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
    SetEntityHeading(ped, spawn.w)
    
    -- Freeze le joueur pendant le countdown
    FreezeEntityPosition(ped, true)
    
    -- Heal complet
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    
    -- Clear wounds
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    
    -- DONNER UNIQUEMENT LE CAL50
    RemoveAllPedWeapons(ped, true)
    GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL50'), 250, false, true)
    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_PISTOL50'), true)
    
    -- Munitions infinies
    SetPedInfiniteAmmoClip(ped, true)
    
    Wait(500)
    
    -- Fade in
    DoScreenFadeIn(500)
    
    -- Notification de team
    local teamColor = team == 'team1' and '~b~' or '~r~'
    ESX.ShowNotification(teamColor .. 'Vous êtes dans la ' .. (team == 'team1' and 'Team A (Bleu)' or 'Team B (Rouge)'))
    
    print('^2[PVP CLIENT]^7 Téléportation terminée, joueur défreeze')
end)

-- Event pour respawn un joueur
RegisterNetEvent('pvp:respawnPlayer', function(spawn)
    print(string.format('^2[PVP CLIENT]^7 Respawn du joueur'))
    
    local ped = PlayerPedId()
    
    -- Ressusciter si mort
    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    end
    
    -- Fade out RAPIDE
    DoScreenFadeOut(300)
    Wait(300)
    
    -- Téléporter
    SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
    SetEntityHeading(ped, spawn.w)
    
    -- Heal complet
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    
    -- Clear wounds
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    
    -- DONNER UNIQUEMENT LE CAL50
    RemoveAllPedWeapons(ped, true)
    GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL50'), 250, false, true)
    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_PISTOL50'), true)
    
    -- Munitions infinies
    SetPedInfiniteAmmoClip(ped, true)
    
    Wait(300)
    
    -- Fade in RAPIDE
    DoScreenFadeIn(300)
    
    print('^2[PVP CLIENT]^7 Respawn terminé')
end)

-- Event pour freeze un joueur
RegisterNetEvent('pvp:freezePlayer', function()
    print('^2[PVP CLIENT]^7 Freeze du joueur')
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
end)

-- Event pour le début d'un round
RegisterNetEvent('pvp:roundStart', function(roundNumber)
    print(string.format('^2[PVP CLIENT]^7 Début du round %d', roundNumber))
    
    local ped = PlayerPedId()
    
    -- FREEZE le joueur
    FreezeEntityPosition(ped, true)
    
    -- Animation "ROUND X"
    SendNUIMessage({
        action = 'showRoundStart',
        round = roundNumber
    })
    
    Wait(2000)
    
    -- Countdown 3-2-1
    for i = 3, 1, -1 do
        SendNUIMessage({
            action = 'showCountdown',
            number = i
        })
        PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
        Wait(1000)
    end
    
    -- GO!
    SendNUIMessage({
        action = 'showGo'
    })
    PlaySoundFrontend(-1, "GO", "HUD_MINI_GAME_SOUNDSET", true)
    
    Wait(1000)
    
    -- UNFREEZE le joueur
    FreezeEntityPosition(ped, false)
end)

-- Event pour la fin d'un round
RegisterNetEvent('pvp:roundEnd', function(winningTeam, score)
    print(string.format('^2[PVP CLIENT]^7 Fin du round - Gagnant: %s', winningTeam))
    
    -- Animation HTML
    SendNUIMessage({
        action = 'showRoundEnd',
        winner = winningTeam,
        score = score
    })
    
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
end)

-- Event pour mettre à jour le score
RegisterNetEvent('pvp:updateScore', function(score, round)
    print(string.format('^2[PVP CLIENT]^7 Mise à jour score - Team1: %d, Team2: %d, Round: %d', score.team1, score.team2, round))
    
    SendNUIMessage({
        action = 'updateScore',
        score = score,
        round = round
    })
end)

-- Event pour afficher le HUD de score
RegisterNetEvent('pvp:showScoreHUD', function(score, round)
    print('^2[PVP CLIENT]^7 Affichage HUD de score')
    
    SendNUIMessage({
        action = 'showScoreHUD',
        score = score,
        round = round
    })
end)

-- Event pour masquer le HUD de score
RegisterNetEvent('pvp:hideScoreHUD', function()
    print('^2[PVP CLIENT]^7 Masquage HUD de score')
    
    SendNUIMessage({
        action = 'hideScoreHUD'
    })
end)

-- Event pour la fin du match
RegisterNetEvent('pvp:matchEnd', function(victory, score)
    print(string.format('^2[PVP CLIENT]^7 Fin du match - Victoire: %s', tostring(victory)))
    
    inMatch = false
    
    -- Animation HTML
    SendNUIMessage({
        action = 'showMatchEnd',
        victory = victory,
        score = score
    })
    
    if victory then
        PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS", true)
    else
        PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", true)
    end
    
    -- Attendre l'animation
    Wait(8000)
    
    -- RESSUSCITER AVANT DE TÉLÉPORTER
    local ped = PlayerPedId()
    if IsEntityDead(ped) then
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        Wait(100)
    end
    
    -- Téléporter au spawn PVP
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(ped, Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z, false, false, false, false)
    SetEntityHeading(ped, Config.PedLocation.coords.w)
    
    -- Heal complet
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    
    -- Clear wounds
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    
    -- Retirer TOUTES les armes
    RemoveAllPedWeapons(ped, true)
    
    -- Désactiver les munitions infinies
    SetPedInfiniteAmmoClip(ped, false)
    
    DoScreenFadeIn(500)
    
    ESX.ShowNotification('~b~Retour au lobby')
end)

-- FIX PROBLEME 2: Event pour retour forcé au lobby (déconnexion adverse)
RegisterNetEvent('pvp:forceReturnToLobby', function()
    print('^2[PVP CLIENT]^7 Retour forcé au lobby')
    
    inMatch = false
    
    local ped = PlayerPedId()
    
    -- RESSUSCITER SI MORT
    if IsEntityDead(ped) then
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        Wait(100)
    end
    
    -- Fade out
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Téléporter au spawn PVP
    SetEntityCoords(ped, Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z, false, false, false, false)
    SetEntityHeading(ped, Config.PedLocation.coords.w)
    
    -- Heal et cleanup
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    RemoveAllPedWeapons(ped, true)
    FreezeEntityPosition(ped, false)
    
    -- Désactiver les munitions infinies
    SetPedInfiniteAmmoClip(ped, false)
    
    -- Fade in
    DoScreenFadeIn(500)
end)

-- Détecter la mort du joueur
CreateThread(function()
    while true do
        Wait(1000)
        
        -- Ne vérifier que si on est en match
        if not inMatch then
            goto continue
        end
        
        local ped = PlayerPedId()
        
        if IsEntityDead(ped) then
            local killer = GetPedSourceOfDeath(ped)
            local killerPlayer = nil
            
            if killer and IsEntityAPed(killer) and IsPedAPlayer(killer) then
                killerPlayer = NetworkGetPlayerIndexFromPed(killer)
                if killerPlayer then
                    killerPlayer = GetPlayerServerId(killerPlayer)
                end
            end
            
            print(string.format('^2[PVP CLIENT]^7 Joueur mort - Killer: %s', killerPlayer or 'suicide'))
            
            TriggerServerEvent('pvp:playerDied', killerPlayer)
            
            -- Attendre la résurrection
            while IsEntityDead(ped) do
                Wait(100)
            end
        end
        
        ::continue::
    end
end)

-- FIX PROBLEME 3: Thread STRICT pour bloquer TOUTES les armes sauf Cal50
CreateThread(function()
    local cal50Hash = GetHashKey('WEAPON_PISTOL50')
    
    while true do
        Wait(0)
        
        if inMatch then
            local ped = PlayerPedId()
            
            -- S'assurer qu'on a UNIQUEMENT le Cal50
            local hasWeapon, weaponHash = GetCurrentPedWeapon(ped, true)
            
            -- Si on n'a pas d'arme ou que ce n'est pas le Cal50
            if not hasWeapon or weaponHash ~= cal50Hash then
                print('^3[PVP CLIENT]^7 Arme incorrecte détectée, correction...')
                
                -- Supprimer TOUTES les armes
                RemoveAllPedWeapons(ped, true)
                
                -- Redonner uniquement le Cal50
                GiveWeaponToPed(ped, cal50Hash, 250, false, true)
                SetCurrentPedWeapon(ped, cal50Hash, true)
                SetPedInfiniteAmmoClip(ped, true)
            end
            
            -- Bloquer TOUTES les touches de changement d'arme
            -- Molette
            DisableControlAction(0, 14, true)  -- INPUT_WEAPON_WHEEL_NEXT
            DisableControlAction(0, 15, true)  -- INPUT_WEAPON_WHEEL_PREV
            DisableControlAction(0, 16, true)  -- INPUT_SELECT_NEXT_WEAPON
            DisableControlAction(0, 17, true)  -- INPUT_SELECT_PREV_WEAPON
            
            -- Wheel d'armes (TAB)
            DisableControlAction(0, 37, true)  -- INPUT_SELECT_WEAPON
            
            -- Touches de raccourci 1-9 (tous les slots d'armes)
            DisableControlAction(0, 157, true) -- INPUT_SELECT_WEAPON_UNARMED
            DisableControlAction(0, 158, true) -- INPUT_SELECT_WEAPON_MELEE  
            DisableControlAction(0, 159, true) -- INPUT_SELECT_WEAPON_HANDGUN
            DisableControlAction(0, 160, true) -- INPUT_SELECT_WEAPON_SHOTGUN
            DisableControlAction(0, 161, true) -- INPUT_SELECT_WEAPON_SMG
            DisableControlAction(0, 162, true) -- INPUT_SELECT_WEAPON_AUTO_RIFLE
            DisableControlAction(0, 163, true) -- INPUT_SELECT_WEAPON_SNIPER
            DisableControlAction(0, 164, true) -- INPUT_SELECT_WEAPON_HEAVY
            DisableControlAction(0, 165, true) -- INPUT_SELECT_WEAPON_SPECIAL
            
            -- Ne PAS bloquer le tir - le joueur doit pouvoir tirer avec le Cal50
            -- DisableControlAction(0, 24, true) est retiré pour permettre de tirer
            
        else
            -- Hors match, attendre plus longtemps
            Wait(500)
        end
    end
end)

-- Thread pour mettre à jour le timer de recherche
CreateThread(function()
    while true do
        Wait(1000)
        
        if inQueue then
            local elapsed = math.floor((GetGameTimer() - queueStartTime) / 1000)
            
            SendNUIMessage({
                action = 'updateSearchTimer',
                elapsed = elapsed
            })
        end
    end
end)

CreateThread(function()
    print('^2[PVP CLIENT]^7 Thread principal démarré')
    SpawnPed()
    
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local pedCoords = vector3(Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z)
        local distance = #(playerCoords - pedCoords)
        
        if distance < Config.InteractionDistance then
            sleep = 0
            
            ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le menu PVP')
            
            if Config.DrawMarker then
                DrawMarker(2, pedCoords.x, pedCoords.y, pedCoords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 0, 0, 200, true, true, 2, false, nil, nil, false)
            end
            
            if IsControlJustReleased(0, 38) then
                print('^2[PVP CLIENT]^7 Touche E pressée près du PED')
                OpenUI()
            end
        end
        
        Wait(sleep)
    end
end)

-- Nettoyer le PED à la déconnexion
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^2[PVP CLIENT]^7 Resource arrêtée, nettoyage...')
    
    if DoesEntityExist(pedEntity) then
        DeleteEntity(pedEntity)
        print('^2[PVP CLIENT]^7 PED supprimé')
    end
    
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    print('^2[PVP CLIENT]^7 Focus NUI libéré')
end)

print('^2[PVP CLIENT]^7 Initialisation terminée')