--[[
    Author: Igromanru
    Date: 04.09.2024
    Mod Name: Stack Manager
]]

---------- Configurations ----------
-- Possible keys: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/key.md
-- See ModifierKey: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/modifierkey.md
-- ModifierKeys can be combined. e.g.: {ModifierKey.CONTROL, ModifierKey.ALT} = CTRL + ALT + Q
-- Take One
local PickUpKey = Key.Q
local PickUpModifiers = {}
local CheatMode = false
-- Take Half
local TakeHalfKey = PickUpKey
local TakeHalfModifiers = { ModifierKey.SHIFT }
-- Increase Stack
local IncreaseStackKey = PickUpKey
local IncreaseStackModifiers = { ModifierKey.CONTROL }
-- Decrease Stack
local DecreaseStackKey = PickUpKey
local DecreaseStackModifiers = { ModifierKey.ALT }
-- Double Stack
local DoubleStackKey = PickUpKey
local DoubleStackModifiers = { ModifierKey.CONTROL, ModifierKey.SHIFT }
-- Halve Stack
local HalveStackKey = PickUpKey
local HalveStackModifiers = { ModifierKey.ALT, ModifierKey.SHIFT }
-------------------------------------

------------------------------
-- Don't change code below --
------------------------------
local AFUtils = require("AFUtils.AFUtils")
local Cache = require("Cache")

ModName = "StackManager"
ModVersion = "1.1.0"
DebugMode = true
IsModEnabled = true

if not IsModEnabled then
    LogInfo("The mod is disabled through IsModEnabled")
    return
end

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
                        LogDebug("TakeOne: AddToItemStack: slotIndex: " .. slotIndex .. " stackToAdd: " .. stackToAdd)
                        if AFUtils.AddToItemStack(inventory, slotIndex, stackToAdd) then
                            LogDebug("TakeOne: AddToItemStack: Success")
                        end
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
        if currentStack > 1 then
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

        LogDebug("IncreaseStack: triggered")
        local inventory, slotIndex = AFUtils.GetInventoryAndSlotIndexFromItemSlot(lastEnteredItemSlot)
        if inventory then
            LogDebug("IncreaseStack: Call AddToItemStack")
            AFUtils.AddToItemStack(inventory, slotIndex, 1)
        end
    end)
end

local function DecreaseStack()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = Cache:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        local currentStack = lastEnteredItemSlot.ItemChangeableStats.CurrentStack_9_D443B69044D640B0989FD8A629801A49
        LogDebug("DecreaseStack: currentStack: ", currentStack)
        if currentStack > 1 then
            local inventory, slotIndex = AFUtils.GetInventoryAndSlotIndexFromItemSlot(lastEnteredItemSlot)
            if inventory then
                LogDebug("DecreaseStack: Call AddToItemStack")
                AFUtils.AddToItemStack(inventory, slotIndex, -1)
            end
        end
    end)
end

local function DoubleStack()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = Cache:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        LogDebug("DoubleStack: triggered")
        local inventory, slotIndex = AFUtils.GetInventoryAndSlotIndexFromItemSlot(lastEnteredItemSlot)
        if inventory then
            local stackToAdd = lastEnteredItemSlot.ItemChangeableStats.CurrentStack_9_D443B69044D640B0989FD8A629801A49
            if stackToAdd < 1 then
                stackToAdd = 1
            end
            LogDebug("DoubleStack: Call AddToItemStack: " .. stackToAdd)
            AFUtils.AddToItemStack(inventory, slotIndex, stackToAdd)
        end
    end)
end

local function HalveStack()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = Cache:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        local currentStack = lastEnteredItemSlot.ItemChangeableStats.CurrentStack_9_D443B69044D640B0989FD8A629801A49
        LogDebug("HalveStack: currentStack: ", currentStack)
        if currentStack > 2 then
            local inventory, slotIndex = AFUtils.GetInventoryAndSlotIndexFromItemSlot(lastEnteredItemSlot)
            if inventory then
                local stackToSub = math.floor(currentStack / 2) * -1
                LogDebug("HalveStack: Call AddToItemStack: " .. stackToSub)
                AFUtils.AddToItemStack(inventory, slotIndex, stackToSub)
            end
        end
    end)
end

local function OnMouseEnter(Context)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C

    -- LogDebug("[OnMouseEnter] called:")
    Cache:SetLastEnteredItemSlot(inventoryItemSlot)
    -- LogDebug("------------------------------")
end

local function OnMouseLeave(Context)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C

    -- LogDebug("[OnMouseEnter] called:")
    Cache:SetLastEnteredItemSlot(nil)
    -- LogDebug("------------------------------")
end

local function PickUpThisItemToCursor(Context, DraggedBySplitStack, SplitStackSize)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C
    local draggedBySplitStack = DraggedBySplitStack:get()
    local splitStackSize = SplitStackSize:get()

    -- LogDebug("[PickUpThisItemToCursor] called:")
    -- LogDebug("DraggedBySplitStack:  ", draggedBySplitStack)
    -- LogDebug("SplitStackSize:  ", splitStackSize)
    Cache:SetLastPickUpItemSlot(inventoryItemSlot)
    -- LogDebug("------------------------------")
end

local function DropItemFromCursor(Context, DragDropOperation, Leftovers)
    -- local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C
    -- local dragDropOperation = DragDropOperation:get()
    local leftovers = Leftovers:get()

    -- LogDebug("[DropItemFromCursor] called:")
    -- LogDebug("Leftovers:  ", leftovers)
    if leftovers <= 0 then
        -- LogDebug("Reset Cache")
        Cache:Reset()
    end
    -- LogDebug("------------------------------")
end

local ClientRestart = "/Script/Engine.PlayerController:ClientRestart"
local ClientRestartPreId = nil
local ClientRestartPostId = nil
local WasHooked = false
local function HookOnce()
    if not WasHooked then
        RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:OnMouseEnter", OnMouseEnter)
        RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:OnMouseLeave", OnMouseLeave)
        RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:PickUpThisItemToCursor", PickUpThisItemToCursor)
        RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:DropItemFromCursor", DropItemFromCursor)
        WasHooked = true
    end
    if ClientRestartPreId and ClientRestartPostId then
        UnregisterHook(ClientRestart, ClientRestartPreId, ClientRestartPostId)
        ClientRestartPreId = nil
        ClientRestartPostId = nil
    end
end

if IsKeyBindRegistered(PickUpKey, PickUpModifiers) then
    error("The TakeOne key and modifirers is already used for something else!")
end
if IsKeyBindRegistered(TakeHalfKey, TakeHalfModifiers) then
    error("The TakeHalf key and modifirers is already used for something else!")
end
if IsKeyBindRegistered(IncreaseStackKey, IncreaseStackModifiers) then
    error("The IncreaseStack key and modifirers is already used for something else!")
end
if IsKeyBindRegistered(DecreaseStackKey, DecreaseStackModifiers) then
    error("The DecreaseStack key and modifirers is already used for something else!")
end
if IsKeyBindRegistered(DoubleStackKey, DoubleStackModifiers) then
    error("The DoubleStack key and modifirers is already used for something else!")
end
if IsKeyBindRegistered(HalveStackKey, HalveStackModifiers) then
    error("The HalveStack key and modifirers is already used for something else!")
end

-- Hooks --
ClientRestartPreId, ClientRestartPostId = RegisterHook(ClientRestart, function(Context, NewPawn)
    LogDebug("[ClientRestart] called:")
    HookOnce()
    LogDebug("------------------------------")
end)

-- Key Binds --
RegisterKeyBind(PickUpKey, PickUpModifiers, TakeOne)
RegisterKeyBind(TakeHalfKey, TakeHalfModifiers, TakeHalf)
RegisterKeyBind(IncreaseStackKey, IncreaseStackModifiers, IncreaseStack)
RegisterKeyBind(DecreaseStackKey, DecreaseStackModifiers, DecreaseStack)
RegisterKeyBind(DoubleStackKey, DoubleStackModifiers, DoubleStack)
RegisterKeyBind(HalveStackKey, HalveStackModifiers, HalveStack)

if DebugMode then
    HookOnce()
end

LogInfo("Mod loaded successfully")