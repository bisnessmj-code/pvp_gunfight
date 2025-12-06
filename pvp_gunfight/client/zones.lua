-- ========================================
-- PVP GUNFIGHT - ZONES DE COMBAT
-- Gestion des domes verts et dégâts hors zone
-- ========================================

print('^2[PVP ZONES]^7 Module chargé')

-- Variables locales
local currentArenaZone = nil -- {center = vector3, radius = number}
local isInMatch = false
local damageTimer = 0
local lastDamageTime = 0

-- Configuration des dégâts hors zone
local DAMAGE_CONFIG = {
    damagePerTick = 5,           -- Dégâts infligés par tick
    tickInterval = 1000,         -- Intervalle entre chaque tick (ms)
    warningDistance = 5.0,       -- Distance avant la limite pour afficher un warning
    maxHealth = 200              -- Santé max du joueur
}

-- ========================================
-- FONCTIONS UTILITAIRES
-- ========================================

-- Fonction pour vérifier si le joueur est dans la zone
local function IsPlayerInZone(playerPos, center, radius)
    if not center or not radius then
        print('^1[PVP ZONES]^7 ERREUR: Zone invalide')
        return true -- Si pas de zone, on considère qu'il est dedans
    end
    
    -- Calculer la distance 2D (sans prendre en compte Z)
    local distance = #(vector2(playerPos.x, playerPos.y) - vector2(center.x, center.y))
    
    return distance <= radius
end

-- Fonction pour dessiner un cercle au sol
local function DrawGroundCircle(center, radius, r, g, b, a)
    -- Nombre de segments pour le cercle (plus = plus lisse)
    local segments = 64
    local angleStep = 360.0 / segments
    
    for i = 0, segments - 1 do
        local angle1 = math.rad(i * angleStep)
        local angle2 = math.rad((i + 1) * angleStep)
        
        -- Points du segment
        local x1 = center.x + math.cos(angle1) * radius
        local y1 = center.y + math.sin(angle1) * radius
        local x2 = center.x + math.cos(angle2) * radius
        local y2 = center.y + math.sin(angle2) * radius
        
        -- Obtenir la hauteur du sol à ces positions
        local z1 = center.z
        local z2 = center.z
        
        -- Dessiner une ligne entre les deux points
        DrawLine(x1, y1, z1, x2, y2, z2, r, g, b, a)
    end
end

-- Fonction pour dessiner un dome (demi-sphère)
local function DrawDome(center, radius, r, g, b, a)
    -- Nombre de cercles verticaux pour former le dome
    local verticalSegments = 12
    local horizontalSegments = 32
    
    -- Dessiner les cercles horizontaux (de bas en haut)
    for v = 0, verticalSegments do
        local heightRatio = v / verticalSegments
        local angle = math.rad(heightRatio * 90) -- De 0° à 90° (demi-sphère)
        
        local currentRadius = math.cos(angle) * radius
        local currentHeight = math.sin(angle) * radius
        
        DrawGroundCircle(
            vector3(center.x, center.y, center.z + currentHeight),
            currentRadius,
            r, g, b, a
        )
    end
    
    -- Dessiner les lignes verticales
    local angleStep = 360.0 / horizontalSegments
    for i = 0, horizontalSegments - 1 do
        local baseAngle = math.rad(i * angleStep)
        
        for v = 0, verticalSegments - 1 do
            local heightRatio1 = v / verticalSegments
            local heightRatio2 = (v + 1) / verticalSegments
            
            local angle1 = math.rad(heightRatio1 * 90)
            local angle2 = math.rad(heightRatio2 * 90)
            
            local r1 = math.cos(angle1) * radius
            local h1 = math.sin(angle1) * radius
            local r2 = math.cos(angle2) * radius
            local h2 = math.sin(angle2) * radius
            
            local x1 = center.x + math.cos(baseAngle) * r1
            local y1 = center.y + math.sin(baseAngle) * r1
            local z1 = center.z + h1
            
            local x2 = center.x + math.cos(baseAngle) * r2
            local y2 = center.y + math.sin(baseAngle) * r2
            local z2 = center.z + h2
            
            DrawLine(x1, y1, z1, x2, y2, z2, r, g, b, a)
        end
    end
end

-- ========================================
-- THREAD DE DESSIN DU DOME
-- ========================================

CreateThread(function()
    print('^2[PVP ZONES]^7 Thread de dessin du dome démarré')
    
    while true do
        local sleep = 500
        
        -- Ne dessiner que si on est en match et qu'on a une zone
        if isInMatch and currentArenaZone then
            sleep = 0
            
            local center = currentArenaZone.center
            local radius = currentArenaZone.radius
            
            -- Dessiner le cercle au sol (plus épais)
            for i = 1, 3 do
                DrawGroundCircle(
                    vector3(center.x, center.y, center.z + (i * 0.1)),
                    radius,
                    0, 255, 0, 150 -- Vert avec transparence
                )
            end
            
            -- Dessiner le dome
            DrawDome(center, radius, 0, 255, 0, 100)
            
            -- Debug: Afficher le rayon de la zone
            --[[
            local playerPos = GetEntityCoords(PlayerPedId())
            local distance = #(vector2(playerPos.x, playerPos.y) - vector2(center.x, center.y))
            
            SetTextScale(0.35, 0.35)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextColour(255, 255, 255, 215)
            SetTextEntry("STRING")
            AddTextComponentString(string.format("Zone: %.1fm | Distance: %.1fm", radius, distance))
            DrawText(0.5, 0.85)
            ]]--
        end
        
        Wait(sleep)
    end
end)

-- ========================================
-- THREAD DE VÉRIFICATION HORS ZONE
-- ========================================

CreateThread(function()
    print('^2[PVP ZONES]^7 Thread de vérification hors zone démarré')
    
    while true do
        local sleep = 500
        
        -- Ne vérifier que si on est en match et qu'on a une zone
        if isInMatch and currentArenaZone then
            sleep = 100 -- Vérifier plus souvent
            
            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)
            local center = currentArenaZone.center
            local radius = currentArenaZone.radius
            
            -- Vérifier si le joueur est dans la zone
            local isInZone = IsPlayerInZone(playerPos, center, radius)
            local distance = #(vector2(playerPos.x, playerPos.y) - vector2(center.x, center.y))
            
            if not isInZone then
                -- JOUEUR HORS ZONE
                print(string.format('^3[PVP ZONES]^7 Joueur hors zone! Distance: %.2fm / Rayon: %.2fm', distance, radius))
                
                -- Calculer le temps écoulé depuis le dernier tick de dégâts
                local currentTime = GetGameTimer()
                
                if currentTime - lastDamageTime >= DAMAGE_CONFIG.tickInterval then
                    -- Infliger des dégâts
                    local currentHealth = GetEntityHealth(playerPed)
                    local newHealth = currentHealth - DAMAGE_CONFIG.damagePerTick
                    
                    print(string.format('^1[PVP ZONES]^7 Dégâts infligés: -%d HP (Santé: %d -> %d)', 
                        DAMAGE_CONFIG.damagePerTick, currentHealth, newHealth))
                    
                    SetEntityHealth(playerPed, newHealth)
                    
                    -- Effet visuel de dégâts
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
                    
                    -- Son de dégâts
                    PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", true)
                    
                    -- Notification
                    ESX.ShowNotification('~r~⚠ Vous êtes hors de la zone de combat! (' .. DAMAGE_CONFIG.damagePerTick .. ' HP)')
                    
                    -- Mettre à jour le temps du dernier tick
                    lastDamageTime = currentTime
                    
                    -- Vérifier si le joueur est mort à cause de la zone
                    if newHealth <= 0 then
                        print('^1[PVP ZONES]^7 Joueur mort à cause de la zone!')
                        
                        -- Notifier le serveur de la mort par zone
                        TriggerServerEvent('pvp:playerDiedOutsideZone')
                    end
                end
                
                -- Affichage HUD d'avertissement
                SetTextScale(0.5, 0.5)
                SetTextFont(4)
                SetTextProportional(1)
                SetTextColour(255, 0, 0, 255)
                SetTextEntry("STRING")
                AddTextComponentString(string.format("⚠ HORS ZONE! Retournez dans la zone! (%.1fm)", distance - radius))
                DrawText(0.5, 0.15)
                
            elseif distance >= (radius - DAMAGE_CONFIG.warningDistance) then
                -- PROCHE DE LA LIMITE
                local distanceToEdge = radius - distance
                
                -- Affichage d'avertissement
                SetTextScale(0.4, 0.4)
                SetTextFont(4)
                SetTextProportional(1)
                SetTextColour(255, 165, 0, 255)
                SetTextEntry("STRING")
                AddTextComponentString(string.format("⚠ Attention! Limite de zone à %.1fm", distanceToEdge))
                DrawText(0.5, 0.15)
            end
        end
        
        Wait(sleep)
    end
end)

-- ========================================
-- EVENTS
-- ========================================

-- Event: Définir la zone de combat active
RegisterNetEvent('pvp:setArenaZone', function(arenaKey)
    print(string.format('^2[PVP ZONES]^7 Définition de la zone pour l\'arène: %s', arenaKey))
    
    local arena = Config.Arenas[arenaKey]
    
    if not arena then
        print(string.format('^1[PVP ZONES]^7 ERREUR: Arène %s introuvable!', arenaKey))
        return
    end
    
    if not arena.zone then
        print(string.format('^1[PVP ZONES]^7 ERREUR: L\'arène %s n\'a pas de zone définie!', arenaKey))
        return
    end
    
    currentArenaZone = {
        center = arena.zone.center,
        radius = arena.zone.radius
    }
    
    print(string.format('^2[PVP ZONES]^7 Zone activée - Centre: %.2f, %.2f, %.2f | Rayon: %.2f', 
        currentArenaZone.center.x, 
        currentArenaZone.center.y, 
        currentArenaZone.center.z, 
        currentArenaZone.radius))
end)

-- Event: Activer le système de zones (début du match)
RegisterNetEvent('pvp:enableZones', function()
    print('^2[PVP ZONES]^7 Activation du système de zones')
    isInMatch = true
    lastDamageTime = GetGameTimer()
end)

-- Event: Désactiver le système de zones (fin du match)
RegisterNetEvent('pvp:disableZones', function()
    print('^2[PVP ZONES]^7 Désactivation du système de zones')
    isInMatch = false
    currentArenaZone = nil
    lastDamageTime = 0
end)

-- ========================================
-- CLEANUP
-- ========================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^2[PVP ZONES]^7 Nettoyage du module zones')
    isInMatch = false
    currentArenaZone = nil
end)

print('^2[PVP ZONES]^7 Module initialisé')
