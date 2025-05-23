local QBCore = exports['qb-core']:GetCoreObject()
local lootedBins = {}
local playerReputations = {}
local areaExhaustion = {}
local playerCollectibles = {}

-- ==========================================--
--             SYSTEM UTILITIES              --
-- ==========================================--
local Systems = {
    inventory = {
        ox_inventory = function(player, item, amount)
            exports.ox_inventory:AddItem(player.PlayerData.source, item, amount)
            TriggerClientEvent('inventory:client:ItemBox', player.PlayerData.source, QBCore.Shared.Items[item], 'add')
            return true
        end,
        ['qb-inventory'] = function(player, item, amount)
            player.Functions.AddItem(item, amount)
            TriggerClientEvent('inventory:client:ItemBox', player.PlayerData.source, QBCore.Shared.Items[item], 'add')
            return true
        end,
        custom = function(player, item, amount)
            -- Placeholder for custom inventory implementation
            -- Add your custom inventory code here
            return true
        end
    },
    
    removeItem = {
        ox_inventory = function(player, item, amount)
            exports.ox_inventory:RemoveItem(player.PlayerData.source, item, amount)
            TriggerClientEvent('inventory:client:ItemBox', player.PlayerData.source, QBCore.Shared.Items[item], 'remove')
            return true
        end,
        ['qb-inventory'] = function(player, item, amount)
            player.Functions.RemoveItem(item, amount)
            TriggerClientEvent('inventory:client:ItemBox', player.PlayerData.source, QBCore.Shared.Items[item], 'remove')
            return true
        end,
        custom = function(player, item, amount)
            -- Placeholder for custom inventory removal
            -- Add your custom inventory code here
            return true
        end
    },
    
    checkItem = {
        ox_inventory = function(player, item, amount)
            local count = exports.ox_inventory:Search(player.PlayerData.source, 'count', item)
            return count >= amount
        end,
        ['qb-inventory'] = function(player, item, amount)
            local items = player.Functions.GetItemsByName(item)
            local count = 0
            for _, itemData in pairs(items) do
                count = count + itemData.amount
            end
            return count >= amount
        end,
        custom = function(player, item, amount)
            -- Placeholder for custom item check
            -- Add your custom inventory code here
            return true
        end
    },
    
    notify = {
        ox_lib = function(source, data)
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Trash Bin',
                description = data.message,
                type = data.type
            })
        end,
        ['qb-notify'] = function(source, data)
            TriggerClientEvent('QBCore:Notify', source, data.message, data.type)
        end,
        custom = function(source, data)
            -- Placeholder for custom notification implementation
            -- Add your custom notification code here
        end
    }
}

-- Initialize the selected systems
local function useSystem(system, ...)
    local selectedSystem = Config.Systems[system]
    if Systems[system] and Systems[system][selectedSystem] then
        return Systems[system][selectedSystem](...)
    else
        print(('Warning: System %s.%s not found'):format(system, selectedSystem))
        return false
    end
end

-- Format notification message with variables
local function formatMessage(message, ...)
    return string.format(message, ...)
end

-- ==========================================--
--             LOOT FUNCTIONS                --
-- ==========================================--
-- Add loot to player inventory
local function addLootToPlayer(player, item, amount)
    local success = useSystem('inventory', player, item, amount)
    
    if success then
        local itemLabel = QBCore.Shared.Items[item] and QBCore.Shared.Items[item].label or item
        useSystem('notify', player.PlayerData.source, {
            message = formatMessage(Config.Notifications.success, amount, itemLabel),
            type = 'success'
        })
    end
end

-- Get location-based loot for an area
local function getLocationBasedLoot(coords)
    for locationName, locationData in pairs(Config.LocationBasedLoot) do
        local distance = #(coords - locationData.center)
        if distance <= locationData.radius then
            return locationData.items
        end
    end
    return {}
end

-- Apply time and weather effects to loot chance
local function applyEnvironmentEffects(chance, coords)
    local modifier = 1.0
    
    -- Time impact
    if Config.TimeImpact.enabled then
        local currentHour = tonumber(os.date('%H'))
        local nightBonus = Config.TimeImpact.nightBonus
        
        -- Check if current time is within night range
        if (nightBonus.timeRange[1] <= nightBonus.timeRange[2] and 
           currentHour >= nightBonus.timeRange[1] and currentHour <= nightBonus.timeRange[2]) or
           (nightBonus.timeRange[1] > nightBonus.timeRange[2] and 
           (currentHour >= nightBonus.timeRange[1] or currentHour <= nightBonus.timeRange[2])) then
            modifier = modifier * nightBonus.chanceMultiplier
        end
    end
    
    -- Weather impact would go here if we had server-side weather access
    -- For actual implementation, you might want to pass weather from client to server
    
    -- Apply area exhaustion
    modifier = modifier * isAreaExhausted(coords)
    
    return chance * modifier
end

-- Function to increase player's "trash reputation"
local function increaseTrashRep(playerId, amount)
    if not playerReputations[playerId] then
        playerReputations[playerId] = 0
    end
    
    playerReputations[playerId] = playerReputations[playerId] + amount
    
    -- Check for level ups
    local newLevel = math.floor(playerReputations[playerId] / 100) + 1
    local oldLevel = math.floor((playerReputations[playerId] - amount) / 100) + 1
    
    if newLevel > oldLevel then
        useSystem('notify', playerId, {
            message = "Your dumpster diving skills improved to level " .. newLevel,
            type = 'success'
        })
    end
    
    return playerReputations[playerId]
end

-- Function to check if an area is exhausted of good loot
local function isAreaExhausted(coords)
    local areaKey = math.floor(coords.x/50) .. "_" .. math.floor(coords.y/50)
    
    if not areaExhaustion[areaKey] then
        areaExhaustion[areaKey] = {
            searches = 0,
            lastReset = os.time()
        }
    end
    
    -- Reset counter after 3 hours
    if os.time() - areaExhaustion[areaKey].lastReset > 10800 then
        areaExhaustion[areaKey] = {
            searches = 0,
            lastReset = os.time()
        }
    end
    
    areaExhaustion[areaKey].searches = areaExhaustion[areaKey].searches + 1
    
    -- Return decreased chance based on how many searches in the area
    return math.max(0.2, 1 - (areaExhaustion[areaKey].searches * 0.1))
end

-- ==========================================--
--           COLLECTIBLES SYSTEM             --
-- ==========================================--
-- Initialize collectibles for a player
local function initPlayerCollectibles(playerId)
    if not playerCollectibles[playerId] then
        playerCollectibles[playerId] = {}
    end
    return playerCollectibles[playerId]
end

-- Add collectible to player inventory
local function addCollectibleToPlayer(playerId, collectibleId)
    local playerData = initPlayerCollectibles(playerId)
    playerData[collectibleId] = (playerData[collectibleId] or 0) + 1
end

-- Check collectible set completion
local function checkCollectiblesCompletion(playerId)
    local playerData = playerCollectibles[playerId]
    if not playerData then return false end
    
    for _, set in pairs(Config.Collectibles.rewards) do
        local hasAllItems = true
        
        for _, itemId in pairs(set.required) do
            if not playerData[itemId] or playerData[itemId] < 1 then
                hasAllItems = false
                break
            end
        end
        
        if hasAllItems then
            return true
        end
    end
    
    return false
end

-- ==========================================--
--             EVENT HANDLERS                --
-- ==========================================--

-- Register server event for loot attempt
RegisterNetEvent('mns-trash:attemptLoot', function(binId, isRoute)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local currentTime = os.time()
    local coords = GetEntityCoords(GetPlayerPed(src))
    
    -- Check cooldown (unless part of a route)
    if not isRoute and lootedBins[binId] and (currentTime - lootedBins[binId]) < Config.Cooldown then
        useSystem('notify', src, {
            message = Config.Notifications.cooldown,
            type = 'error'
        })
        return
    end
    
    -- Set cooldown
    lootedBins[binId] = currentTime
    
    -- Attempt to find loot
    local foundItem = false
    local repGain = 0
    
    -- Get location-specific items first
    local locationItems = getLocationBasedLoot(coords)
    
    -- Check for location-specific loot
    for _, loot in pairs(locationItems) do
        local adjustedChance = applyEnvironmentEffects(loot.chance, coords)
        if math.random(1, 100) <= adjustedChance then
            local amount = math.random(loot.min, loot.max)
            addLootToPlayer(player, loot.item, amount)
            repGain = repGain + 10 -- More reputation for finding location-specific items
            foundItem = true
        end
    end
    
    -- Check for regular loot items
    for _, loot in pairs(Config.LootItems) do
        local adjustedChance = applyEnvironmentEffects(loot.chance, coords)
        if math.random(1, 100) <= adjustedChance then
            local amount = math.random(loot.min, loot.max)
            addLootToPlayer(player, loot.item, amount)
            repGain = repGain + 5
            foundItem = true
        end
    end
    
    -- Check for rare items
    for _, loot in pairs(Config.RareItems) do
        local adjustedChance = applyEnvironmentEffects(loot.chance, coords)
        if math.random(1, 100) <= adjustedChance then
            local amount = math.random(loot.min, loot.max)
            addLootToPlayer(player, loot.item, amount)
            repGain = repGain + 20 -- More reputation for finding rare items
            foundItem = true
        end
    end
    
    -- Check for collectibles
    if Config.Collectibles.enabled then
        for _, collectible in pairs(Config.Collectibles.items) do
            if math.random(1, 100) <= collectible.chance then
                addCollectibleToPlayer(src, collectible.id)
                
                useSystem('notify', src, {
                    message = "You found a " .. collectible.name .. "!",
                    type = 'success'
                })
                
                repGain = repGain + 15 -- Bonus reputation for finding collectibles
                foundItem = true
            end
        end
    end
    
    -- Increase reputation if items were found
    if foundItem then
        -- Bonus reputation if part of a route
        if isRoute then
            repGain = repGain * 1.5
        end
        
        increaseTrashRep(src, repGain)
    else
        useSystem('notify', src, {
            message = Config.Notifications.empty,
            type = 'error'
        })
    end
end)

-- Register event for route completion
RegisterNetEvent('mns-trash:completeRoute', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    
    -- Add route completion bonus
    local rewardItem = Config.TrashRoutes.rewards.bonus.item
    local amount = math.random(Config.TrashRoutes.rewards.bonus.min, Config.TrashRoutes.rewards.bonus.max)
    
    if math.random(1, 100) <= Config.TrashRoutes.rewards.bonusChance then
        addLootToPlayer(player, rewardItem, amount)
        increaseTrashRep(src, 50) -- Big reputation boost for completing route
    end
end)

-- Register event for losing lockpick on failed attempt
RegisterNetEvent('mns-trash:loseLockpick', function(lockpickItem)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    
    useSystem('removeItem', player, lockpickItem, 1)
    
    useSystem('notify', src, {
        message = "Your lockpick broke.",
        type = 'error'
    })
end)

-- Register event for claiming collectible reward
RegisterNetEvent('mns-trash:claimCollectibleReward', function(setName)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    
    -- Find the reward set
    local rewardSet = nil
    for _, set in pairs(Config.Collectibles.rewards) do
        if set.name == setName then
            rewardSet = set
            break
        end
    end
    
    if not rewardSet then return end
    
    -- Check if player has all required items
    local playerData = playerCollectibles[src]
    if not playerData then return end
    
    for _, itemId in pairs(rewardSet.required) do
        if not playerData[itemId] or playerData[itemId] < 1 then
            useSystem('notify', src, {
                message = "You don't have all required collectibles.",
                type = 'error'
            })
            return
        end
    end
    
    -- Remove collectibles from player
    for _, itemId in pairs(rewardSet.required) do
        playerData[itemId] = playerData[itemId] - 1
    end
    
    -- Give reward
    addLootToPlayer(player, rewardSet.reward.item, rewardSet.reward.amount)
    
    useSystem('notify', src, {
        message = "You've exchanged your " .. setName .. " collection for a reward!",
        type = 'success'
    })
    
    -- Bonus reputation for completing a collection
    increaseTrashRep(src, 75)
end)

-- Register event for crafting items
RegisterNetEvent('mns-trash:craftItem', function(recipeName)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    
    -- Find the recipe
    local recipe = nil
    for _, r in pairs(Config.Crafting.recipes) do
        if r.name == recipeName then
            recipe = r
            break
        end
    end
    
    if not recipe then return end
    
    -- Check if player has all ingredients
    for _, ingredient in pairs(recipe.items) do
        local hasItem = useSystem('checkItem', player, ingredient.item, ingredient.amount)
        if not hasItem then
            useSystem('notify', src, {
                message = "You don't have enough " .. QBCore.Shared.Items[ingredient.item].label,
                type = 'error'
            })
            return
        end
    end
    
    -- Remove ingredients
    for _, ingredient in pairs(recipe.items) do
        useSystem('removeItem', player, ingredient.item, ingredient.amount)
    end
    
    -- Give crafted item
    addLootToPlayer(player, recipe.result.item, recipe.result.amount)
    
    useSystem('notify', src, {
        message = "You crafted " .. recipe.result.amount .. "x " .. QBCore.Shared.Items[recipe.result.item].label,
        type = 'success'
    })
    
    -- Reputation gain for crafting
    increaseTrashRep(src, 15)
end)

-- ==========================================--
--             CALLBACKS                     --
-- ==========================================--
-- Callback to get player collectibles
QBCore.Functions.CreateCallback('mns-trash:getCollectibles', function(source, cb)
    local src = source
    
    -- Initialize if needed
    if not playerCollectibles[src] then
        playerCollectibles[src] = {}
    end
    
    cb(playerCollectibles[src])
end)

-- Callback to get player reputation
QBCore.Functions.CreateCallback('mns-trash:getReputation', function(source, cb)
    local src = source
    
    -- Initialize if needed
    if not playerReputations[src] then
        playerReputations[src] = 0
    end
    
    local level = math.floor(playerReputations[src] / 100) + 1
    local progress = playerReputations[src] % 100
    
    cb({
        level = level,
        points = playerReputations[src],
        progress = progress
    })
end)

-- ==========================================--
--            DATABASE FUNCTIONS             --
-- ==========================================--

-- Load player reputation from database
local function LoadPlayerReputation(citizenid)
    if not citizenid then return 0 end
    
    local result = MySQL.Sync.fetchScalar('SELECT reputation FROM trash_reputation WHERE citizenid = ?', {citizenid})
    return result or 0
end

-- Save player reputation to database
local function SavePlayerReputation(citizenid, reputation)
    if not citizenid then return end
    
    MySQL.Async.execute('INSERT INTO trash_reputation (citizenid, reputation) VALUES (?, ?) ON DUPLICATE KEY UPDATE reputation = ?', 
        {citizenid, reputation, reputation})
end

-- Load player collectibles from database
local function LoadPlayerCollectibles(citizenid)
    if not citizenid then return {} end
    
    local collectibles = {}
    local result = MySQL.Sync.fetchAll('SELECT collectible_id, amount FROM trash_collectibles WHERE citizenid = ?', {citizenid})
    
    if result and #result > 0 then
        for _, item in pairs(result) do
            collectibles[item.collectible_id] = item.amount
        end
    end
    
    return collectibles
end

-- Save player collectibles to database
local function SavePlayerCollectibles(citizenid, collectibles)
    if not citizenid or not collectibles then return end
    
    -- First delete existing entries
    MySQL.Async.execute('DELETE FROM trash_collectibles WHERE citizenid = ?', {citizenid})
    
    -- Then insert new entries
    for collectibleId, amount in pairs(collectibles) do
        if amount > 0 then
            MySQL.Async.execute('INSERT INTO trash_collectibles (citizenid, collectible_id, amount) VALUES (?, ?, ?)',
                {citizenid, collectibleId, amount})
        end
    end
end

-- Save area exhaustion to database
local function SaveAreaExhaustion()
    -- First clear old records
    MySQL.Async.execute('DELETE FROM trash_area_exhaustion', {})
    
    -- Then insert current ones
    for areaKey, data in pairs(areaExhaustion) do
        MySQL.Async.execute('INSERT INTO trash_area_exhaustion (area_key, searches, last_reset) VALUES (?, ?, ?)',
            {areaKey, data.searches, data.lastReset})
    end
end

-- Load area exhaustion from database
local function LoadAreaExhaustion()
    local result = MySQL.Sync.fetchAll('SELECT * FROM trash_area_exhaustion', {})
    
    if result and #result > 0 then
        for _, area in pairs(result) do
            areaExhaustion[area.area_key] = {
                searches = area.searches,
                lastReset = area.last_reset
            }
        end
    end
end

-- Update global statistics
local function UpdateStats(statName, value)
    MySQL.Async.execute('UPDATE trash_stats SET ' .. statName .. ' = ' .. statName .. ' + ?', {value})
end

-- ==========================================--
--             MAINTENANCE                   --
-- ==========================================--
-- Clean up cooldowns periodically to prevent memory issues
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(900000) -- 15 minutes
        local currentTime = os.time()
        local cleanupCount = 0
        
        for binId, timestamp in pairs(lootedBins) do
            if (currentTime - timestamp) > Config.Cooldown then
                lootedBins[binId] = nil
                cleanupCount = cleanupCount + 1
            end
        end
        
        if cleanupCount > 0 then
            print(string.format("Cleaned up %d expired trash bin cooldowns", cleanupCount))
        end
    end
end)

-- Save player reputation/collectibles periodically
Citizen.CreateThread(function()
    Wait(10000) -- Wait for server to fully start
    
    -- Load area exhaustion on startup
    LoadAreaExhaustion()
    
    while true do
        Citizen.Wait(300000) -- 5 minutes
        
        -- Save all player data
        local saveCount = 0
        for src, rep in pairs(playerReputations) do
            local player = QBCore.Functions.GetPlayer(src)
            if player then
                local citizenid = player.PlayerData.citizenid
                SavePlayerReputation(citizenid, rep)
                
                if playerCollectibles[src] then
                    SavePlayerCollectibles(citizenid, playerCollectibles[src])
                end
                
                saveCount = saveCount + 1
            end
        end
        
        -- Save area exhaustion
        SaveAreaExhaustion()
        
        if saveCount > 0 then
            print("Saved trash data for " .. saveCount .. " players")
        end
    end
end)

-- ==========================================--
--            PLAYER EVENTS                  --
-- ==========================================--

-- Load player data when they join
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Load reputation
    playerReputations[src] = LoadPlayerReputation(citizenid)
    
    -- Load collectibles
    playerCollectibles[src] = LoadPlayerCollectibles(citizenid)
    
    -- Notify player of their level if they have reputation
    if playerReputations[src] > 0 then
        local level = math.floor(playerReputations[src] / 100) + 1
        
        Wait(5000) -- Wait a few seconds after joining to avoid notification spam
        
        useSystem('notify', src, {
            message = "Your dumpster diving skill level is " .. level,
            type = 'info'
        })
    end
end)

-- Save player data when they disconnect
AddEventHandler('playerDropped', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Save reputation if they have any
    if playerReputations[src] then
        SavePlayerReputation(citizenid, playerReputations[src])
    end
    
    -- Save collectibles if they have any
    if playerCollectibles[src] then
        SavePlayerCollectibles(citizenid, playerCollectibles[src])
    end
    
    -- Clear from memory
    playerReputations[src] = nil
    playerCollectibles[src] = nil
end)
