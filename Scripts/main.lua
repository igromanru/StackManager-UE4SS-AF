--[[
    Author: Igromanru
    Date: 04.09.2024
    Mod Name: Stack Manager
]]

-------------------------------------
-- Possible keys: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/key.md
-- See ModifierKey: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/modifierkey.md
-- ModifierKeys can be combined. e.g.: {ModifierKey.CONTROL, ModifierKey.ALT} = CTRL + ALT + L
local PickUpKey = Key.Q
local TakeHalfModifiers = { ModifierKey.SHIFT }
local IncreaseStackModifiers = { ModifierKey.CONTROL }
local DecreaseStackModifiers = { ModifierKey.ALT }
local CheatMode = true
-------------------------------------

------------------------------
-- Don't change code below --
------------------------------
local AFUtils = require("AFUtils.AFUtils")
local Cache = require("Cache")

ModName = "StackManager"
ModVersion = "1.0.0"
DebugMode = true
IsModEnabled = true

LogInfo("Starting mod initialization")

local function TakeOne()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = Cache:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        if Cache:IsSameSlot() then
            Cache.StackToTake = Cache.StackToTake + 1
        else
            Cache.StackToTake = 1
        end
        LogDebug("TakeOne: StackToTake: ",  Cache.StackToTake)
        local currentStack = lastEnteredItemSlot.ItemChangeableStats.CurrentStack_9_D443B69044D640B0989FD8A629801A49
        if currentStack <= Cache.StackToTake then
            LogDebug("TakeOne: CurrentStack: ",  currentStack)
            if CheatMode then
                local stackToAdd = (Cache.StackToTake + 1) - currentStack
                LogDebug("TakeOne: CheatMode->StackToAdd: ",  stackToAdd)
                if stackToAdd > 0 then
                    local inventory, slotIndex = AFUtils.GetInventoryAndSlotIndexFromItemSlot(lastEnteredItemSlot)
                    if inventory then
                        AFUtils.AddToItemStack(inventory, slotIndex, stackToAdd)
                    end
                end
            else
                LogDebug("TakeOne: Not enough items in stack, skip")
                return
            end
        end
        lastEnteredItemSlot:PickUpThisItemToCursor(true, Cache.StackToTake)
    end)
end

local function TakeHalf()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = Cache:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        local currentStack = lastEnteredItemSlot.ItemChangeableStats.CurrentStack_9_D443B69044D640B0989FD8A629801A49
        
        LogDebug("TakeHalf: CurrentStack: ", currentStack)
        if currentStack > 1 and Cache.StackToTake then
            local half = math.floor(currentStack / 2)
            LogDebug("TakeHalf: Value: ", half)
            LogDebug("TakeHalf: StackToTake: ", Cache.StackToTake)
            if Cache.StackToTake < half then
                Cache.StackToTake = half
            else
                local halfOfTheRest = (currentStack - Cache.StackToTake) / 2
                LogDebug("TakeHalf: halfOfTheRest: ", halfOfTheRest)
                Cache.StackToTake = math.floor(Cache.StackToTake + halfOfTheRest)
            end
            LogDebug("TakeHalf: New StackToTake: ", Cache.StackToTake)
            if Cache.StackToTake >= currentStack then
                Cache.StackToTake = currentStack - 1
                LogDebug("TakeHalf: Clamp StackToTake: ", Cache.StackToTake)
            end
            lastEnteredItemSlot:PickUpThisItemToCursor(true, Cache.StackToTake)
        end
    end)
end

local function IncreaseStack()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = Cache:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        local inventory, slotIndex = AFUtils.GetInventoryAndSlotIndexFromItemSlot(lastEnteredItemSlot)
        if inventory then
            AFUtils.AddToItemStack(inventory, slotIndex, 1)
        end
    end)
end

local function DecreaseStack()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = Cache:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        local currentStack = lastEnteredItemSlot.ItemChangeableStats.CurrentStack_9_D443B69044D640B0989FD8A629801A49
        if currentStack > 1 then
            local inventory, slotIndex = AFUtils.GetInventoryAndSlotIndexFromItemSlot(lastEnteredItemSlot)
            if inventory then
                AFUtils.AddToItemStack(inventory, slotIndex, -1)
            end
        end
    end)
end

local function OnMouseEnter(Context)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C

    LogDebug("[OnMouseEnter] called:")
    Cache:SetLastEnteredItemSlot(inventoryItemSlot)
    LogDebug("------------------------------")
end

local function PickUpThisItemToCursor(Context, DraggedBySplitStack, SplitStackSize)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C
    local draggedBySplitStack = DraggedBySplitStack:get()
    local splitStackSize = SplitStackSize:get()

    LogDebug("[PickUpThisItemToCursor] called:")
    LogDebug("DraggedBySplitStack:  ", draggedBySplitStack)
    LogDebug("SplitStackSize:  ", splitStackSize)
    Cache:SetLastPickUpItemSlot(inventoryItemSlot)
    LogDebug("------------------------------")
end

local function DropItemFromCursor(Context, DragDropOperation, Leftovers)
    -- local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C
    -- local dragDropOperation = DragDropOperation:get()
    local leftovers = Leftovers:get()

    LogDebug("[DropItemFromCursor] called:")
    LogDebug("Leftovers:  ", leftovers)
    if leftovers <= 0 then
        Cache:Reset()
    end
    LogDebug("------------------------------")
end

local ClientRestart = "/Script/Engine.PlayerController:ClientRestart"
local ClientRestartPreId = nil
local ClientRestartPostId = nil
local WasHooked = false
local function HookOnce()
    if not WasHooked then
        RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:OnMouseEnter", OnMouseEnter)
        RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:PickUpThisItemToCursor", PickUpThisItemToCursor)
        RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:DropItemFromCursor", DropItemFromCursor)
        WasHooked = true
    end
    if ClientRestartPreId and ClientRestartPostId then
        UnregisterHook(ClientRestart, ClientRestartPreId, ClientRestartPostId)
    end
end

if DebugMode then
    HookOnce()
end

-- Hooks --
ClientRestartPreId, ClientRestartPostId = RegisterHook(ClientRestart, function(Context, NewPawn)
    LogDebug("[ClientRestart] called:")
    HookOnce()
    LogDebug("------------------------------")
end)

-- Key Binds --
RegisterKeyBind(PickUpKey, TakeOne)
RegisterKeyBind(PickUpKey, TakeHalfModifiers, TakeHalf)
RegisterKeyBind(PickUpKey, IncreaseStackModifiers, IncreaseStack)
RegisterKeyBind(PickUpKey, DecreaseStackModifiers, DecreaseStack)

LogInfo("Mod loaded successfully")