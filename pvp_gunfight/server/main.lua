-- ========================================
-- PVP GUNFIGHT - SERVER MAIN (FIXED)
-- Correctifs : Routing Buckets + Matchmaking Groupes
-- ========================================

print('^2[PVP SERVER]^7 Chargement du système PVP avec instances...')

-- Tables pour gérer les queues et matchs
local queues = {
    ['1v1'] = {},
    ['2v2'] = {},
    ['3v3'] = {},
    ['4v4'] = {}
}

local activeMatches = {}
local playersInQueue = {} -- [playerId] = {mode, startTime, groupMembers}
local playerCurrentMatch = {} -- [playerId] = matchId
local playerCurrentBucket = {} -- [playerId] = bucketId

-- Compteur de buckets pour les instances
local nextBucketId = 100 -- On commence à 100 pour éviter les buckets système

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

-- ========================================
-- SYSTÈME DE ROUTING BUCKETS (INSTANCES)
-- ========================================

-- Fonction pour créer un bucket unique pour un match
local function CreateMatchBucket()
    local bucketId = nextBucketId
    nextBucketId = nextBucketId + 1
    
    print(string.format('^2[PVP BUCKET]^7 Création du bucket %d', bucketId))
    
    return bucketId
end

-- Fonction pour assigner un joueur à un bucket
local function SetPlayerBucket(playerId, bucketId)
    if playerId <= 0 then return end -- Skip bots
    
    SetPlayerRoutingBucket(playerId, bucketId)
    playerCurrentBucket[playerId] = bucketId
    
    print(string.format('^2[PVP BUCKET]^7 Joueur %d assigné au bucket %d', playerId, bucketId))
end

-- Fonction pour remettre un joueur dans le monde public (bucket 0)
local function ResetPlayerBucket(playerId)
    if playerId <= 0 then return end -- Skip bots
    
    SetPlayerRoutingBucket(playerId, 0)
    playerCurrentBucket[playerId] = nil
    
    print(string.format('^2[PVP BUCKET]^7 Joueur %d remis dans le bucket public (0)', playerId))
end

-- ========================================
-- SYSTÈME DE MATCHMAKING AVEC GROUPES
-- ========================================

-- FIX CRITIQUE : Event pour rejoindre une queue AVEC SUPPORT DES GROUPES
RegisterNetEvent('pvp:joinQueue', function(mode)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    print(string.format('^2[PVP SERVER]^7 %s (%d) veut rejoindre la queue %s', xPlayer.getName(), src, mode))
    
    -- Vérifier si le joueur est déjà en queue
    if playersInQueue[src] then
        print('^3[PVP SERVER]^7 Joueur déjà en queue')
        TriggerClientEvent('esx:showNotification', src, '~r~Vous êtes déjà en file d\'attente!')
        return
    end
    
    -- Récupérer le groupe du joueur
    local group = exports['pvp_gunfight']:GetPlayerGroup(src)
    
    local playersToQueue = {}
    
    if group then
        -- LE JOUEUR EST DANS UN GROUPE
        print(string.format('^2[PVP SERVER]^7 Joueur dans un groupe avec %d membres', #group.members))
        
        -- Vérifier que c'est le leader
        if group.leaderId ~= src then
            print('^3[PVP SERVER]^7 N\'est pas le leader')
            TriggerClientEvent('esx:showNotification', src, '~r~Seul le leader peut lancer la recherche!')
            return
        end
        
        -- Déterminer le nombre de joueurs nécessaires pour le mode
        local playersNeededPerTeam = tonumber(mode:sub(1, 1))
        
        -- Vérifier que le groupe a la bonne taille
        if #group.members ~= playersNeededPerTeam then
            print(string.format('^3[PVP SERVER]^7 Mauvaise taille de groupe : %d au lieu de %d', #group.members, playersNeededPerTeam))
            TriggerClientEvent('esx:showNotification', src, string.format('~r~Il faut exactement %d joueur(s) dans le groupe pour le mode %s!', playersNeededPerTeam, mode))
            return
        end
        
        -- Vérifier que tous les membres sont prêts
        local allReady = true
        for memberId, isReady in pairs(group.ready) do
            if not isReady then
                allReady = false
                break
            end
        end
        
        if not allReady then
            print('^3[PVP SERVER]^7 Tous les membres ne sont pas prêts')
            TriggerClientEvent('esx:showNotification', src, '~r~Tous les membres doivent être prêts!')
            return
        end
        
        -- FIX CRITIQUE : Ajouter TOUS les membres du groupe
        for _, memberId in ipairs(group.members) do
            table.insert(playersToQueue, memberId)
        end
        
        print(string.format('^2[PVP SERVER]^7 Ajout de %d joueurs du groupe à la queue', #playersToQueue))
        
    else
        -- LE JOUEUR EST SOLO
        print('^2[PVP SERVER]^7 Joueur solo')
        
        -- Seul le 1v1 est autorisé en solo
        if mode ~= '1v1' then
            TriggerClientEvent('esx:showNotification', src, '~r~Vous devez être dans un groupe pour les modes 2v2, 3v3 et 4v4!')
            return
        end
        
        table.insert(playersToQueue, src)
    end
    
    -- Ajouter tous les joueurs à la queue
    for _, playerId in ipairs(playersToQueue) do
        table.insert(queues[mode], playerId)
        playersInQueue[playerId] = {
            mode = mode,
            startTime = os.time(),
            groupMembers = playersToQueue
        }
        
        -- Notifier le client qu'il est en recherche
        TriggerClientEvent('pvp:searchStarted', playerId, mode)
        TriggerClientEvent('esx:showNotification', playerId, '~b~Recherche de partie en cours...')
    end
    
    print(string.format('[PVP] Queue %s: %d joueurs (ajout de %d)', mode, #queues[mode], #playersToQueue))
    
    -- Vérifier si on peut créer un match
    CheckAndCreateMatch(mode)
end)

-- Fonction pour vérifier et créer un match
function CheckAndCreateMatch(mode)
    local playersNeeded = tonumber(mode:sub(1, 1)) * 2 -- 1v1 = 2, 2v2 = 4, etc.
    
    print(string.format('^2[PVP MATCHMAKING]^7 Check queue %s : %d/%d joueurs', mode, #queues[mode], playersNeeded))
    
    if #queues[mode] >= playersNeeded then
        local matchPlayers = {}
        
        -- Retirer les joueurs de la queue
        for i = 1, playersNeeded do
            local playerId = table.remove(queues[mode], 1)
            table.insert(matchPlayers, playerId)
            print(string.format('^2[PVP MATCHMAKING]^7 Joueur %d ajouté au match', playerId))
        end
        
        -- Créer le match
        CreateMatch(mode, matchPlayers)
    else
        print(string.format('^3[PVP MATCHMAKING]^7 Pas assez de joueurs (%d/%d)', #queues[mode], playersNeeded))
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

-- Fonction pour créer un match AVEC INSTANCE
function CreateMatch(mode, players)
    local matchId = #activeMatches + 1
    
    print(string.format('^2[PVP SERVER]^7 ========== CRÉATION MATCH %d ==========', matchId))
    print(string.format('^2[PVP SERVER]^7 Mode: %s avec %d joueurs', mode, #players))
    
    -- CRÉER UN BUCKET UNIQUE POUR CE MATCH
    local bucketId = CreateMatchBucket()
    
    -- Sélectionner une arène aléatoire
    local arenaKey, arena = GetRandomArena()
    
    activeMatches[matchId] = {
        mode = mode,
        players = players,
        arena = arenaKey,
        bucketId = bucketId,  -- NOUVEAU : ID du bucket pour l'instance
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
        
        -- FIX : Retirer le joueur de son groupe quand il entre en match
        if playerId > 0 then
            exports['pvp_gunfight']:RemovePlayerFromGroup(playerId)
        end
        
        -- ASSIGNER LE JOUEUR AU BUCKET DE L'INSTANCE
        SetPlayerBucket(playerId, bucketId)
    end
    
    print(string.format('^2[PVP SERVER]^7 Match %d - Bucket: %d', matchId, bucketId))
    print(string.format('^2[PVP SERVER]^7 Team 1: %d joueurs, Team 2: %d joueurs', 
        #activeMatches[matchId].team1, #activeMatches[matchId].team2))
    
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
    
    print(string.format('[PVP] Match %d créé: %s sur %s (Bucket: %d)', matchId, mode, arena.name, bucketId))
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
            
            result.name = result.name or xPlayer.getName()
            result.kills = result.kills or 0
            result.deaths = result.deaths or 0
            
            cb(result)
        else
            print('^2[PVP SERVER]^7 Aucune stats trouvée, création...')
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
    local groupMembers = queueData.groupMembers or {src}
    
    -- Retirer TOUS les membres du groupe de la queue
    for _, memberId in ipairs(groupMembers) do
        -- Retirer de la queue
        for i, playerId in ipairs(queues[queueData.mode]) do
            if playerId == memberId then
                table.remove(queues[queueData.mode], i)
                break
            end
        end
        
        playersInQueue[memberId] = nil
        
        -- Notifier
        TriggerClientEvent('pvp:searchCancelled', memberId)
        TriggerClientEvent('esx:showNotification', memberId, '~y~Recherche annulée')
    end
end)

-- Event quand un joueur meurt
RegisterNetEvent('pvp:playerDied', function(killerId)
    local victimId = source
    
    print(string.format('^2[PVP SERVER]^7 Joueur %s tué par %s', victimId, killerId or 'suicide'))
    
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
    
    if not match.roundStats then
        match.roundStats = {}
    end
    
    table.insert(match.roundStats, {
        victim = victimId,
        killer = killerId,
        time = os.time()
    })
    
    if killerId and killerId ~= victimId then
        UpdatePlayerKills(killerId, 1)
        TriggerClientEvent('esx:showNotification', killerId, '~g~+1 Kill!')
    end
    
    UpdatePlayerDeaths(victimId, 1)
    
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
        if playerId < 0 then
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
    
    for _, playerId in ipairs(match.players) do
        if playerId > 0 then
            TriggerClientEvent('pvp:roundEnd', playerId, winningTeam, match.score)
            TriggerClientEvent('pvp:updateScore', playerId, match.score, match.currentRound)
        end
    end
    
    print(string.format('^2[PVP SERVER]^7 Score - Team1: %d, Team2: %d', match.score.team1, match.score.team2))
    
    if match.score.team1 >= Config.MaxRounds or match.score.team2 >= Config.MaxRounds then
        EndMatch(matchId, match)
    else
        Wait(3000)
        
        match.currentRound = match.currentRound + 1
        
        for _, playerId in ipairs(match.players) do
            if playerId > 0 then
                TriggerClientEvent('pvp:freezePlayer', playerId)
            end
        end
        
        Wait(500)
        
        RespawnPlayers(matchId, match, arena)
        
        Wait(2000)
        
        StartRound(matchId, match, arena)
    end
end

-- Fonction pour respawn les joueurs
function RespawnPlayers(matchId, match, arena)
    print(string.format('^2[PVP SERVER]^7 Respawn des joueurs pour le round %d', match.currentRound))
    
    for i, playerId in ipairs(match.team1) do
        if arena.teamA[i] and playerId > 0 then
            local spawn = arena.teamA[i]
            TriggerClientEvent('pvp:respawnPlayer', playerId, spawn)
        end
    end
    
    for i, playerId in ipairs(match.team2) do
        if arena.teamB[i] and playerId > 0 then
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
        if playerId > 0 then
            TriggerClientEvent('pvp:roundStart', playerId, match.currentRound)
            TriggerClientEvent('pvp:updateScore', playerId, match.score, match.currentRound)
        end
    end
end

-- Fonction pour terminer le match AVEC REMISE AU BUCKET 0
function EndMatch(matchId, match)
    print(string.format('^2[PVP SERVER]^7 Fin du match %d', matchId))
    
    match.status = 'finished'
    
    local winningTeam = match.score.team1 > match.score.team2 and 'team1' or 'team2'
    local winners = winningTeam == 'team1' and match.team1 or match.team2
    local losers = winningTeam == 'team1' and match.team2 or match.team1
    
    for _, winnerId in ipairs(winners) do
        if winnerId > 0 then
            UpdatePlayerWin(winnerId)
            TriggerClientEvent('pvp:matchEnd', winnerId, true, match.score)
            TriggerClientEvent('pvp:hideScoreHUD', winnerId)
            TriggerClientEvent('esx:showNotification', winnerId, '~g~VICTOIRE!')
            
            playerCurrentMatch[winnerId] = nil
        end
    end
    
    for _, loserId in ipairs(losers) do
        if loserId > 0 then
            UpdatePlayerLoss(loserId)
            TriggerClientEvent('pvp:matchEnd', loserId, false, match.score)
            TriggerClientEvent('pvp:hideScoreHUD', loserId)
            TriggerClientEvent('esx:showNotification', loserId, '~r~DÉFAITE!')
            
            playerCurrentMatch[loserId] = nil
        end
    end
    
    -- Attendre que les joueurs voient l'animation de fin
    Wait(8000)
    
    -- REMETTRE TOUS LES JOUEURS DANS LE BUCKET PUBLIC
    print(string.format('^2[PVP BUCKET]^7 Remise des joueurs du match %d dans le bucket 0', matchId))
    for _, playerId in ipairs(match.players) do
        ResetPlayerBucket(playerId)
    end
    
    -- Nettoyer le match
    Wait(2000)
    activeMatches[matchId] = nil
    
    print(string.format('^2[PVP SERVER]^7 Match %d terminé et nettoyé', matchId))
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
-- GESTION DES DÉCONNEXIONS AVEC BUCKETS
-- ========================================

local function HandlePlayerDisconnect(playerId)
    print(string.format('^2[PVP SERVER]^7 Gestion de la déconnexion du joueur %s', playerId))
    
    -- Remettre dans le bucket 0 (par sécurité)
    ResetPlayerBucket(playerId)
    
    local matchId = playerCurrentMatch[playerId]
    
    if not matchId or not activeMatches[matchId] then
        print('^3[PVP SERVER]^7 Joueur pas en match ou match inexistant')
        return
    end
    
    local match = activeMatches[matchId]
    
    print(string.format('^1[PVP SERVER]^7 Joueur %s déconnecté pendant le match %d', playerId, matchId))
    
    UpdatePlayerLoss(playerId)
    
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
    
    for _, otherPlayerId in ipairs(match.players) do
        if otherPlayerId ~= playerId and otherPlayerId > 0 then
            TriggerClientEvent('esx:showNotification', otherPlayerId, '~y~Un joueur s\'est déconnecté')
        end
    end
    
    local team1Count = 0
    local team2Count = 0
    
    for _, pid in ipairs(match.team1) do
        if pid > 0 and GetPlayerPing(pid) > 0 and pid ~= playerId then
            team1Count = team1Count + 1
        end
    end
    
    for _, pid in ipairs(match.team2) do
        if pid > 0 and GetPlayerPing(pid) > 0 and pid ~= playerId then
            team2Count = team2Count + 1
        end
    end
    
    print(string.format('^2[PVP SERVER]^7 Joueurs restants - Team1: %d, Team2: %d', team1Count, team2Count))
    
    if team1Count == 0 or team2Count == 0 then
        print('^1[PVP SERVER]^7 Une équipe est vide - Fin immédiate du match')
        
        local winningTeam = team1Count > 0 and 'team1' or 'team2'
        local winners = winningTeam == 'team1' and match.team1 or match.team2
        
        if winningTeam == 'team1' then
            match.score.team1 = Config.MaxRounds
        else
            match.score.team2 = Config.MaxRounds
        end
        
        for _, winnerId in ipairs(winners) do
            if winnerId > 0 and GetPlayerPing(winnerId) > 0 and winnerId ~= playerId then
                print(string.format('^2[PVP SERVER]^7 Téléportation du gagnant %d au lobby', winnerId))
                
                TriggerClientEvent('pvp:hideScoreHUD', winnerId)
                TriggerClientEvent('pvp:forceReturnToLobby', winnerId)
                TriggerClientEvent('esx:showNotification', winnerId, '~g~Victoire par abandon adverse!')
                
                UpdatePlayerWin(winnerId)
                
                playerCurrentMatch[winnerId] = nil
                
                -- REMETTRE DANS LE BUCKET PUBLIC
                ResetPlayerBucket(winnerId)
            end
        end
        
        activeMatches[matchId] = nil
        print('^2[PVP SERVER]^7 Match supprimé')
    end
    
    playerCurrentMatch[playerId] = nil
end

-- Nettoyer les queues quand un joueur se déconnecte
AddEventHandler('playerDropped', function()
    local src = source
    
    print(string.format('^2[PVP SERVER]^7 Joueur %s déconnecté, nettoyage...', src))
    
    -- Retirer des queues
    if playersInQueue[src] then
        local queueData = playersInQueue[src]
        local groupMembers = queueData.groupMembers or {src}
        
        -- Retirer TOUS les membres du groupe
        for _, memberId in ipairs(groupMembers) do
            for i, playerId in ipairs(queues[queueData.mode]) do
                if playerId == memberId then
                    table.remove(queues[queueData.mode], i)
                    print(string.format('^2[PVP SERVER]^7 Retiré de la queue %s', queueData.mode))
                    break
                end
            end
            playersInQueue[memberId] = nil
        end
    end
    
    -- Gérer la déconnexion pendant un match
    HandlePlayerDisconnect(src)
end)

print('^2[PVP SERVER]^7 Système PVP avec instances chargé!')