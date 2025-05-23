local QBCore = exports['qb-core']:GetCoreObject()
local activeRoute = nil
local currentBinIndex = 0
local routeBlip = nil
local routeCompleted = false
local recyclingPed = nil

-- ==========================================--
--             SYSTEM UTILITIES              --
-- ==========================================--
local Systems = {
    target = {
        ox_target = function(models, options)
            exports.ox_target:addModel(models, options)
        end,
        ['qb-target'] = function(models, options)
            exports['qb-target']:AddTargetModel(models, {
                options = options,
                distance = 1.5
            })
        end,
        custom = function(models, options)
            -- Placeholder for custom target implementation
            -- Add your custom target code here
        end
    },
    
    progressBar = {
        ox_lib = function(data, onComplete, onCancel)
            if lib.progressCircle({
                duration = data.duration,
                label = data.label,
                position = 'bottom',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true
                },
                anim = {
                    scenario = data.scenario
                }
            }) then
                onComplete()
            else
                onCancel()
            end
        end,
        ['qb-progressbar'] = function(data, onComplete, onCancel)
            QBCore.Functions.Progressbar("search_trash", data.label, data.duration, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = nil,
                anim = nil,
                flags = 49,
                scenario = data.scenario,
            }, {}, {}, function()
                onComplete()
            end, function()
                onCancel()
            end)
        end,
        custom = function(data, onComplete, onCancel)
            -- Placeholder for custom progress bar implementation
            -- Add your custom progress bar code here
            Wait(data.duration)
            onComplete()
        end
    },
    
    notify = {
        ox_lib = function(data)
            lib.notify({
                title = 'Trash Bin',
                description = data.message,
                type = data.type
            })
        end,
        ['qb-notify'] = function(data)
            QBCore.Functions.Notify(data.message, data.type)
        end,
        custom = function(data)
            -- Placeholder for custom notification implementation
            -- Add your custom notification code here
        end
    },

    minigame = {
        ox_lib = function(difficulty, callbackSuccess, callbackFail)
            if difficulty == 'easy' then
                if lib.skillCheck(Config.LockpickSettings.easy.circles, {'w', 'a', 's', 'd'}, Config.LockpickSettings.easy.time) then
                    callbackSuccess()
                else
                    callbackFail()
                end
            elseif difficulty == 'medium' then
                if lib.skillCheck(Config.LockpickSettings.medium.circles, {'w', 'a', 's', 'd'}, Config.LockpickSettings.medium.time) then
                    callbackSuccess()
                else
                    callbackFail()
                end
            elseif difficulty == 'hard' then
                if lib.skillCheck(Config.LockpickSettings.hard.circles, {'w', 'a', 's', 'd'}, Config.LockpickSettings.hard.time) then
                    callbackSuccess()
                else
                    callbackFail()
                end
            end
        end,
        ['qb-lockpick'] = function(difficulty, callbackSuccess, callbackFail)
            -- Adjust difficulty based on config
            local difficultySettings = {
                easy = { amount = 2, time = 10 },
                medium = { amount = 3, time = 15 },
                hard = { amount = 4, time = 20 }
            }
            
            local settings = difficultySettings[difficulty]
            exports['qb-lockpick']:Lockpick(function(success)
                if success then
                    callbackSuccess()
                else
                    callbackFail()
                end
            end, settings.amount, settings.time)
        end,
        custom = function(difficulty, callbackSuccess, callbackFail)
            -- Placeholder for custom minigame implementation
            Wait(1000)
            -- 70% success rate for testing
            if math.random(1, 100) <= 70 then
                callbackSuccess()
            else
                callbackFail()
            end
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
    end
end

-- ==========================================--
--             CORE FUNCTIONS                --
-- ==========================================--

-- Check if player has required item
local function hasRequiredItem(item)
    if not item then return true end -- No item required
    
    if Config.Systems.inventory == 'ox_inventory' then
        return exports.ox_inventory:Search('count', item) > 0
    elseif Config.Systems.inventory == 'qb-inventory' then
        local Player = QBCore.Functions.GetPlayerData()
        local hasItem = false
        
        for _, v in pairs(Player.items or {}) do
            if v.name == item and v.amount > 0 then
                hasItem = true
                break
            end
        end
        
        return hasItem
    else
        -- Custom inventory system
        -- Implement your own check here
        return true
    end
end

-- Function to determine if a bin needs lockpicking
local function needsLockpicking(entity)
    local model = GetEntityModel(entity)
    local modelName
    
    for _, name in pairs(Config.TrashModels) do
        if model == GetHashKey(name) then
            modelName = name
            break
        end
    end
    
    if modelName and Config.DifficultyTiers[modelName] then
        return Config.DifficultyTiers[modelName].requireItem ~= nil, 
               Config.DifficultyTiers[modelName].requireItem,
               Config.DifficultyTiers[modelName].difficulty
    end
    
    return false, nil, 'easy'
end

-- Function to search trash bin
local function searchTrashBin(entity)
    local coords = GetEntityCoords(entity)
    local binId = string.format("%d_%d_%d", math.floor(coords.x), math.floor(coords.y), math.floor(coords.z))
    
    -- Check if bin needs to be lockpicked
    local needsLock, requiredItem, difficulty = needsLockpicking(entity)
    
    if needsLock then
        -- Check if player has the required item
        if not hasRequiredItem(requiredItem) then
            useSystem('notify', {
                message = Config.Notifications.locked,
                type = 'error'
            })
            return
        end
        
        -- Start lockpicking minigame
        useSystem('minigame', difficulty, 
            function() -- Success
                -- Start searching animation after successful lockpicking
                searchTrashBinAfterLockpicking(entity, binId)
            end,
            function() -- Failed lockpicking
                -- Lose lockpick on failure (50% chance)
                if math.random(1, 100) <= 50 then
                    TriggerServerEvent('mns-trash:loseLockpick', requiredItem)
                end
                
                useSystem('notify', {
                    message = 'You failed to lockpick the dumpster',
                    type = 'error'
                })
            end
        )
    else
        -- No lockpicking needed, proceed with search
        searchTrashBinAfterLockpicking(entity, binId)
    end
end

-- Function to search bin after lockpicking (or if no lockpicking required)
local function searchTrashBinAfterLockpicking(entity, binId)
    -- Start searching animation
    useSystem('progressBar', 
        {
            duration = Config.Animation.duration,
            label = Config.Animation.label,
            scenario = Config.Animation.scenario
        },
        function() -- On complete
            -- Check if this is part of a route
            if activeRoute and currentBinIndex > 0 then
                -- Check if this bin is the active one in the route
                if activeRoute[currentBinIndex].entity == entity then
                    TriggerServerEvent('mns-trash:attemptLoot', binId, true) -- true = part of route
                    advanceTrashRoute()
                else
                    TriggerServerEvent('mns-trash:attemptLoot', binId, false)
                end
            else
                TriggerServerEvent('mns-trash:attemptLoot', binId, false)
            end
            
            -- Chance for NPC reaction
            handleNpcReactions(entity)
        end,
        function() -- On cancel
            ClearPedTasks(PlayerPedId())
            useSystem('notify', {
                message = Config.Notifications.canceled,
                type = 'error'
            })
        end
    )
end

-- Function to generate a trash route
local function generateTrashRoute()
    local playerPos = GetEntityCoords(PlayerPedId())
    local nearbyBins = {}
    
    -- Find nearby trash bins
    for _, bin in pairs(GetGamePool('CObject')) do
        for _, model in pairs(Config.TrashModels) do
            if GetEntityModel(bin) == GetHashKey(model) then
                local binPos = GetEntityCoords(bin)
                local dist = #(playerPos - binPos)
                if dist < Config.TrashRoutes.searchRadius then
                    table.insert(nearbyBins, {entity = bin, coords = binPos})
                end
            end
        end
    end
    
    -- Create route with min-max bins
    local count = math.random(Config.TrashRoutes.minBins, Config.TrashRoutes.maxBins)
    local route = {}
    
    for i=1, count do
        if #nearbyBins > 0 then
            local idx = math.random(1, #nearbyBins)
            table.insert(route, nearbyBins[idx])
            table.remove(nearbyBins, idx)
        end
    end
    
    -- Start route mission
    if #route > 0 then
        return route
    else
        return nil
    end
end

-- ==========================================--
--        RECYCLING CENTER NPC SETUP         --
-- ==========================================--
-- Create recycling NPC and blip
local function setupRecyclingCenter()
    -- Create blip for recycling center
    local blip = AddBlipForCoord(Config.RecyclingCenter.location)
    SetBlipSprite(blip, Config.RecyclingCenter.blip.sprite)
    SetBlipColour(blip, Config.RecyclingCenter.blip.color)
    SetBlipScale(blip, Config.RecyclingCenter.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.RecyclingCenter.blip.name)
    EndTextCommandSetBlipName(blip)
    
    -- Spawn recycling NPC
    local pedModel = GetHashKey(Config.RecyclingCenter.ped.model)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(10) end
    
    recyclingPed = CreatePed(4, pedModel, 
        Config.RecyclingCenter.location.x, 
        Config.RecyclingCenter.location.y, 
        Config.RecyclingCenter.location.z - 1.0, 
        Config.RecyclingCenter.ped.heading, 
        false, false)
    
    FreezeEntityPosition(recyclingPed, true)
    SetEntityInvincible(recyclingPed, true)
    SetBlockingOfNonTemporaryEvents(recyclingPed, true)
    
    -- Set NPC animation
    TaskStartScenarioInPlace(recyclingPed, Config.RecyclingCenter.ped.scenario, 0, true)
    
    -- Add target to NPC
    if Config.Systems.target == 'ox_target' then
        exports.ox_target:addLocalEntity(recyclingPed, {
            {
                name = 'recycling_center',
                label = 'Talk to Recycler',
                icon = 'fas fa-recycle',
                distance = 2.5,
                onSelect = function()
                    openRecyclingMenu()
                end
            }
        })
    elseif Config.Systems.target == 'qb-target' then
        exports['qb-target']:AddTargetEntity(recyclingPed, {
            options = {
                {
                    type = "client",
                    label = 'Talk to Recycler',
                    icon = 'fas fa-recycle',
                    action = function()
                        openRecyclingMenu()
                    end
                }
            },
            distance = 2.5
        })
    end
end

-- Open main recycling center menu
local function openRecyclingMenu()
    lib.registerContext({
        id = 'recycling_center_menu',
        title = 'Recycling Center',
        options = {
            {
                title = 'Crafting Station',
                description = 'Craft useful items from recycled materials',
                icon = 'fas fa-hammer',
                onSelect = function()
                    openCraftingMenu()
                end
            },
            {
                title = 'Collectibles',
                description = 'Trade your bottle cap collections',
                icon = 'fas fa-coins',
                onSelect = function()
                    openCollectiblesMenu()
                end
            },
            {
                title = 'Check Reputation',
                description = 'See your scavenging skill level',
                icon = 'fas fa-star',
                onSelect = function()
                    checkScavengerReputation()
                end
            }
        }
    })
    
    lib.showContext('recycling_center_menu')
end

-- Show player's scavenging reputation level
local function checkScavengerReputation()
    QBCore.Functions.TriggerCallback('mns-trash:getReputation', function(repData)
        if repData then
            useSystem('notify', {
                message = string.format("Scavenger Level: %d (%d points, %d%% to next level)", 
                    repData.level, repData.points, repData.progress),
                type = 'success'
            })
        end
    end)
end

-- Add targets to trash models
Citizen.CreateThread(function()
    -- Wait for resources to load
    Wait(2000)
    
    -- Setup recycling center
    setupRecyclingCenter()
    
    -- Add target to trash bins
    if Config.Systems.target == 'ox_target' then
        useSystem('target', Config.TrashModels, {
            {
                label = 'Search Trash Bin',
                icon = 'fas fa-search',
                distance = 1.5,
                onSelect = function(data)
                    searchTrashBin(data.entity)
                end
            },
            {
                label = 'Start Trash Route',
                icon = 'fas fa-route',
                distance = 1.5,
                onSelect = function(data)
                    if not Config.TrashRoutes.enabled then
                        useSystem('notify', {
                            message = "Trash routes are disabled.",
                            type = 'error'
                        })
                        return
                    end
                    
                    local route = generateTrashRoute()
                    if route then
                        startTrashRoute(route)
                    else
                        useSystem('notify', {
                            message = "Couldn't find enough trash bins nearby. Try a different area.",
                            type = 'error'
                        })
                    end
                end
            }
        })
    elseif Config.Systems.target == 'qb-target' then
        local options = {
            {
                type = "client",
                label = 'Search Trash Bin',
                icon = 'fas fa-search',
                action = function(entity)
                    searchTrashBin(entity)
                end,
            },
            {
                type = "client",
                label = 'Start Trash Route',
                icon = 'fas fa-route',
                action = function(entity)
                    if not Config.TrashRoutes.enabled then
                        useSystem('notify', {
                            message = "Trash routes are disabled.",
                            type = 'error'
                        })
                        return
                    end
                    
                    local route = generateTrashRoute()
                    if route then
                        startTrashRoute(route)
                    else
                        useSystem('notify', {
                            message = "Couldn't find enough trash bins nearby. Try a different area.",
                            type = 'error'
                        })
                    end
                end
            }
        }
        useSystem('target', Config.TrashModels, options)
    elseif Config.Systems.target == 'custom' then
        -- Placeholder for custom target implementation
        useSystem('target', Config.TrashModels, {})
    end
end)

-- ==========================================--
--             NPC REACTIONS                 --
-- ==========================================--
local function handleNpcReactions(entity)
    if not Config.NPCReactions.enabled then return end
    
    -- Check if NPC should react
    if math.random(1, 100) <= Config.NPCReactions.chanceToSpawn then
        -- Spawn a random NPC nearby
        local coords = GetEntityCoords(entity)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local spawnLocation = coords + vec3(
            math.random(-5, 5),
            math.random(-5, 5),
            0
        )
        
        -- Get heading pointing towards player
        local heading = GetHeadingFromVector_2d(playerCoords.x - spawnLocation.x, playerCoords.y - spawnLocation.y)
        
        -- Spawn NPC
        local pedModel = GetHashKey('a_m_m_business_01')
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do Wait(10) end
        
        local ped = CreatePed(4, pedModel, spawnLocation.x, spawnLocation.y, spawnLocation.z, heading, true, false)
        SetEntityAsMissionEntity(ped, true, true)
        
        -- Make NPC face player and say something
        TaskTurnPedToFaceEntity(ped, PlayerPedId(), -1)
        Wait(500)
        
        -- Choose random dialogue
        local dialogue = Config.NPCReactions.dialogues[math.random(1, #Config.NPCReactions.dialogues)]
        PlayPedAmbientSpeechNative(ped, dialogue, "SPEECH_PARAMS_FORCE_SHOUTED", 1)
        
        -- Check if NPC calls police
        if math.random(1, 100) <= Config.NPCReactions.policeCallChance then
            -- Make animation of calling phone
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_MOBILE", 0, true)
            Wait(5000)
            
            -- Alert police
            -- This would integrate with your police dispatch system
            TriggerServerEvent("police:server:policeAlert", "Suspicious Activity")
        else
            -- Just walk away angrily
            TaskWanderInArea(ped, coords.x, coords.y, coords.z, 15.0, 1.0, 10.0)
        end
        
        -- Delete NPC after 1 minute
        SetTimeout(60000, function()
            DeleteEntity(ped)
        end)
    end
end

-- ==========================================--
--             TRASH ROUTES                  --
-- ==========================================--
local function startTrashRoute(route)
    if activeRoute then
        useSystem('notify', {
            message = "You're already on a trash route",
            type = 'error'
        })
        return
    end
    
    activeRoute = route
    currentBinIndex = 1
    routeCompleted = false
    
    -- Create first blip
    local firstBin = activeRoute[currentBinIndex]
    if DoesBlipExist(routeBlip) then
        RemoveBlip(routeBlip)
    end
    
    routeBlip = AddBlipForCoord(firstBin.coords.x, firstBin.coords.y, firstBin.coords.z)
    SetBlipSprite(routeBlip, 420)
    SetBlipColour(routeBlip, 2)
    SetBlipScale(routeBlip, 0.8)
    SetBlipAsShortRange(routeBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Trash Bin")
    EndTextCommandSetBlipName(routeBlip)
    
    useSystem('notify', {
        message = string.format("Trash route started. Find %d bins to complete the route.", #activeRoute),
        type = 'success'
    })
end

local function advanceTrashRoute()
    if not activeRoute then return end
    
    currentBinIndex = currentBinIndex + 1
    
    -- Check if route is complete
    if currentBinIndex > #activeRoute then
        if DoesBlipExist(routeBlip) then
            RemoveBlip(routeBlip)
            routeBlip = nil
        end
        
        -- Route completed
        routeCompleted = true
        TriggerServerEvent('mns-trash:completeRoute')
        
        useSystem('notify', {
            message = "Trash route completed! You've earned a bonus reward.",
            type = 'success'
        })
        
        activeRoute = nil
        currentBinIndex = 0
        return
    end
    
    -- Update blip to next bin
    local nextBin = activeRoute[currentBinIndex]
    if DoesBlipExist(routeBlip) then
        RemoveBlip(routeBlip)
    end
    
    routeBlip = AddBlipForCoord(nextBin.coords.x, nextBin.coords.y, nextBin.coords.z)
    SetBlipSprite(routeBlip, 420)
    SetBlipColour(routeBlip, 2)
    SetBlipScale(routeBlip, 0.8)
    SetBlipAsShortRange(routeBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Trash Bin")
    EndTextCommandSetBlipName(routeBlip)
    
    useSystem('notify', {
        message = string.format("Bin %d/%d complete. Head to the next bin.", currentBinIndex-1, #activeRoute),
        type = 'inform'
    })
end

-- ==========================================--
--             COLLECTIBLES MENU             --
-- ==========================================--
local function openCollectiblesMenu()
    if not Config.Collectibles.enabled then return end
    
    -- Get player's collectibles from server
    QBCore.Functions.TriggerCallback('mns-trash:getCollectibles', function(collectibles)
        if collectibles then
            local collectiblesMenu = {
                id = 'trash_collectibles_menu',
                title = 'Collectibles',
                options = {}
            }
            
            -- Add all collectible sets
            for _, set in pairs(Config.Collectibles.rewards) do
                local hasAllItems = true
                local missingItems = {}
                local description = ""
                
                -- Check if player has all required items
                for _, itemId in pairs(set.required) do
                    if not collectibles[itemId] or collectibles[itemId] == 0 then
                        hasAllItems = false
                        table.insert(missingItems, itemId)
                    end
                end
                
                -- Create description
                if hasAllItems then
                    description = "Complete set! Click to claim reward: " .. set.reward.amount .. "x " .. set.reward.item
                else
                    description = "Missing: " .. table.concat(missingItems, ", ")
                end
                
                table.insert(collectiblesMenu.options, {
                    title = set.name,
                    description = description,
                    disabled = not hasAllItems,
                    onSelect = function()
                        if hasAllItems then
                            TriggerServerEvent('mns-trash:claimCollectibleReward', set.name)
                        end
                    end
                })
            end
            
            lib.registerContext(collectiblesMenu)
            lib.showContext('trash_collectibles_menu')
        end
    end)
end

-- ==========================================--
--             CRAFTING MENU                 --
-- ==========================================--
local function openCraftingMenu()
    if not Config.Crafting.enabled then return end
    
    local craftingMenu = {
        id = 'trash_crafting_menu',
        title = 'Trash Crafting',
        options = {}
    }
    
    for _, recipe in pairs(Config.Crafting.recipes) do
        local ingredients = ""
        for _, ingredient in pairs(recipe.items) do
            ingredients = ingredients .. ingredient.amount .. "x " .. ingredient.item .. " "
        end
        
        table.insert(craftingMenu.options, {
            title = recipe.name,
            description = 'Craft ' .. recipe.result.amount .. 'x ' .. recipe.result.item .. '\nRequires: ' .. ingredients,
            onSelect = function()
                TriggerServerEvent('mns-trash:craftItem', recipe.name)
            end
        })
    end
    
    lib.registerContext(craftingMenu)
    lib.showContext('trash_crafting_menu')
end

-- ==========================================--
--             COMMANDS                      --
-- ==========================================--
RegisterCommand('trashroute', function()
    if Config.TrashRoutes.enabled then
        -- Generate a random route of nearby dumpsters
        local playerPos = GetEntityCoords(PlayerPedId())
        local nearbyBins = {}
        
        -- Find nearby trash bins
        for _, bin in pairs(GetGamePool('CObject')) do
            for _, model in pairs(Config.TrashModels) do
                if GetEntityModel(bin) == GetHashKey(model) then
                    local binPos = GetEntityCoords(bin)
                    local dist = #(playerPos - binPos)
                    if dist < Config.TrashRoutes.searchRadius then
                        table.insert(nearbyBins, {entity = bin, coords = binPos})
                    end
                end
            end
        end
        
        -- Create route with min-max bins
        local count = math.random(Config.TrashRoutes.minBins, Config.TrashRoutes.maxBins)
        local route = {}
        
        for i=1, count do
            if #nearbyBins > 0 then
                local idx = math.random(1, #nearbyBins)
                table.insert(route, nearbyBins[idx])
                table.remove(nearbyBins, idx)
            end
        end
        
        -- Start route mission
        if #route > 0 then
            startTrashRoute(route)
        else
            useSystem('notify', {
                message = "Couldn't find enough trash bins nearby. Try a different area.",
                type = 'error'
            })
        end
    else
        useSystem('notify', {
            message = "Trash routes are disabled.",
            type = 'error'
        })
    end
end, false)

RegisterCommand('trashcollect', function()
    openCollectiblesMenu()
end, false)

RegisterCommand('trashcraft', function()
    openCraftingMenu()
end, false)

-- ==========================================--
--             EVENT HANDLERS                --
-- ==========================================--
-- Event handler for receiving trash route
RegisterNetEvent('mns-trash:startRoute', function(route)
    startTrashRoute(route)
end)

-- Event handler for alerting players
RegisterNetEvent('mns-trash:notify', function(data)
    useSystem('notify', data)
end)
