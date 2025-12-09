-- ================================================================================================
-- GUNFIGHT ARENA - INVENTORY BRIDGE v1.0
-- ================================================================================================
-- Gestion modulable des inventaires pour éviter les conflits
-- Compatible avec : qs-inventory, ox_inventory, qb-inventory, vanilla
-- ================================================================================================

InventoryBridge = {}

-- ================================================================================================
-- CONFIGURATION
-- ================================================================================================
local inventoryType = Config.InventorySystem or "auto"  -- "auto", "qs-inventory", "ox_inventory", "qb-inventory", "vanilla"
local detectedInventory = "vanilla"

-- ================================================================================================
-- FONCTION : DÉTECTION AUTOMATIQUE DE L'INVENTAIRE
-- ================================================================================================
local function DetectInventory()
    if inventoryType ~= "auto" then
        detectedInventory = inventoryType
        return inventoryType
    end
    
    -- Détection de qs-inventory
    if GetResourceState('qs-inventory') == 'started' then
        detectedInventory = "qs-inventory"
        return "qs-inventory"
    end
    
    -- Détection de ox_inventory
    if GetResourceState('ox_inventory') == 'started' then
        detectedInventory = "ox_inventory"
        return "ox_inventory"
    end
    
    -- Détection de qb-inventory
    if GetResourceState('qb-inventory') == 'started' then
        detectedInventory = "qb-inventory"
        return "qb-inventory"
    end
    
    -- Par défaut : vanilla (natives GTA)
    detectedInventory = "vanilla"
    return "vanilla"
end

-- ================================================================================================
-- FONCTION : LOG DEBUG
-- ================================================================================================
local function DebugLog(message, type)
    if not Config.DebugClient then return end
    
    local prefix = "^6[GF-Bridge]^0"
    if type == "error" then
        prefix = "^1[GF-Bridge ERROR]^0"
    elseif type == "success" then
        prefix = "^2[GF-Bridge OK]^0"
    end
    
    print(prefix .. " " .. message)
end

-- ================================================================================================
-- FONCTION : DONNER UNE ARME
-- ================================================================================================
function InventoryBridge.GiveWeapon(weaponName, ammo)
    local playerPed = PlayerPedId()
    local success = false
    
    DebugLog("Tentative de donner l'arme: " .. weaponName .. " (Inventaire: " .. detectedInventory .. ")")
    
    if detectedInventory == "qs-inventory" then
        -- ✅ QS-INVENTORY
        DebugLog("Utilisation de qs-inventory")
        
        -- Vérifier si l'arme existe déjà
        local hasWeapon = exports['qs-inventory']:HasItem(weaponName, 1)
        
        if not hasWeapon then
            -- Demander au serveur d'ajouter l'arme via l'inventaire
            TriggerServerEvent('gunfightarena:giveWeapon', weaponName, ammo)
            DebugLog("Demande serveur envoyée pour " .. weaponName, "success")
        else
            DebugLog("Le joueur possède déjà l'arme dans l'inventaire")
        end
        
        -- Petit délai pour laisser le temps au serveur de traiter
        Citizen.Wait(100)
        
        -- Équiper l'arme
        local weaponHash = GetHashKey(weaponName)
        if not HasPedGotWeapon(playerPed, weaponHash, false) then
            GiveWeaponToPed(playerPed, weaponHash, ammo, false, true)
        end
        SetCurrentPedWeapon(playerPed, weaponHash, true)
        SetPedAmmo(playerPed, weaponHash, ammo)
        
        success = true
        
    elseif detectedInventory == "ox_inventory" then
        -- ✅ OX_INVENTORY
        DebugLog("Utilisation de ox_inventory")
        TriggerServerEvent('gunfightarena:giveWeapon', weaponName, ammo)
        Citizen.Wait(100)
        
        local weaponHash = GetHashKey(weaponName)
        SetCurrentPedWeapon(playerPed, weaponHash, true)
        success = true
        
    elseif detectedInventory == "qb-inventory" then
        -- ✅ QB-INVENTORY
        DebugLog("Utilisation de qb-inventory")
        TriggerServerEvent('gunfightarena:giveWeapon', weaponName, ammo)
        Citizen.Wait(100)
        
        local weaponHash = GetHashKey(weaponName)
        SetCurrentPedWeapon(playerPed, weaponHash, true)
        success = true
        
    else
        -- ✅ VANILLA (natives GTA)
        DebugLog("Utilisation du système vanilla")
        local weaponHash = GetHashKey(weaponName)
        GiveWeaponToPed(playerPed, weaponHash, ammo, false, true)
        SetCurrentPedWeapon(playerPed, weaponHash, true)
        SetPedAmmo(playerPed, weaponHash, ammo)
        success = true
    end
    
    if success then
        DebugLog("Arme donnée avec succès", "success")
    else
        DebugLog("Échec de l'attribution de l'arme", "error")
    end
    
    return success
end

-- ================================================================================================
-- FONCTION : RETIRER UNE ARME
-- ================================================================================================
function InventoryBridge.RemoveWeapon(weaponName)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    
    DebugLog("Tentative de retirer l'arme: " .. weaponName .. " (Inventaire: " .. detectedInventory .. ")")
    
    if detectedInventory == "qs-inventory" then
        -- ✅ QS-INVENTORY
        DebugLog("Utilisation de qs-inventory pour retirer l'arme")
        
        -- Retirer l'arme du ped
        RemoveWeaponFromPed(playerPed, weaponHash)
        
        -- Demander au serveur de retirer l'arme de l'inventaire
        TriggerServerEvent('gunfightarena:removeWeapon', weaponName)
        DebugLog("Demande de suppression envoyée au serveur", "success")
        
    elseif detectedInventory == "ox_inventory" then
        -- ✅ OX_INVENTORY
        DebugLog("Utilisation de ox_inventory pour retirer l'arme")
        RemoveWeaponFromPed(playerPed, weaponHash)
        TriggerServerEvent('gunfightarena:removeWeapon', weaponName)
        
    elseif detectedInventory == "qb-inventory" then
        -- ✅ QB-INVENTORY
        DebugLog("Utilisation de qb-inventory pour retirer l'arme")
        RemoveWeaponFromPed(playerPed, weaponHash)
        TriggerServerEvent('gunfightarena:removeWeapon', weaponName)
        
    else
        -- ✅ VANILLA
        DebugLog("Utilisation du système vanilla pour retirer l'arme")
        RemoveWeaponFromPed(playerPed, weaponHash)
    end
    
    DebugLog("Arme retirée avec succès", "success")
end

-- ================================================================================================
-- FONCTION : RETIRER TOUTES LES ARMES
-- ================================================================================================
function InventoryBridge.RemoveAllWeapons()
    local playerPed = PlayerPedId()
    
    DebugLog("Retrait de toutes les armes")
    
    -- Retirer l'arme spécifique de l'arène
    InventoryBridge.RemoveWeapon(Config.WeaponHash)
    
    -- Optionnel : retirer toutes les autres armes (selon config)
    if Config.RemoveAllWeaponsOnExit then
        RemoveAllPedWeapons(playerPed, true)
        
        if detectedInventory ~= "vanilla" then
            TriggerServerEvent('gunfightarena:removeAllWeapons')
        end
    end
end

-- ================================================================================================
-- FONCTION : VÉRIFIER SI LE JOUEUR A UNE ARME
-- ================================================================================================
function InventoryBridge.HasWeapon(weaponName)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    
    if detectedInventory == "qs-inventory" then
        local hasInInventory = exports['qs-inventory']:HasItem(weaponName, 1)
        local hasEquipped = HasPedGotWeapon(playerPed, weaponHash, false)
        return hasInInventory or hasEquipped
        
    elseif detectedInventory == "ox_inventory" then
        local hasInInventory = exports.ox_inventory:Search('count', weaponName) > 0
        local hasEquipped = HasPedGotWeapon(playerPed, weaponHash, false)
        return hasInInventory or hasEquipped
        
    else
        return HasPedGotWeapon(playerPed, weaponHash, false)
    end
end

-- ================================================================================================
-- FONCTION : DÉFINIR LES MUNITIONS
-- ================================================================================================
function InventoryBridge.SetAmmo(weaponName, ammo)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    
    if HasPedGotWeapon(playerPed, weaponHash, false) then
        SetPedAmmo(playerPed, weaponHash, ammo)
        DebugLog("Munitions définies: " .. ammo, "success")
    else
        DebugLog("Le joueur n'a pas cette arme équipée", "error")
    end
end

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Wait(1000)
    
    local inventory = DetectInventory()
    
    print("^2[Gunfight Bridge]^0 Initialisé")
    print("^3[Gunfight Bridge]^0 Inventaire détecté: ^2" .. inventory .. "^0")
    
    if Config.DebugClient then
        DebugLog("========================================", "success")
        DebugLog("BRIDGE D'INVENTAIRE CHARGÉ", "success")
        DebugLog("Type détecté: " .. inventory, "success")
        DebugLog("========================================", "success")
    end
end)

-- ================================================================================================
-- EXPORT POUR AUTRES SCRIPTS (OPTIONNEL)
-- ================================================================================================
exports('GiveWeapon', InventoryBridge.GiveWeapon)
exports('RemoveWeapon', InventoryBridge.RemoveWeapon)
exports('HasWeapon', InventoryBridge.HasWeapon)
exports('GetInventoryType', function() return detectedInventory end)
