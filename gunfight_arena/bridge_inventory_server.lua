-- ================================================================================================
-- GUNFIGHT ARENA - INVENTORY BRIDGE SERVER v1.1 (CORRIGÉ)
-- ================================================================================================
-- ✅ Correction syntaxe qs-inventory RemoveItem
-- ================================================================================================

local ESX = exports['es_extended']:getSharedObject()

-- ================================================================================================
-- CONFIGURATION
-- ================================================================================================
local inventoryType = Config.InventorySystem or "auto"
local detectedInventory = "vanilla"

-- ================================================================================================
-- FONCTION : DÉTECTION AUTOMATIQUE DE L'INVENTAIRE
-- ================================================================================================
local function DetectInventory()
    if inventoryType ~= "auto" then
        detectedInventory = inventoryType
        return inventoryType
    end
    
    if GetResourceState('qs-inventory') == 'started' then
        detectedInventory = "qs-inventory"
        return "qs-inventory"
    end
    
    if GetResourceState('ox_inventory') == 'started' then
        detectedInventory = "ox_inventory"
        return "ox_inventory"
    end
    
    if GetResourceState('qb-inventory') == 'started' then
        detectedInventory = "qb-inventory"
        return "qb-inventory"
    end
    
    detectedInventory = "vanilla"
    return "vanilla"
end

-- ================================================================================================
-- FONCTION : LOG DEBUG
-- ================================================================================================
local function DebugLog(message, type)
    if not Config.DebugServer then return end
    
    local prefix = "^6[GF-Bridge-Server]^0"
    if type == "error" then
        prefix = "^1[GF-Bridge-Server ERROR]^0"
    elseif type == "success" then
        prefix = "^2[GF-Bridge-Server OK]^0"
    end
    
    print(prefix .. " " .. message)
end

-- ================================================================================================
-- EVENT : DONNER UNE ARME AU JOUEUR
-- ================================================================================================
RegisterNetEvent('gunfightarena:giveWeapon')
AddEventHandler('gunfightarena:giveWeapon', function(weaponName, ammo)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then
        DebugLog("Joueur ESX non trouvé: " .. src, "error")
        return
    end
    
    DebugLog("Demande d'arme reçue pour le joueur " .. src .. ": " .. weaponName)
    
    if detectedInventory == "qs-inventory" then
        -- ✅ QS-INVENTORY (SYNTAXE CORRIGÉE)
        DebugLog("Utilisation de qs-inventory (serveur)")
        
        -- Vérifier si le joueur a déjà l'arme
        local hasWeapon = exports['qs-inventory']:GetItemTotalAmount(src, weaponName)
        
        if not hasWeapon or hasWeapon == 0 then
            -- ✅ CORRECTION : Utiliser la bonne syntaxe pour AddItem
            local success = exports['qs-inventory']:AddItem(src, weaponName, 1)
            
            if success then
                DebugLog("Arme ajoutée avec succès à l'inventaire", "success")
                
                -- Ajouter les munitions si configuré
                if Config.GiveAmmoSeparately and ammo > 0 then
                    local ammoType = Config.WeaponAmmoTypes[weaponName] or "ammo-9"
                    exports['qs-inventory']:AddItem(src, ammoType, ammo)
                    DebugLog("Munitions ajoutées: " .. ammo .. "x " .. ammoType, "success")
                end
            else
                DebugLog("Échec de l'ajout de l'arme à l'inventaire", "error")
            end
        else
            DebugLog("Le joueur possède déjà cette arme")
        end
        
    elseif detectedInventory == "ox_inventory" then
        -- ✅ OX_INVENTORY
        DebugLog("Utilisation de ox_inventory (serveur)")
        
        local success = exports.ox_inventory:AddItem(src, weaponName, 1)
        
        if success then
            DebugLog("Arme ajoutée avec succès (ox_inventory)", "success")
            
            if Config.GiveAmmoSeparately and ammo > 0 then
                local ammoType = Config.WeaponAmmoTypes[weaponName] or "ammo-9"
                exports.ox_inventory:AddItem(src, ammoType, ammo)
            end
        else
            DebugLog("Échec de l'ajout de l'arme (ox_inventory)", "error")
        end
        
    elseif detectedInventory == "qb-inventory" then
        -- ✅ QB-INVENTORY
        DebugLog("Utilisation de qb-inventory (serveur)")
        
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddItem(weaponName, 1)
            
            if Config.GiveAmmoSeparately and ammo > 0 then
                local ammoType = Config.WeaponAmmoTypes[weaponName] or "pistol_ammo"
                Player.Functions.AddItem(ammoType, ammo)
            end
            
            DebugLog("Arme ajoutée avec succès (qb-inventory)", "success")
        end
        
    else
        -- ✅ VANILLA - Rien à faire côté serveur pour les natives
        DebugLog("Mode vanilla - pas d'action serveur nécessaire")
    end
end)

-- ================================================================================================
-- EVENT : RETIRER UNE ARME DU JOUEUR (CORRIGÉ v1.1)
-- ================================================================================================
RegisterNetEvent('gunfightarena:removeWeapon')
AddEventHandler('gunfightarena:removeWeapon', function(weaponName)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then
        DebugLog("Joueur ESX non trouvé: " .. src, "error")
        return
    end
    
    DebugLog("Demande de retrait d'arme pour le joueur " .. src .. ": " .. weaponName)
    
    if detectedInventory == "qs-inventory" then
        -- ✅ QS-INVENTORY (SYNTAXE CORRIGÉE v1.1)
        DebugLog("Utilisation de qs-inventory pour retirer l'arme (serveur)")
        
        local hasWeapon = exports['qs-inventory']:GetItemTotalAmount(src, weaponName)
        
        if hasWeapon and hasWeapon > 0 then
            -- ✅ CORRECTION : Syntaxe simple sans callback
            local success = exports['qs-inventory']:RemoveItem(src, weaponName, 1)
            
            if success then
                DebugLog("Arme retirée avec succès de l'inventaire", "success")
                
                -- Retirer les munitions si configuré
                if Config.GiveAmmoSeparately then
                    local ammoType = Config.WeaponAmmoTypes[weaponName] or "ammo-9"
                    local ammoCount = exports['qs-inventory']:GetItemTotalAmount(src, ammoType)
                    
                    if ammoCount and ammoCount > 0 then
                        exports['qs-inventory']:RemoveItem(src, ammoType, ammoCount)
                        DebugLog("Munitions retirées: " .. ammoCount .. "x " .. ammoType, "success")
                    end
                end
            else
                DebugLog("Échec du retrait de l'arme de l'inventaire", "error")
            end
        else
            DebugLog("Le joueur ne possède pas cette arme dans l'inventaire")
        end
        
    elseif detectedInventory == "ox_inventory" then
        -- ✅ OX_INVENTORY
        DebugLog("Utilisation de ox_inventory pour retirer l'arme (serveur)")
        
        local success = exports.ox_inventory:RemoveItem(src, weaponName, 1)
        
        if success then
            DebugLog("Arme retirée avec succès (ox_inventory)", "success")
            
            if Config.GiveAmmoSeparately then
                local ammoType = Config.WeaponAmmoTypes[weaponName] or "ammo-9"
                local ammoCount = exports.ox_inventory:Search(src, 'count', ammoType)
                
                if ammoCount > 0 then
                    exports.ox_inventory:RemoveItem(src, ammoType, ammoCount)
                end
            end
        else
            DebugLog("Échec du retrait de l'arme (ox_inventory)", "error")
        end
        
    elseif detectedInventory == "qb-inventory" then
        -- ✅ QB-INVENTORY
        DebugLog("Utilisation de qb-inventory pour retirer l'arme (serveur)")
        
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(weaponName, 1)
            
            if Config.GiveAmmoSeparately then
                local ammoType = Config.WeaponAmmoTypes[weaponName] or "pistol_ammo"
                local item = Player.Functions.GetItemByName(ammoType)
                
                if item then
                    Player.Functions.RemoveItem(ammoType, item.amount)
                end
            end
            
            DebugLog("Arme retirée avec succès (qb-inventory)", "success")
        end
        
    else
        -- ✅ VANILLA - Rien à faire côté serveur
        DebugLog("Mode vanilla - pas d'action serveur nécessaire")
    end
end)

-- ================================================================================================
-- EVENT : RETIRER TOUTES LES ARMES
-- ================================================================================================
RegisterNetEvent('gunfightarena:removeAllWeapons')
AddEventHandler('gunfightarena:removeAllWeapons', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    DebugLog("Demande de retrait de toutes les armes pour le joueur " .. src)
    
    if detectedInventory == "qs-inventory" then
        -- Retirer l'arme de l'arène spécifiquement
        DebugLog("Retrait de toutes les armes (qs-inventory)")
        TriggerEvent('gunfightarena:removeWeapon', Config.WeaponHash)
        
    elseif detectedInventory == "ox_inventory" then
        DebugLog("Retrait de toutes les armes (ox_inventory)")
        TriggerEvent('gunfightarena:removeWeapon', Config.WeaponHash)
        
    elseif detectedInventory == "qb-inventory" then
        DebugLog("Retrait de toutes les armes (qb-inventory)")
        TriggerEvent('gunfightarena:removeWeapon', Config.WeaponHash)
    end
end)

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Wait(1000)
    
    local inventory = DetectInventory()
    
    print("^2[Gunfight Bridge Server v1.1]^0 Initialisé")
    print("^3[Gunfight Bridge Server v1.1]^0 Inventaire détecté: ^2" .. inventory .. "^0")
    print("^3[Gunfight Bridge Server v1.1]^0 Correction: Syntaxe qs-inventory RemoveItem")
    
    if Config.DebugServer then
        DebugLog("========================================", "success")
        DebugLog("BRIDGE SERVEUR CHARGÉ v1.1", "success")
        DebugLog("Type détecté: " .. inventory, "success")
        DebugLog("Correction: RemoveItem sans callback", "success")
        DebugLog("========================================", "success")
    end
end)
