-- Tables pour gérer les queues et matchs
local queues = {
    ['1v1'] = {},
    ['2v2'] = {},
    ['3v3'] = {},
    ['4v4'] = {}
}

local activeMatches = {}
local playersInQueue = {} -- [playerId] = {mode, startTime}
local playerCurrentMatch = {} -- [playerId] = matchId

-- Fonction pour créer les tables en base de données
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS pvp_stats (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) UNIQUE,
            name VARCHAR(50),
            elo INT DEFAULT 1000,
            kills INT DEFAULT 0,
            deaths INT DEFAULT 0,
            matches_played INT DEFAULT 0,
            wins INT DEFAULT 0,
            losses INT DEFAULT 0,
            best_elo INT DEFAULT 1000,
            rank_id INT DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    print('^2[PVP GunFight]^7 Base de données initialisée')
end)

-- Event pour rejoindre une queue
RegisterNetEvent('pvp:joinQueue', function(mode)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    print(string.format('^2[PVP SERVER]^7 %s rejoint la queue %s', xPlayer.getName(), mode))
    
    -- Vérifier si le joueur est déjà en queue
    if playersInQueue[src] then
        print('^3[PVP SERVER]^7 Joueur déjà en queue')
        TriggerClientEvent('esx:showNotification', src, '~r~Vous êtes déjà en file d\'attente!')
        return
    end
    
    -- Ajouter le joueur à la queue
    table.insert(queues[mode], src)
    playersInQueue[src] = {
        mode = mode,
        startTime = os.time()
    }
    
    -- Notifier le client qu'il est en recherche
    TriggerClientEvent('pvp:searchStarted', src, mode)
    TriggerClientEvent('esx:showNotification', src, '~b~Recherche de partie en cours...')
    
    print(string.format('[PVP] Queue %s: %d joueurs', mode, #queues[mode]))
    
    -- Vérifier si on peut créer un match
    CheckAndCreateMatch(mode)
end)

-- Fonction pour vérifier et créer un match
function CheckAndCreateMatch(mode)
    local playersNeeded = tonumber(mode:sub(1, 1)) * 2 -- 1v1 = 2, 2v2 = 4, etc.
    
    if #queues[mode] >= playersNeeded then
        local matchPlayers = {}
        
        -- Retirer les joueurs de la queue
        for i = 1, playersNeeded do
            table.insert(matchPlayers, table.remove(queues[mode], 1))
        end
        
        -- Créer le match
        CreateMatch(mode, matchPlayers)
    end
end

-- Fonction pour obtenir une arène aléatoire
local function GetRandomArena()
    local arenaKeys = {}
    for key, _ in pairs(Config.Arenas) do
        table.insert(arenaKeys, key)
    end
    
    local randomIndex = math.random(1, #arenaKeys)
    local arenaKey = arenaKeys[randomIndex]
    
    print(string.format('^2[PVP SERVER]^7 Arène sélectionnée: %s (%s)', arenaKey, Config.Arenas[arenaKey].name))
    
    return arenaKey, Config.Arenas[arenaKey]
end

-- Fonction pour créer un match
function CreateMatch(mode, players)
    local matchId = #activeMatches + 1
    
    print(string.format('^2[PVP SERVER]^7 Création du match %s avec %d joueurs', mode, #players))
    
    -- Sélectionner une arène aléatoire
    local arenaKey, arena = GetRandomArena()
    
    activeMatches[matchId] = {
        mode = mode,
        players = players,
        arena = arenaKey,
        team1 = {},
        team2 = {},
        score = {team1 = 0, team2 = 0},
        currentRound = 1,
        status = 'starting',
        startTime = os.time()
    }
    
    -- Diviser les joueurs en équipes
    local halfSize = #players / 2
    for i, playerId in ipairs(players) do
        if i <= halfSize then
            table.insert(activeMatches[matchId].team1, playerId)
        else
            table.insert(activeMatches[matchId].team2, playerId)
        end
        
        -- Retirer de la queue
        playersInQueue[playerId] = nil
        
        -- Enregistrer le match actuel du joueur
        playerCurrentMatch[playerId] = matchId
    end
    
    print(string.format('^2[PVP SERVER]^7 Match %d - Team 1: %d joueurs, Team 2: %d joueurs', 
        matchId, #activeMatches[matchId].team1, #activeMatches[matchId].team2))
    
    -- Téléporter les joueurs
    TeleportPlayersToArena(matchId, activeMatches[matchId], arena)
    
    -- Notifier tous les joueurs
    for _, playerId in ipairs(players) do
        TriggerClientEvent('pvp:matchFound', playerId)
        TriggerClientEvent('esx:showNotification', playerId, '~g~Match trouvé! ~w~Arène: ~b~' .. arena.name)
        
        -- Afficher le HUD de score
        TriggerClientEvent('pvp:showScoreHUD', playerId, activeMatches[matchId].score, activeMatches[matchId].currentRound)
    end
    
    -- Attendre la fin de la téléportation
    Wait(3000)
    
    -- FREEZE tous les joueurs AVANT de commencer le round 1
    for _, playerId in ipairs(players) do
        if playerId > 0 then
            TriggerClientEvent('pvp:freezePlayer', playerId)
        end
    end
    
    Wait(1000)
    
    -- Démarrer le premier round
    StartRound(matchId, activeMatches[matchId], arena)
    
    print(string.format('[PVP] Match %d créé: %s sur %s', matchId, mode, arena.name))
end

-- Fonction pour téléporter les joueurs à l'arène
function TeleportPlayersToArena(matchId, match, arena)
    print(string.format('^2[PVP SERVER]^7 Téléportation des joueurs pour le match %d', matchId))
    
    -- Téléporter Team 1 (spawn A)
    for i, playerId in ipairs(match.team1) do
        if arena.teamA[i] then
            local spawn = arena.teamA[i]
            
            -- Ne téléporter que les vrais joueurs
            if playerId > 0 then
                print(string.format('^2[PVP SERVER]^7 Team 1 - Joueur %d -> Spawn A%d', playerId, i))
                TriggerClientEvent('pvp:teleportToSpawn', playerId, spawn, 'team1', matchId)
            else
                print(string.format('^3[PVP BOT]^7 Team 1 - Bot %s -> Spawn A%d (virtuel)', bots[playerId].name, i))
            end
        end
    end
    
    -- Téléporter Team 2 (spawn B)
    for i, playerId in ipairs(match.team2) do
        if arena.teamB[i] then
            local spawn = arena.teamB[i]
            
            -- Ne téléporter que les vrais joueurs
            if playerId > 0 then
                print(string.format('^2[PVP SERVER]^7 Team 2 - Joueur %d -> Spawn B%d', playerId, i))
                TriggerClientEvent('pvp:teleportToSpawn', playerId, spawn, 'team2', matchId)
            else
                print(string.format('^3[PVP BOT]^7 Team 2 - Bot %s -> Spawn B%d (virtuel)', bots[playerId].name, i))
            end
        end
    end
end

-- Callback pour obtenir les stats d'un joueur
ESX.RegisterServerCallback('pvp:getPlayerStats', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then 
        cb(nil)
        return 
    end
    
    print(string.format('^2[PVP SERVER]^7 Récupération stats pour %s (%s)', xPlayer.getName(), xPlayer.identifier))
    
    MySQL.single('SELECT * FROM pvp_stats WHERE identifier = ?', {
        xPlayer.identifier
    }, function(result)
        if result then
            print(string.format('^2[PVP SERVER]^7 Stats trouvées: ELO %d, Kills %d, Deaths %d', result.elo, result.kills or 0, result.deaths or 0))
            
            -- Ajouter le nom si manquant
            result.name = result.name or xPlayer.getName()
            result.kills = result.kills or 0
            result.deaths = result.deaths or 0
            
            cb(result)
        else
            print('^2[PVP SERVER]^7 Aucune stats trouvée, création...')
            -- Créer les stats
            MySQL.insert('INSERT INTO pvp_stats (identifier, name, kills, deaths) VALUES (?, ?, 0, 0)', {
                xPlayer.identifier,
                xPlayer.getName()
            }, function(id)
                cb({
                    identifier = xPlayer.identifier,
                    name = xPlayer.getName(),
                    elo = Config.StartingELO,
                    kills = 0,
                    deaths = 0,
                    matches_played = 0,
                    wins = 0,
                    losses = 0
                })
            end)
        end
    end)
end)

-- Callback pour obtenir le leaderboard
ESX.RegisterServerCallback('pvp:getLeaderboard', function(source, cb)
    print('^2[PVP SERVER]^7 Récupération du leaderboard')
    
    MySQL.query('SELECT * FROM pvp_stats ORDER BY elo DESC LIMIT 50', {}, function(results)
        print(string.format('^2[PVP SERVER]^7 Leaderboard: %d entrées', #results))
        
        -- S'assurer que tous les champs existent
        for i, player in ipairs(results) do
            player.kills = player.kills or 0
            player.deaths = player.deaths or 0
            player.name = player.name or 'Joueur ' .. i
        end
        
        cb(results)
    end)
end)

-- Event pour annuler la recherche
RegisterNetEvent('pvp:cancelSearch', function()
    local src = source
    
    print(string.format('^2[PVP SERVER]^7 %s annule la recherche', src))
    
    if not playersInQueue[src] then
        return
    end
    
    local queueData = playersInQueue[src]
    
    -- Retirer de la queue
    for i, playerId in ipairs(queues[queueData.mode]) do
        if playerId == src then
            table.remove(queues[queueData.mode], i)
            break
        end
    end
    
    playersInQueue[src] = nil
    
    TriggerClientEvent('pvp:searchCancelled', src)
    TriggerClientEvent('esx:showNotification', src, '~y~Recherche annulée')
end)

-- Event quand un joueur meurt
RegisterNetEvent('pvp:playerDied', function(killerId)
    local victimId = source
    
    print(string.format('^2[PVP SERVER]^7 Joueur %s tué par %s', victimId, killerId or 'suicide'))
    
    -- Trouver le match du joueur
    local matchId = playerCurrentMatch[victimId]
    
    if matchId and activeMatches[matchId] then
        local match = activeMatches[matchId]
        print(string.format('^2[PVP SERVER]^7 Mort dans le match %d', matchId))
        HandlePlayerDeath(matchId, match, victimId, killerId)
    end
end)

-- Fonction pour gérer la mort d'un joueur
function HandlePlayerDeath(matchId, match, victimId, killerId)
    if match.status ~= 'playing' then return end
    
    -- Enregistrer les stats du round
    if not match.roundStats then
        match.roundStats = {}
    end
    
    table.insert(match.roundStats, {
        victim = victimId,
        killer = killerId,
        time = os.time()
    })
    
    -- Mettre à jour les kills/deaths
    if killerId and killerId ~= victimId then
        UpdatePlayerKills(killerId, 1)
        TriggerClientEvent('esx:showNotification', killerId, '~g~+1 Kill!')
    end
    
    UpdatePlayerDeaths(victimId, 1)
    
    -- Vérifier si une équipe est éliminée
    CheckRoundEnd(matchId, match)
end

-- Fonction pour vérifier si le round est terminé
function CheckRoundEnd(matchId, match)
    local team1Alive = CountAlivePlayers(match.team1)
    local team2Alive = CountAlivePlayers(match.team2)
    
    print(string.format('^2[PVP SERVER]^7 Team1 vivants: %d, Team2 vivants: %d', team1Alive, team2Alive))
    
    if team1Alive == 0 then
        print('^2[PVP SERVER]^7 Team 2 gagne le round!')
        match.score.team2 = match.score.team2 + 1
        EndRound(matchId, match, 'team2')
    elseif team2Alive == 0 then
        print('^2[PVP SERVER]^7 Team 1 gagne le round!')
        match.score.team1 = match.score.team1 + 1
        EndRound(matchId, match, 'team1')
    end
end

-- Fonction pour compter les joueurs vivants
function CountAlivePlayers(team)
    local count = 0
    for _, playerId in ipairs(team) do
        -- Les bots sont considérés comme toujours morts (pour que le joueur gagne)
        if playerId < 0 then
            -- Bot = mort
            count = count + 0
        else
            local playerPed = GetPlayerPed(playerId)
            if playerPed and playerPed > 0 then
                local health = GetEntityHealth(playerPed)
                if health > 0 then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- Fonction pour terminer un round
function EndRound(matchId, match, winningTeam)
    match.status = 'round_end'
    
    local arena = Config.Arenas[match.arena]
    
    -- Notifier tous les joueurs réels
    for _, playerId in ipairs(match.players) do
        if playerId > 0 then
            TriggerClientEvent('pvp:roundEnd', playerId, winningTeam, match.score)
            
            -- Mettre à jour le HUD
            TriggerClientEvent('pvp:updateScore', playerId, match.score, match.currentRound)
        end
    end
    
    print(string.format('^2[PVP SERVER]^7 Score - Team1: %d, Team2: %d', match.score.team1, match.score.team2))
    
    -- Vérifier si le match est terminé
    if match.score.team1 >= Config.MaxRounds or match.score.team2 >= Config.MaxRounds then
        EndMatch(matchId, match)
    else
        -- Attendre la fin de l'animation (3 secondes)
        Wait(3000)
        
        match.currentRound = match.currentRound + 1
        
        -- FREEZE tous les joueurs AVANT le respawn
        for _, playerId in ipairs(match.players) do
            if playerId > 0 then
                TriggerClientEvent('pvp:freezePlayer', playerId)
            end
        end
        
        Wait(500)
        
        -- Respawn et heal tous les joueurs
        RespawnPlayers(matchId, match, arena)
        
        Wait(2000)
        
        -- Démarrer le round (qui va aussi gérer le freeze/unfreeze)
        StartRound(matchId, match, arena)
    end
end

-- Fonction pour respawn les joueurs
function RespawnPlayers(matchId, match, arena)
    print(string.format('^2[PVP SERVER]^7 Respawn des joueurs pour le round %d', match.currentRound))
    
    -- Respawn Team 1
    for i, playerId in ipairs(match.team1) do
        if arena.teamA[i] and playerId > 0 then -- Seulement les vrais joueurs
            local spawn = arena.teamA[i]
            TriggerClientEvent('pvp:respawnPlayer', playerId, spawn)
        end
    end
    
    -- Respawn Team 2
    for i, playerId in ipairs(match.team2) do
        if arena.teamB[i] and playerId > 0 then -- Seulement les vrais joueurs
            local spawn = arena.teamB[i]
            TriggerClientEvent('pvp:respawnPlayer', playerId, spawn)
        end
    end
end

-- Fonction pour démarrer un round
function StartRound(matchId, match, arena)
    print(string.format('^2[PVP SERVER]^7 Début du round %d', match.currentRound))
    
    match.status = 'playing'
    match.roundStats = {}
    
    for _, playerId in ipairs(match.players) do
        if playerId > 0 then -- Seulement les vrais joueurs
            TriggerClientEvent('pvp:roundStart', playerId, match.currentRound)
            
            -- Mettre à jour le HUD
            TriggerClientEvent('pvp:updateScore', playerId, match.score, match.currentRound)
        end
    end
end

-- Fonction pour terminer le match
function EndMatch(matchId, match)
    print(string.format('^2[PVP SERVER]^7 Fin du match %d', matchId))
    
    match.status = 'finished'
    
    local winningTeam = match.score.team1 > match.score.team2 and 'team1' or 'team2'
    local winners = winningTeam == 'team1' and match.team1 or match.team2
    local losers = winningTeam == 'team1' and match.team2 or match.team1
    
    -- Mettre à jour les stats (seulement pour les vrais joueurs)
    for _, winnerId in ipairs(winners) do
        if winnerId > 0 then
            UpdatePlayerWin(winnerId)
            
            -- Déterminer si c'est notre team
            local isTeam1 = false
            for _, pid in ipairs(match.team1) do
                if pid == winnerId then
                    isTeam1 = true
                    break
                end
            end
            
            TriggerClientEvent('pvp:matchEnd', winnerId, true, match.score)
            TriggerClientEvent('pvp:hideScoreHUD', winnerId)
            TriggerClientEvent('esx:showNotification', winnerId, '~g~VICTOIRE!')
            
            -- Nettoyer le playerCurrentMatch
            playerCurrentMatch[winnerId] = nil
        end
    end
    
    for _, loserId in ipairs(losers) do
        if loserId > 0 then
            UpdatePlayerLoss(loserId)
            TriggerClientEvent('pvp:matchEnd', loserId, false, match.score)
            TriggerClientEvent('pvp:hideScoreHUD', loserId)
            TriggerClientEvent('esx:showNotification', loserId, '~r~DÉFAITE!')
            
            -- Nettoyer le playerCurrentMatch
            playerCurrentMatch[loserId] = nil
        end
    end
    
    -- Nettoyer le match après un délai
    Wait(10000)
    activeMatches[matchId] = nil
end

-- Fonction pour mettre à jour les kills
function UpdatePlayerKills(playerId, amount)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    MySQL.query('UPDATE pvp_stats SET kills = kills + ? WHERE identifier = ?', {
        amount,
        xPlayer.identifier
    })
end

-- Fonction pour mettre à jour les deaths
function UpdatePlayerDeaths(playerId, amount)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    MySQL.query('UPDATE pvp_stats SET deaths = deaths + ? WHERE identifier = ?', {
        amount,
        xPlayer.identifier
    })
end

-- Fonction pour mettre à jour les victoires
function UpdatePlayerWin(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    MySQL.query('UPDATE pvp_stats SET wins = wins + 1, matches_played = matches_played + 1 WHERE identifier = ?', {
        xPlayer.identifier
    })
end

-- Fonction pour mettre à jour les défaites
function UpdatePlayerLoss(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    MySQL.query('UPDATE pvp_stats SET losses = losses + 1, matches_played = matches_played + 1 WHERE identifier = ?', {
        xPlayer.identifier
    })
end

-- ========================================
-- GESTION DES DÉCONNEXIONS
-- ========================================

-- Fonction pour gérer la déconnexion d'un joueur pendant un match
local function HandlePlayerDisconnect(playerId)
    print(string.format('^2[PVP SERVER]^7 Gestion de la déconnexion du joueur %s', playerId))
    
    local matchId = playerCurrentMatch[playerId]
    
    if not matchId or not activeMatches[matchId] then
        print('^3[PVP SERVER]^7 Joueur pas en match ou match inexistant')
        return
    end
    
    local match = activeMatches[matchId]
    
    print(string.format('^1[PVP SERVER]^7 Joueur %s déconnecté pendant le match %d', playerId, matchId))
    
    -- Compter comme défaite
    UpdatePlayerLoss(playerId)
    
    -- Déterminer la team du joueur
    local playerTeam = nil
    local isTeam1 = false
    for _, pid in ipairs(match.team1) do
        if pid == playerId then
            playerTeam = 'team1'
            isTeam1 = true
            break
        end
    end
    
    if not playerTeam then
        for _, pid in ipairs(match.team2) do
            if pid == playerId then
                playerTeam = 'team2'
                break
            end
        end
    end
    
    if not playerTeam then
        print('^1[PVP SERVER]^7 Impossible de trouver la team du joueur')
        return
    end
    
    -- Notifier tous les autres joueurs
    for _, otherPlayerId in ipairs(match.players) do
        if otherPlayerId ~= playerId and otherPlayerId > 0 then
            TriggerClientEvent('esx:showNotification', otherPlayerId, '~y~Un joueur s\'est déconnecté - Le match continue')
        end
    end
    
    -- Terminer le match si trop de joueurs manquants
    local team1Count = 0
    local team2Count = 0
    
    for _, pid in ipairs(match.team1) do
        if pid > 0 and GetPlayerPing(pid) > 0 then
            team1Count = team1Count + 1
        end
    end
    
    for _, pid in ipairs(match.team2) do
        if pid > 0 and GetPlayerPing(pid) > 0 then
            team2Count = team2Count + 1
        end
    end
    
    print(string.format('^2[PVP SERVER]^7 Joueurs restants - Team1: %d, Team2: %d', team1Count, team2Count))
    
    -- Si une team est vide, terminer le match immédiatement
    if team1Count == 0 or team2Count == 0 then
        print('^1[PVP SERVER]^7 Une équipe est vide - Fin immédiate du match')
        
        local winningTeam = team1Count > 0 and 'team1' or 'team2'
        local winners = winningTeam == 'team1' and match.team1 or match.team2
        
        -- Donner la victoire à la team restante
        if winningTeam == 'team1' then
            match.score.team1 = Config.MaxRounds
        else
            match.score.team2 = Config.MaxRounds
        end
        
        -- Téléporter immédiatement les survivants au lobby
        for _, winnerId in ipairs(winners) do
            if winnerId > 0 and GetPlayerPing(winnerId) > 0 then
                print(string.format('^2[PVP SERVER]^7 Téléportation du gagnant %d au lobby', winnerId))
                
                -- Masquer le HUD
                TriggerClientEvent('pvp:hideScoreHUD', winnerId)
                
                -- Téléporter au lobby SANS animation de fin
                TriggerClientEvent('pvp:forceReturnToLobby', winnerId)
                
                -- Notification
                TriggerClientEvent('esx:showNotification', winnerId, '~g~Victoire par abandon adverse!')
                
                -- Update stats
                UpdatePlayerWin(winnerId)
            end
        end
        
        -- Nettoyer le match
        Wait(2000)
        activeMatches[matchId] = nil
    end
    
    -- Nettoyer
    playerCurrentMatch[playerId] = nil
end

-- Nettoyer les queues quand un joueur se déconnecte
AddEventHandler('playerDropped', function()
    local src = source
    
    print(string.format('^2[PVP SERVER]^7 Joueur %s déconnecté, nettoyage...', src))
    
    -- Retirer des queues
    if playersInQueue[src] then
        local queueData = playersInQueue[src]
        for i, playerId in ipairs(queues[queueData.mode]) do
            if playerId == src then
                table.remove(queues[queueData.mode], i)
                print(string.format('^2[PVP SERVER]^7 Retiré de la queue %s', queueData.mode))
                break
            end
        end
        playersInQueue[src] = nil
    end
    
    -- Gérer la déconnexion pendant un match
    HandlePlayerDisconnect(src)
end)

-- ========================================
-- SYSTÈME DE BOTS POUR TESTS
-- ========================================

local bots = {}
local botIdCounter = -1

-- Commande pour ajouter un bot à la queue
RegisterCommand('addbot', function(source, args)
    local mode = args[1] or '1v1'
    
    if not queues[mode] then
        TriggerClientEvent('esx:showNotification', source, '~r~Mode invalide! Utilisez: 1v1, 2v2, 3v3 ou 4v4')
        return
    end
    
    local botId = botIdCounter
    botIdCounter = botIdCounter - 1
    
    -- Créer les données du bot
    bots[botId] = {
        id = botId,
        name = 'Bot_' .. math.abs(botId),
        isBot = true
    }
    
    -- Ajouter à la queue
    table.insert(queues[mode], botId)
    playersInQueue[botId] = {
        mode = mode,
        startTime = os.time()
    }
    
    print(string.format('^3[PVP BOT]^7 Bot %s ajouté à la queue %s', bots[botId].name, mode))
    TriggerClientEvent('esx:showNotification', source, '~b~Bot ajouté à la queue ' .. mode)
    
    -- Vérifier si on peut créer un match
    CheckAndCreateMatch(mode)
end, true) -- Admin only

-- Commande pour remplir automatiquement une queue avec des bots
RegisterCommand('fillqueue', function(source, args)
    local mode = args[1] or '1v1'
    local playersNeeded = tonumber(mode:sub(1, 1)) * 2
    
    if not queues[mode] then
        TriggerClientEvent('esx:showNotification', source, '~r~Mode invalide!')
        return
    end
    
    local currentPlayers = #queues[mode]
    local botsToAdd = playersNeeded - currentPlayers
    
    if botsToAdd <= 0 then
        TriggerClientEvent('esx:showNotification', source, '~y~La queue est déjà pleine!')
        return
    end
    
    -- Ajouter les bots nécessaires
    for i = 1, botsToAdd do
        local botId = botIdCounter
        botIdCounter = botIdCounter - 1
        
        bots[botId] = {
            id = botId,
            name = 'Bot_' .. math.abs(botId),
            isBot = true
        }
        
        table.insert(queues[mode], botId)
        playersInQueue[botId] = {
            mode = mode,
            startTime = os.time()
        }
        
        print(string.format('^3[PVP BOT]^7 Bot %s ajouté', bots[botId].name))
    end
    
    TriggerClientEvent('esx:showNotification', source, string.format('~g~%d bots ajoutés!', botsToAdd))
    
    CheckAndCreateMatch(mode)
end, true)

-- Commande pour voir les queues
RegisterCommand('showqueues', function(source, args)
    print('^2[PVP QUEUES]^7 État des files d\'attente:')
    
    for mode, players in pairs(queues) do
        print(string.format('  %s: %d joueurs', mode, #players))
        for _, playerId in ipairs(players) do
            if playerId < 0 then
                print(string.format('    - Bot: %s', bots[playerId].name))
            else
                local xPlayer = ESX.GetPlayerFromId(playerId)
                if xPlayer then
                    print(string.format('    - Joueur: %s (ID: %d)', xPlayer.getName(), playerId))
                end
            end
        end
    end
    
    TriggerClientEvent('esx:showNotification', source, '~b~Infos dans la console F8')
end, true)

-- Gérer les bots dans les events de téléportation
-- Les bots ne sont pas téléportés mais comptés dans le match