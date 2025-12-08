-- ================================================================================================
-- GUNFIGHT ARENA - CUSTOM REVIVE
-- ================================================================================================
-- Gestion personnalisée de la réanimation dans l'arène
-- Ce fichier peut être désactivé si vous avez un système de mort personnalisé
-- ================================================================================================

-- Récupération d'ESX
ESX = exports["es_extended"]:getSharedObject()

local deathHandled = false

-- ================================================================================================
-- FONCTION : LOG DEBUG
-- ================================================================================================
local function DebugLog(message, type)
    if not Config.DebugClient then return end
    
    local prefix = "^6[GF-Revive]^0"
    if type == "error" then
        prefix = "^1[GF-Revive ERROR]^0"
    elseif type == "success" then
        prefix = "^2[GF-Revive OK]^0"
    end
    
    print(prefix .. " " .. message)
end

-- ================================================================================================
-- THREAD : GESTION DE LA MORT ET RÉANIMATION
-- ================================================================================================
Citizen.CreateThread(function()
    DebugLog("Thread custom revive démarré")
    
    while true do
        Citizen.Wait(0)
        
        -- Vérifier uniquement si le joueur est dans l'arène
        if isInArena then
            local playerPed = PlayerPedId()
            
            -- Détection de la mort
            if IsEntityDead(playerPed) and not deathHandled then
                DebugLog("=== MORT DÉTECTÉE ===")
                DebugLog("Démarrage du processus de réanimation")
                
                deathHandled = true
                
                -- Attendre le délai configuré pour la réanimation
                DebugLog("Attente de " .. Config.RespawnDelay .. "ms")
                Citizen.Wait(Config.RespawnDelay)
                
                -- Vérifier si le joueur est toujours mort
                if IsEntityDead(playerPed) then
                    DebugLog("Joueur toujours mort, réanimation en cours...")
                    
                    -- Arrêt des animations pour éviter les conflits
                    ClearPedTasksImmediately(playerPed)
                    DebugLog("Animations nettoyées")
                    
                    -- Déterminer le point de respawn selon la zone actuelle
                    if currentZone then
                        local zoneCfg = Config["Zone" .. currentZone]
                        if zoneCfg then
                            local randomIndex = math.random(1, #zoneCfg.respawnPoints)
                            DebugLog("Point de respawn sélectionné: " .. randomIndex .. " dans la zone " .. currentZone)
                            
                            -- Notification au serveur
                            TriggerServerEvent('gunfightarena:playerDied', randomIndex, nil)
                            DebugLog("Événement de mort envoyé au serveur", "success")
                        else
                            DebugLog("Configuration de zone introuvable pour zone " .. currentZone, "error")
                            TriggerEvent('gunfightarena:exit')
                        end
                    else
                        DebugLog("currentZone est nil, sortie de l'arène", "error")
                        TriggerEvent('gunfightarena:exit')
                    end
                else
                    DebugLog("Joueur déjà réanimé par un autre système")
                end
                
                -- Délai supplémentaire pour éviter plusieurs déclenchements
                DebugLog("Délai anti-spam de 3 secondes")
                Citizen.Wait(3000)
                deathHandled = false
                DebugLog("Gestionnaire de mort réinitialisé", "success")
                DebugLog("=====================")
            end
        else
            -- Reset si le joueur n'est pas dans l'arène
            if deathHandled then
                deathHandled = false
                DebugLog("Reset du gestionnaire (joueur hors arène)")
            end
        end
        
        Citizen.Wait(0)
    end
end)

-- ================================================================================================
-- COMMANDE : TEST DE MORT (DÉVELOPPEMENT)
-- ================================================================================================
RegisterCommand(Config.TestDeathCommand, function(source, args, rawCommand)
    DebugLog("=== COMMANDE TEST MORT ===")
    
    if not isInArena then
        DebugLog("Impossible : joueur pas dans l'arène", "error")
        TriggerEvent('chat:addMessage', {
            args = { "^1Erreur :", "Vous devez être dans l'arène pour tester." }
        })
        return
    end
    
    local playerPed = PlayerPedId()
    DebugLog("Mise à mort du joueur pour test")
    SetEntityHealth(playerPed, 0)
    DebugLog("Joueur tué (test)", "success")
    DebugLog("==========================")
    
    TriggerEvent('chat:addMessage', {
        args = { "^3Test :", "Mort simulée." }
    })
end, false)

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
DebugLog("========================================", "success")
DebugLog("CUSTOM REVIVE - CHARGÉ", "success")
DebugLog("Commande de test: /" .. Config.TestDeathCommand, "success")
DebugLog("========================================", "success")
