DebugSuccess('Script chargé')

local pedSpawned = false
local pedEntity = nil
local uiOpen = false
local inQueue = false
local queueStartTime = 0
local inMatch = false
local playerTeam = nil

-- ========================================
-- CACHE DES NATIVES POUR PERFORMANCES
-- ========================================
local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local IsControlJustReleased = IsControlJustReleased
local Wait = Wait
local GetGameTimer = GetGameTimer
local GetHashKey = GetHashKey
local IsEntityDead = IsEntityDead
local GetPedSourceOfDeath = GetPedSourceOfDeath
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local GetPlayerServerId = GetPlayerServerId

-- ========================================
-- SPAWN PED
-- ========================================
local function SpawnPed()
    if pedSpawned then 
        DebugWarn('PED déjà spawné')
        return 
    end
    
    DebugClient('Début spawn PED')
    local pedModel = GetHashKey(Config.PedLocation.model)
    
    DebugClient('Requête modèle: %s', Config.PedLocation.model)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(100)
    end
    DebugClient('Modèle chargé')
    
    pedEntity = CreatePed(4, pedModel, Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z - 1.0, Config.PedLocation.coords.w, false, true)
    DebugClient('PED créé, entity: %d', pedEntity)
    
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
    DebugSuccess('PED spawné avec succès')
end

-- ========================================
-- UI
-- ========================================
local function OpenUI()
    if uiOpen then 
        DebugWarn('UI déjà ouverte')
        return 
    end
    
    DebugClient('Ouverture de l\'UI')
    
    SetNuiFocus(true, true)
    DebugClient('SetNuiFocus(true, true) appelé')
    
    SendNUIMessage({
        action = 'openUI'
    })
    DebugClient('Message openUI envoyé')
    
    uiOpen = true
    DebugClient('UI ouverte (uiOpen = true)')
end

local function CloseUI()
    if not uiOpen then 
        DebugWarn('UI déjà fermée')
        return 
    end
    
    DebugClient('Fermeture de l\'UI')
    
    SendNUIMessage({
        action = 'closeUI'
    })
    DebugClient('Message closeUI envoyé au NUI')
    
    Wait(100)
    
    SetNuiFocus(false, false)
    DebugClient('SetNuiFocus(false, false) appelé')
    
    SetNuiFocusKeepInput(false)
    DebugClient('SetNuiFocusKeepInput(false) appelé')
    
    uiOpen = false
    DebugClient('UI fermée (uiOpen = false)')
end

-- ========================================
-- NUI CALLBACKS
-- ========================================
RegisterNUICallback('closeUI', function(data, cb)
    DebugClient('Callback closeUI reçu du NUI')
    cb('ok')
    DebugClient('Callback répondu')
    Wait(50)
    CloseUI()
end)

RegisterNetEvent('pvp:forceCloseUI', function()
    DebugClient('Event pvp:forceCloseUI reçu')
    CloseUI()
end)

RegisterNUICallback('joinQueue', function(data, cb)
    DebugClient('Callback joinQueue reçu - Mode: %s', data.mode)
    cb('ok')
    
    TriggerServerEvent('pvp:joinQueue', data.mode)
    DebugClient('Event pvp:joinQueue envoyé au serveur')
end)

RegisterNUICallback('getStats', function(data, cb)
    DebugClient('Callback getStats reçu')
    ESX.TriggerServerCallback('pvp:getPlayerStats', function(stats)
        DebugClient('Stats reçues: %s', json.encode(stats))
        cb(stats)
    end)
end)

RegisterNUICallback('getLeaderboard', function(data, cb)
    DebugClient('Callback getLeaderboard reçu')
    ESX.TriggerServerCallback('pvp:getLeaderboard', function(leaderboard)
        DebugClient('Leaderboard reçu: %d entrées', #leaderboard)
        cb(leaderboard)
    end)
end)

RegisterNUICallback('invitePlayer', function(data, cb)
    local targetId = tonumber(data.targetId)
    DebugClient('Callback invitePlayer reçu - Target ID: %d', targetId)
    cb('ok')
    
    TriggerServerEvent('pvp:inviteToGroup', targetId)
    DebugClient('Event pvp:inviteToGroup envoyé')
end)

RegisterNUICallback('leaveGroup', function(data, cb)
    DebugClient('Callback leaveGroup reçu')
    cb('ok')
    
    TriggerServerEvent('pvp:leaveGroup')
    DebugClient('Event pvp:leaveGroup envoyé')
end)

RegisterNUICallback('kickPlayer', function(data, cb)
    local targetId = tonumber(data.targetId)
    DebugClient('Callback kickPlayer reçu - Target ID: %d', targetId)
    cb('ok')
    
    TriggerServerEvent('pvp:kickFromGroup', targetId)
    DebugClient('Event pvp:kickFromGroup envoyé')
end)

RegisterNUICallback('toggleReady', function(data, cb)
    DebugClient('Callback toggleReady reçu')
    cb('ok')
    
    TriggerServerEvent('pvp:toggleReady')
    DebugClient('Event pvp:toggleReady envoyé')
end)

RegisterNUICallback('getGroupInfo', function(data, cb)
    DebugClient('Callback getGroupInfo reçu')
    ESX.TriggerServerCallback('pvp:getGroupInfo', function(groupInfo)
        DebugClient('GroupInfo reçu: %s', json.encode(groupInfo))
        cb(groupInfo)
    end)
end)

RegisterNUICallback('acceptInvite', function(data, cb)
    local inviterId = tonumber(data.inviterId)
    DebugClient('Callback acceptInvite reçu - Inviter ID: %d', inviterId)
    cb('ok')
    
    TriggerServerEvent('pvp:acceptInvite', inviterId)
    DebugClient('Event pvp:acceptInvite envoyé')
end)

RegisterNUICallback('declineInvite', function(data, cb)
    DebugClient('Callback declineInvite reçu')
    cb('ok')
end)

RegisterNUICallback('cancelSearch', function(data, cb)
    DebugClient('Callback cancelSearch reçu')
    cb('ok')
    
    TriggerServerEvent('pvp:cancelSearch')
    DebugClient('Event pvp:cancelSearch envoyé')
end)

-- ========================================
-- EVENTS RÉSEAU
-- ========================================
RegisterNetEvent('pvp:updateGroupUI', function(groupData)
    DebugClient('Event pvp:updateGroupUI reçu: %s', json.encode(groupData))
    SendNUIMessage({
        action = 'updateGroup',
        group = groupData
    })
    DebugClient('Message updateGroup envoyé au NUI')
end)

RegisterNetEvent('pvp:receiveInvite', function(inviterName, inviterId)
    DebugClient('Event pvp:receiveInvite reçu de: %s (ID: %d)', inviterName, inviterId)
    
    ESX.ShowNotification('~b~' .. inviterName .. '~w~ vous invite à rejoindre son groupe!')
    
    SendNUIMessage({
        action = 'showInvite',
        inviterName = inviterName,
        inviterId = inviterId
    })
    DebugClient('Message showInvite envoyé au NUI (queue système)')
end)

RegisterNetEvent('pvp:searchStarted', function(mode)
    DebugClient('Recherche commencée pour le mode: %s', mode)
    inQueue = true
    queueStartTime = GetGameTimer()
    
    SendNUIMessage({
        action = 'searchStarted',
        mode = mode
    })
end)

RegisterNetEvent('pvp:matchFound', function()
    DebugSuccess('Match trouvé!')
    inQueue = false
    inMatch = true
    
    if uiOpen then
        DebugClient('Fermeture de l\'UI (match trouvé)')
        CloseUI()
    end
    
    SendNUIMessage({
        action = 'matchFound'
    })
end)

RegisterNetEvent('pvp:searchCancelled', function()
    DebugClient('Recherche annulée')
    inQueue = false
    
    SendNUIMessage({
        action = 'searchCancelled'
    })
end)

RegisterNetEvent('pvp:teleportToSpawn', function(spawn, team, matchId, arenaKey)
    DebugClient('Téléportation au spawn - Team: %s, Match: %d, Arène: %s', team, matchId, arenaKey or 'unknown')
    DebugClient('Coordonnées: %.2f, %.2f, %.2f, %.2f', spawn.x, spawn.y, spawn.z, spawn.w)
    
    playerTeam = team
    DebugClient('Équipe du joueur définie: %s', playerTeam)
    
    local ped = PlayerPedId()
    
    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    end
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
    SetEntityHeading(ped, spawn.w)
    
    FreezeEntityPosition(ped, true)
    
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    
    RemoveAllPedWeapons(ped, true)
    GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL50'), 250, false, true)
    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_PISTOL50'), true)
    
    SetPedInfiniteAmmoClip(ped, true)
    
    Wait(500)
    
    DoScreenFadeIn(500)
    
    local teamColor = team == 'team1' and '~b~' or '~r~'
    ESX.ShowNotification(teamColor .. 'Vous êtes dans la ' .. (team == 'team1' and 'Team A (Bleu)' or 'Team B (Rouge)'))
    
    if arenaKey then
        DebugClient('🟢 Activation de la zone pour l\'arène: %s', arenaKey)
        TriggerEvent('pvp:setArenaZone', arenaKey)
        TriggerEvent('pvp:enableZones')
    else
        DebugError('⚠️ ERREUR: Pas d\'arenaKey fournie!')
    end
    
    DebugClient('Téléportation terminée, joueur freeze')
end)

RegisterNetEvent('pvp:respawnPlayer', function(spawn)
    DebugClient('Respawn du joueur')
    
    local ped = PlayerPedId()
    
    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    end
    
    DoScreenFadeOut(300)
    Wait(300)
    
    SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
    SetEntityHeading(ped, spawn.w)
    
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    
    RemoveAllPedWeapons(ped, true)
    GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL50'), 250, false, true)
    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_PISTOL50'), true)
    
    SetPedInfiniteAmmoClip(ped, true)
    
    Wait(300)
    
    DoScreenFadeIn(300)
    
    DebugClient('Respawn terminé')
end)

RegisterNetEvent('pvp:freezePlayer', function()
    DebugClient('Freeze du joueur')
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
end)

RegisterNetEvent('pvp:roundStart', function(roundNumber)
    DebugClient('Début du round %d', roundNumber)
    
    local ped = PlayerPedId()
    
    FreezeEntityPosition(ped, true)
    
    SendNUIMessage({
        action = 'showRoundStart',
        round = roundNumber
    })
    
    Wait(2000)
    
    for i = 3, 1, -1 do
        SendNUIMessage({
            action = 'showCountdown',
            number = i
        })
        PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
        Wait(1000)
    end
    
    SendNUIMessage({
        action = 'showGo'
    })
    PlaySoundFrontend(-1, "GO", "HUD_MINI_GAME_SOUNDSET", true)
    
    Wait(1000)
    
    FreezeEntityPosition(ped, false)
end)

RegisterNetEvent('pvp:roundEnd', function(winningTeam, score)
    DebugClient('Fin du round - Équipe gagnante: %s, Mon équipe: %s, Victoire: %s', 
        winningTeam, playerTeam or 'unknown', tostring(winningTeam == playerTeam))
    
    SendNUIMessage({
        action = 'showRoundEnd',
        winner = winningTeam,
        score = score,
        playerTeam = playerTeam,
        isVictory = (winningTeam == playerTeam)
    })
    
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
end)

RegisterNetEvent('pvp:updateScore', function(score, round)
    DebugClient('Mise à jour score - Team1: %d, Team2: %d, Round: %d', score.team1, score.team2, round)
    
    SendNUIMessage({
        action = 'updateScore',
        score = score,
        round = round
    })
end)

RegisterNetEvent('pvp:showScoreHUD', function(score, round)
    DebugClient('Affichage HUD de score')
    
    SendNUIMessage({
        action = 'showScoreHUD',
        score = score,
        round = round
    })
end)

RegisterNetEvent('pvp:hideScoreHUD', function()
    DebugClient('Masquage HUD de score')
    
    SendNUIMessage({
        action = 'hideScoreHUD'
    })
end)

RegisterNetEvent('pvp:matchEnd', function(victory, score)
    DebugClient('Fin du match - Victoire: %s', tostring(victory))
    
    inMatch = false
    
    DebugClient('🔴 Désactivation du système de zones')
    TriggerEvent('pvp:disableZones')
    
    SendNUIMessage({
        action = 'showMatchEnd',
        victory = victory,
        score = score,
        playerTeam = playerTeam
    })
    
    if victory then
        PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS", true)
    else
        PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", true)
    end
    
    Wait(8000)
    
    playerTeam = nil
    DebugClient('Équipe du joueur réinitialisée')
    
    local ped = PlayerPedId()
    if IsEntityDead(ped) then
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        Wait(100)
    end
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(ped, Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z, false, false, false, false)
    SetEntityHeading(ped, Config.PedLocation.coords.w)
    
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    
    RemoveAllPedWeapons(ped, true)
    
    SetPedInfiniteAmmoClip(ped, false)
    
    DoScreenFadeIn(500)
    
    ESX.ShowNotification('~b~Retour au lobby')
end)

RegisterNetEvent('pvp:forceReturnToLobby', function()
    DebugClient('Retour forcé au lobby')
    
    inMatch = false
    
    DebugClient('🔴 Désactivation du système de zones (retour forcé)')
    TriggerEvent('pvp:disableZones')
    
    playerTeam = nil
    DebugClient('Équipe du joueur réinitialisée (retour forcé)')
    
    local ped = PlayerPedId()
    
    if IsEntityDead(ped) then
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        Wait(100)
    end
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(ped, Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z, false, false, false, false)
    SetEntityHeading(ped, Config.PedLocation.coords.w)
    
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    RemoveAllPedWeapons(ped, true)
    FreezeEntityPosition(ped, false)
    
    SetPedInfiniteAmmoClip(ped, false)
    
    DoScreenFadeIn(500)
end)

-- ========================================
-- THREAD: DÉTECTION MORT (OPTIMISÉ - NE TOURNE QUE EN MATCH)
-- ========================================
CreateThread(function()
    while true do
        -- ⚡ OPTIMISATION: Sleep long si pas en match
        if not inMatch then
            Wait(2000)
            goto continue
        end
        
        Wait(1000) -- Check toutes les secondes (suffisant)
        
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
            
            DebugClient('Joueur mort - Killer: %s', killerPlayer or 'suicide')
            
            TriggerServerEvent('pvp:playerDied', killerPlayer)
            
            -- Attendre la résurrection
            while IsEntityDead(ped) do
                Wait(500) -- Augmenté de 100 à 500ms
            end
        end
        
        ::continue::
    end
end)

-- ========================================
-- THREAD: BLOCAGE ARMES (ULTRA-OPTIMISÉ)
-- ========================================
CreateThread(function()
    local cal50Hash = GetHashKey('WEAPON_PISTOL50')
    local lastCheck = 0
    local checkInterval = 250 -- Vérifier toutes les 250ms au lieu de chaque frame
    
    while true do
        -- ⚡ OPTIMISATION: Sleep long si pas en match
        if not inMatch then
            Wait(1000)
            goto continue
        end
        
        Wait(0) -- Pour les DisableControlAction
        
        local currentTime = GetGameTimer()
        
        -- Vérifier l'arme seulement toutes les 250ms
        if currentTime - lastCheck >= checkInterval then
            lastCheck = currentTime
            
            local ped = PlayerPedId()
            local hasWeapon, weaponHash = GetCurrentPedWeapon(ped, true)
            
            if not hasWeapon or weaponHash ~= cal50Hash then
                RemoveAllPedWeapons(ped, true)
                GiveWeaponToPed(ped, cal50Hash, 250, false, true)
                SetCurrentPedWeapon(ped, cal50Hash, true)
                SetPedInfiniteAmmoClip(ped, true)
            end
        end
        
        -- Désactiver les contrôles de changement d'arme
        DisableControlAction(0, 14, true)  -- Scroll up
        DisableControlAction(0, 15, true)  -- Scroll down
        DisableControlAction(0, 16, true)  -- Next weapon
        DisableControlAction(0, 17, true)  -- Select weapon
        DisableControlAction(0, 37, true)  -- Weapon wheel
        DisableControlAction(0, 157, true) -- 1
        DisableControlAction(0, 158, true) -- 2
        DisableControlAction(0, 159, true) -- 3
        DisableControlAction(0, 160, true) -- 4
        DisableControlAction(0, 161, true) -- 5
        DisableControlAction(0, 162, true) -- 6
        DisableControlAction(0, 163, true) -- 7
        DisableControlAction(0, 164, true) -- 8
        DisableControlAction(0, 165, true) -- 9
        
        ::continue::
    end
end)

-- ========================================
-- THREAD: TIMER DE RECHERCHE
-- ========================================
CreateThread(function()
    while true do
        Wait(1000) -- OK à 1000ms
        
        if inQueue then
            local elapsed = math.floor((GetGameTimer() - queueStartTime) / 1000)
            
            SendNUIMessage({
                action = 'updateSearchTimer',
                elapsed = elapsed
            })
        end
    end
end)

-- ========================================
-- THREAD: INTERACTION PED (OPTIMISÉ - DISTANCE ADAPTATIVE)
-- ========================================
CreateThread(function()
    DebugClient('Thread principal démarré')
    SpawnPed()
    
    local pedCoords = vector3(Config.PedLocation.coords.x, Config.PedLocation.coords.y, Config.PedLocation.coords.z)
    
    while true do
        local sleep = 1000 -- Sleep par défaut: 1 seconde
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - pedCoords)
        
        -- ⚡ OPTIMISATION: Sleep adaptatif selon la distance
        if distance < 50.0 then
            sleep = 500 -- Proche: check toutes les 500ms
            
            if distance < Config.InteractionDistance then
                sleep = 0 -- Très proche: check chaque frame
                
                ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le menu PVP')
                
                if Config.DrawMarker then
                    DrawMarker(2, pedCoords.x, pedCoords.y, pedCoords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 0, 0, 200, true, true, 2, false, nil, nil, false)
                end
                
                if IsControlJustReleased(0, 38) then
                    DebugClient('Touche E pressée près du PED')
                    OpenUI()
                end
            end
        end
        -- Sinon sleep = 1000ms (loin du PED)
        
        Wait(sleep)
    end
end)

-- ========================================
-- CLEANUP
-- ========================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugClient('Resource arrêtée, nettoyage...')
    
    if DoesEntityExist(pedEntity) then
        DeleteEntity(pedEntity)
        DebugClient('PED supprimé')
    end
    
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    DebugClient('Focus NUI libéré')
end)

DebugSuccess('Initialisation terminée (version OPTIMISÉE)')
