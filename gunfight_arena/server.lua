-- ================================================================================================
-- GUNFIGHT ARENA - SERVER v3.2 (CORRIGÉ - NOMS DES JOUEURS DÉCONNECTÉS)
-- ================================================================================================
-- ✅ NOUVEAU : Les noms des joueurs s'affichent correctement dans le classement même déconnectés
-- ✅ Sauvegarde automatique du nom du joueur dans la BDD
-- ✅ Jointure SQL optionnelle avec la table users si la colonne player_name n'existe pas
-- ================================================================================================

local ESX = exports['es_extended']:getSharedObject()

-- Tables de suivi
local arenaPlayers = {}
local playerZone = {}
local playerBucket = {}
local zonePlayerCounts = {[1]=0,[2]=0,[3]=0,[4]=0}
local PlayerStats = {}
local killStreaks = {}
local playerJoinTime = {}
local globalLeaderboard = {}
local lastLeaderboardUpdate = 0

-- ================================================================================================
-- FONCTION : LOG DEBUG SERVER
-- ================================================================================================
local function DebugLog(message, type)
    if not Config.DebugServer then return end
    local prefix = type == "error" and "^1[GF-Server ERROR]^0" or type == "success" and "^2[GF-Server OK]^0" or type == "instance" and "^5[GF-Instance]^0" or type == "database" and "^6[GF-Database]^0" or "^3[GF-Server]^0"
    print(prefix .. " " .. message)
end

-- ================================================================================================
-- FONCTION : CHARGER LES STATS DU JOUEUR
-- ================================================================================================
local function LoadPlayerStats(identifier, playerName, callback)
    if not Config.SaveStatsToDatabase then
        callback({kills=0,deaths=0,headshots=0,best_streak=0,total_playtime=0})
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM gunfight_stats WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            -- 🆕 Mise à jour du nom si nécessaire (en cas de changement de pseudo)
            if playerName and result[1].player_name ~= playerName then
                MySQL.Async.execute('UPDATE gunfight_stats SET player_name = @name WHERE identifier = @identifier', {
                    ['@name'] = playerName,
                    ['@identifier'] = identifier
                })
                DebugLog("Nom mis à jour : " .. playerName, "database")
            end
            callback(result[1])
        else
            -- Créer une nouvelle entrée avec le nom du joueur
            MySQL.Async.execute('INSERT INTO gunfight_stats (identifier, player_name, kills, deaths, headshots, best_streak, total_playtime) VALUES (@identifier, @name, 0, 0, 0, 0, 0)', {
                ['@identifier'] = identifier,
                ['@name'] = playerName or 'Joueur Inconnu'
            }, function()
                DebugLog("Nouveau joueur créé : " .. (playerName or 'Inconnu'), "database")
                callback({kills=0,deaths=0,headshots=0,best_streak=0,total_playtime=0})
            end)
        end
    end)
end

-- ================================================================================================
-- FONCTION : SAUVEGARDER LES STATS DU JOUEUR
-- ================================================================================================
local function SavePlayerStats(identifier, playerName, stats)
    if not Config.SaveStatsToDatabase then return end
    
    MySQL.Async.execute([[
        UPDATE gunfight_stats 
        SET player_name = @name, kills = @kills, deaths = @deaths, headshots = @headshots, best_streak = @best_streak, total_playtime = @total_playtime, last_played = NOW()
        WHERE identifier = @identifier
    ]], {
        ['@identifier'] = identifier,
        ['@name'] = playerName or 'Joueur Inconnu',
        ['@kills'] = stats.kills,
        ['@deaths'] = stats.deaths,
        ['@headshots'] = stats.headshots or 0,
        ['@best_streak'] = stats.best_streak or 0,
        ['@total_playtime'] = stats.total_playtime or 0
    })
end

-- ================================================================================================
-- FONCTION : OBTENIR LE CLASSEMENT GLOBAL (CORRIGÉ v3.2)
-- ================================================================================================
local function GetGlobalLeaderboard(callback)
    if not Config.SaveStatsToDatabase then
        callback({})
        return
    end
    
    -- Récupère le classement depuis la table gunfight_stats (avec player_name)
    MySQL.Async.fetchAll([[
        SELECT 
            identifier, 
            player_name,
            kills, 
            deaths, 
            headshots, 
            best_streak,
            CASE WHEN deaths > 0 THEN ROUND(kills / deaths, 2) ELSE kills END as kd_ratio
        FROM gunfight_stats
        ORDER BY kd_ratio DESC, kills DESC
        LIMIT @limit
    ]], {
        ['@limit'] = Config.LeaderboardLimit
    }, function(result)
        local leaderboard = {}
        
        for i, data in ipairs(result) do
            -- Utilise le nom de la BDD en priorité
            local playerName = data.player_name or "Joueur Inconnu"
            
            -- Si le joueur est connecté, utiliser son nom en temps réel (optionnel)
            for _, playerId in ipairs(GetPlayers()) do
                local xPlayer = ESX.GetPlayerFromId(tonumber(playerId))
                if xPlayer and xPlayer.identifier == data.identifier then
                    playerName = xPlayer.getName()
                    break
                end
            end
            
            table.insert(leaderboard, {
                rank = i,
                player = playerName,
                kills = data.kills,
                deaths = data.deaths,
                headshots = data.headshots,
                best_streak = data.best_streak,
                kd = data.kd_ratio
            })
        end
        
        DebugLog("Classement chargé : " .. #leaderboard .. " joueurs", "database")
        callback(leaderboard)
    end)
end

-- ================================================================================================
-- FONCTION : METTRE À JOUR LE CLASSEMENT GLOBAL
-- ================================================================================================
local function UpdateGlobalLeaderboard()
    GetGlobalLeaderboard(function(leaderboard)
        globalLeaderboard = leaderboard
        lastLeaderboardUpdate = os.time()
        DebugLog("Classement global mis à jour", "success")
    end)
end

-- ================================================================================================
-- FONCTION : OBTENIR LES STATS D'UN JOUEUR
-- ================================================================================================
function GetPlayerStats(id)
    if not PlayerStats[id] then
        PlayerStats[id] = {
            kills = 0,
            deaths = 0,
            headshots = 0,
            best_streak = 0,
            total_playtime = 0
        }
        
        if Config.SaveStatsToDatabase then
            local xPlayer = ESX.GetPlayerFromId(id)
            if xPlayer then
                LoadPlayerStats(xPlayer.identifier, xPlayer.getName(), function(dbStats)
                    PlayerStats[id].kills = dbStats.kills
                    PlayerStats[id].deaths = dbStats.deaths
                    PlayerStats[id].headshots = dbStats.headshots or 0
                    PlayerStats[id].best_streak = dbStats.best_streak or 0
                    PlayerStats[id].total_playtime = dbStats.total_playtime or 0
                end)
            end
        end
    end
    return PlayerStats[id]
end

-- ================================================================================================
-- FONCTION : GÉRER LES INSTANCES (ROUTING BUCKETS)
-- ================================================================================================
local function SetPlayerInstance(source, bucketId)
    if not Config.UseInstances then return end
    
    SetPlayerRoutingBucket(source, bucketId)
    local playerPed = GetPlayerPed(source)
    SetEntityRoutingBucket(playerPed, bucketId)
    playerBucket[source] = bucketId
    
    DebugLog("Joueur " .. source .. " assigné au bucket " .. bucketId, "instance")
end

local function RemovePlayerFromInstance(source)
    if not Config.UseInstances then return end
    SetPlayerInstance(source, Config.LobbyBucket)
    DebugLog("Joueur " .. source .. " retourné au lobby bucket", "instance")
end

-- ================================================================================================
-- FONCTION : METTRE À JOUR LE NOMBRE DE JOUEURS PAR ZONE
-- ================================================================================================
local function updateZonePlayers()
    local zonesData = {}
    for i = 1, 4 do
        local zoneCfg = Config["Zone" .. i]
        if zoneCfg and zoneCfg.enabled then
            table.insert(zonesData, {
                zone = i,
                players = zonePlayerCounts[i] or 0,
                maxPlayers = zoneCfg.maxPlayers or 15
            })
        end
    end
    TriggerClientEvent('gunfightarena:updateZonePlayers', -1, zonesData)
end

-- ================================================================================================
-- COMMANDE : QUITTER L'ARÈNE
-- ================================================================================================
RegisterCommand(Config.ExitCommand, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if arenaPlayers[source] then
        -- Calculer le temps de jeu
        if playerJoinTime[source] and Config.SaveStatsToDatabase then
            local playTime = os.time() - playerJoinTime[source]
            local stats = GetPlayerStats(source)
            stats.total_playtime = (stats.total_playtime or 0) + playTime
            SavePlayerStats(xPlayer.identifier, xPlayer.getName(), stats)
        end
        
        arenaPlayers[source] = nil
        local zone = playerZone[source]
        
        if zone then
            zonePlayerCounts[zone] = math.max((zonePlayerCounts[zone] or 1) - 1, 0)
            playerZone[source] = nil
        end
        
        RemovePlayerFromInstance(source)
        killStreaks[source] = 0
        playerJoinTime[source] = nil
        updateZonePlayers()
        
        TriggerClientEvent('esx:showNotification', source, Config.Messages.exitArena)
        TriggerClientEvent('gunfightarena:exit', source)
    else
        TriggerClientEvent('esx:showNotification', source, Config.Messages.notInArena)
    end
end, false)

-- ================================================================================================
-- EVENT : SORTIE DE ZONE (NETTOYAGE INSTANCE)
-- ================================================================================================
RegisterNetEvent('gunfightarena:leaveArena')
AddEventHandler('gunfightarena:leaveArena', function()
    local src = source
    
    DebugLog("=== SORTIE DE ZONE (CLIENT) ===")
    DebugLog("Joueur: " .. src)
    
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        DebugLog("Joueur ESX non trouvé", "error")
        return
    end
    
    if arenaPlayers[src] then
        DebugLog("Joueur dans l'arène, nettoyage...")
        
        -- Calculer temps de jeu
        if playerJoinTime[src] and Config.SaveStatsToDatabase then
            local playTime = os.time() - playerJoinTime[src]
            local stats = GetPlayerStats(src)
            stats.total_playtime = (stats.total_playtime or 0) + playTime
            SavePlayerStats(xPlayer.identifier, xPlayer.getName(), stats)
        end
        
        -- Retirer des tables
        arenaPlayers[src] = nil
        local zone = playerZone[src]
        
        if zone then
            zonePlayerCounts[zone] = math.max((zonePlayerCounts[zone] or 1) - 1, 0)
            DebugLog("Zone " .. zone .. " : " .. zonePlayerCounts[zone] .. " joueurs restants")
            playerZone[src] = nil
        end
        
        -- Retirer de l'instance
        RemovePlayerFromInstance(src)
        DebugLog("Joueur retiré de l'instance (bucket " .. Config.LobbyBucket .. ")", "success")
        
        -- Reset
        killStreaks[src] = 0
        playerJoinTime[src] = nil
        
        -- Mise à jour
        updateZonePlayers()
        
        DebugLog("Joueur sorti avec succès", "success")
    else
        DebugLog("Joueur pas dans l'arène", "error")
    end
    
    DebugLog("=================================")
end)

-- ================================================================================================
-- EVENT : DEMANDE DE REJOINDRE UNE ZONE
-- ================================================================================================
RegisterNetEvent('gunfightarena:joinRequest')
AddEventHandler('gunfightarena:joinRequest', function(zoneNumber)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    local zoneCfg = Config["Zone" .. zoneNumber]
    if not zoneCfg or not zoneCfg.enabled then
        TriggerClientEvent('esx:showNotification', src, "Zone non disponible.")
        return
    end
    
    local maxPlayers = zoneCfg.maxPlayers or 15
    if zonePlayerCounts[zoneNumber] >= maxPlayers then
        TriggerClientEvent('esx:showNotification', src, Config.Messages.arenaFull)
        return
    end
    
    if playerZone[src] then
        local oldZone = playerZone[src]
        zonePlayerCounts[oldZone] = math.max((zonePlayerCounts[oldZone] or 1) - 1, 0)
    end
    
    arenaPlayers[src] = true
    playerZone[src] = zoneNumber
    zonePlayerCounts[zoneNumber] = (zonePlayerCounts[zoneNumber] or 0) + 1
    playerJoinTime[src] = os.time()
    
    if Config.UseInstances then
        local bucketId = Config.ZoneBuckets[zoneNumber]
        if bucketId then
            SetPlayerInstance(src, bucketId)
            TriggerClientEvent('esx:showNotification', src, Config.Messages.instanceJoined .. " " .. zoneNumber)
        end
    end
    
    GetPlayerStats(src)
    killStreaks[src] = 0
    updateZonePlayers()
    
    TriggerClientEvent('gunfightarena:join', src, zoneNumber)
    TriggerClientEvent('esx:showNotification', src, Config.Messages.enterArena)
end)

-- ================================================================================================
-- EVENT : MORT DU JOUEUR
-- ================================================================================================
RegisterNetEvent('gunfightarena:playerDied')
AddEventHandler('gunfightarena:playerDied', function(respawnIndex, killerId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    local stats = GetPlayerStats(src)
    stats.deaths = stats.deaths + 1
    killStreaks[src] = 0
    
    if Config.SaveStatsToDatabase then
        SavePlayerStats(xPlayer.identifier, xPlayer.getName(), stats)
    end
    
    TriggerClientEvent('esx:showNotification', src, Config.Messages.playerDied)
    TriggerClientEvent('gunfightarena:join', src, 0)
    
    if killerId and killerId ~= src then
        local killer = ESX.GetPlayerFromId(killerId)
        
        if killer then
            killStreaks[killerId] = (killStreaks[killerId] or 0) + 1
            
            local killerStats = GetPlayerStats(killerId)
            killerStats.kills = killerStats.kills + 1
            
            if killStreaks[killerId] > killerStats.best_streak then
                killerStats.best_streak = killStreaks[killerId]
            end
            
            if Config.SaveStatsToDatabase then
                SavePlayerStats(killer.identifier, killer.getName(), killerStats)
            end
            
            local reward = Config.RewardAmount
            killer.addAccountMoney(Config.RewardAccount, reward)
            
            if Config.KillStreakBonus.enabled then
                local bonus = Config.KillStreakBonus[killStreaks[killerId]]
                if bonus then
                    killer.addAccountMoney(Config.RewardAccount, bonus)
                    TriggerClientEvent('esx:showNotification', killerId, "^2KILL STREAK x" .. killStreaks[killerId] .. "! Bonus: $" .. bonus)
                    reward = reward + bonus
                end
            end
            
            TriggerClientEvent('esx:showNotification', killerId, Config.Messages.killRecorded .. reward)
            
            local killerName = killer.getName()
            local victimName = xPlayer.getName()
            local headshot = false
            local multiplier = killStreaks[killerId]
            
            TriggerClientEvent('gunfightarena:killFeed', -1, killerName, victimName, headshot, multiplier, killerId)
        end
    end
end)

-- ================================================================================================
-- EVENT : DÉCONNEXION DU JOUEUR
-- ================================================================================================
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    if arenaPlayers[src] then
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if playerJoinTime[src] and Config.SaveStatsToDatabase and xPlayer then
            local playTime = os.time() - playerJoinTime[src]
            local stats = GetPlayerStats(src)
            stats.total_playtime = (stats.total_playtime or 0) + playTime
            SavePlayerStats(xPlayer.identifier, xPlayer.getName(), stats)
        end
        
        arenaPlayers[src] = nil
        
        local zone = playerZone[src]
        if zone then
            zonePlayerCounts[zone] = math.max((zonePlayerCounts[zone] or 1) - 1, 0)
            playerZone[src] = nil
        end
        
        if playerBucket[src] then
            playerBucket[src] = nil
        end
        
        killStreaks[src] = nil
        playerJoinTime[src] = nil
        PlayerStats[src] = nil
        
        updateZonePlayers()
    end
end)

-- ================================================================================================
-- EVENT : OBTENIR LES STATS EN JEU (TOUCHE G)
-- ================================================================================================
RegisterNetEvent('gunfightarena:getStats')
AddEventHandler('gunfightarena:getStats', function()
    local src = source
    
    if not arenaPlayers[src] then
        TriggerClientEvent('esx:showNotification', src, Config.Messages.accessStats)
        return
    end
    
    local leaderboard = {}
    for id, stats in pairs(PlayerStats) do
        local xPlayer = ESX.GetPlayerFromId(id)
        local playerName = xPlayer and xPlayer.getName() or "Inconnu"
        table.insert(leaderboard, {
            player = playerName,
            kills = stats.kills,
            deaths = stats.deaths,
            kd = (stats.deaths > 0 and (stats.kills / stats.deaths) or stats.kills)
        })
    end
    
    table.sort(leaderboard, function(a, b) return a.kd > b.kd end)
    TriggerClientEvent('gunfightarena:statsData', src, leaderboard)
end)

-- ================================================================================================
-- EVENT : OBTENIR LES STATS PERSONNELLES
-- ================================================================================================
RegisterNetEvent('gunfightarena:getPersonalStats')
AddEventHandler('gunfightarena:getPersonalStats', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    if Config.SaveStatsToDatabase then
        LoadPlayerStats(xPlayer.identifier, xPlayer.getName(), function(dbStats)
            local sessionStats = GetPlayerStats(src)
            local personalStats = {
                player = xPlayer.getName(),
                kills = dbStats.kills,
                deaths = dbStats.deaths,
                headshots = dbStats.headshots,
                best_streak = dbStats.best_streak,
                total_playtime = dbStats.total_playtime,
                kd = (dbStats.deaths > 0 and (dbStats.kills / dbStats.deaths) or dbStats.kills),
                current_streak = killStreaks[src] or 0,
                session_kills = sessionStats.kills - dbStats.kills,
                session_deaths = sessionStats.deaths - dbStats.deaths
            }
            TriggerClientEvent('gunfightarena:personalStatsData', src, personalStats)
        end)
    else
        local stats = GetPlayerStats(src)
        local personalStats = {
            player = xPlayer.getName(),
            kills = stats.kills,
            deaths = stats.deaths,
            headshots = stats.headshots or 0,
            best_streak = stats.best_streak or 0,
            total_playtime = 0,
            kd = (stats.deaths > 0 and (stats.kills / stats.deaths) or stats.kills),
            current_streak = killStreaks[src] or 0,
            session_kills = stats.kills,
            session_deaths = stats.deaths
        }
        TriggerClientEvent('gunfightarena:personalStatsData', src, personalStats)
    end
end)

-- ================================================================================================
-- EVENT : OBTENIR LE CLASSEMENT GLOBAL
-- ================================================================================================
RegisterNetEvent('gunfightarena:getGlobalLeaderboard')
AddEventHandler('gunfightarena:getGlobalLeaderboard', function()
    local src = source
    
    if os.time() - lastLeaderboardUpdate > Config.LeaderboardUpdateInterval then
        UpdateGlobalLeaderboard()
        Citizen.Wait(1000)
    end
    
    if #globalLeaderboard > 0 then
        TriggerClientEvent('gunfightarena:globalLeaderboardData', src, globalLeaderboard)
    else
        GetGlobalLeaderboard(function(leaderboard)
            TriggerClientEvent('gunfightarena:globalLeaderboardData', src, leaderboard)
        end)
    end
end)

-- ================================================================================================
-- EVENT : OBTENIR LE CLASSEMENT DU LOBBY
-- ================================================================================================
RegisterNetEvent('gunfightarena:getLobbyScoreboard')
AddEventHandler('gunfightarena:getLobbyScoreboard', function()
    local src = source
    
    if os.time() - lastLeaderboardUpdate > Config.LeaderboardUpdateInterval then
        UpdateGlobalLeaderboard()
        Citizen.Wait(500)
    end
    
    if #globalLeaderboard > 0 then
        TriggerClientEvent('gunfightarena:lobbyScoreboardData', src, globalLeaderboard)
    else
        GetGlobalLeaderboard(function(leaderboard)
            TriggerClientEvent('gunfightarena:lobbyScoreboardData', src, leaderboard)
        end)
    end
end)

-- ================================================================================================
-- EVENT : DEMANDE DE MISE À JOUR DES ZONES
-- ================================================================================================
RegisterNetEvent('gunfightarena:requestZoneUpdate')
AddEventHandler('gunfightarena:requestZoneUpdate', function()
    updateZonePlayers()
end)

-- ================================================================================================
-- THREAD : MISE À JOUR AUTOMATIQUE DU CLASSEMENT
-- ================================================================================================
if Config.SaveStatsToDatabase and Config.LeaderboardUpdateInterval > 0 then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.LeaderboardUpdateInterval * 1000)
            UpdateGlobalLeaderboard()
        end
    end)
end

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Wait(1000)
    print("^2[Gunfight Arena v3.2]^0 Server démarré")
    print("^3[Gunfight Arena v3.2]^0 Correction : ^2Noms des joueurs déconnectés affichés^0")
    
    if Config.SaveStatsToDatabase then
        UpdateGlobalLeaderboard()
    end
end)
