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
local IncreaseStackModifiers = { ModifierKey.SHIFT }
local DecreaseStackModifiers = { ModifierKey.CONTROL }
local TakeHalfModifiers = { ModifierKey.ALT }
local CheatMode = true
-------------------------------------

------------------------------
-- Don't change code below --
------------------------------
local AFUtils = require("AFUtils.AFUtils")
require("AFUtils.AFUtilsDebug")
local DataHolder = require("DataHolder")

ModName = "StackManager"
ModVersion = "1.0.0"
DebugMode = true
IsModEnabled = true

LogInfo("Starting mod initialization")

-- ---@param InventoryItemSlot UW_InventoryItemSlot_C
-- ---@param Leave boolean?
-- local function SetLastInventoryItemSlot(InventoryItemSlot, Leave)
--     if not InventoryItemSlot then return end
--     Leave = Leave == true

--     if InventoryItemSlot.Empty or Leave then
--         LastEnteredItemSlot = nil
--     else
--         LastEnteredItemSlot = InventoryItemSlot
--     end
-- end

local function TakeOne()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = DataHolder:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        if DataHolder:IsSameSlot() then
            DataHolder.StackToTake = DataHolder.StackToTake + 1
        else
            DataHolder.StackToTake = 1
        end
        LogDebug("TakeOne: StackToTake: ",  DataHolder.StackToTake)
        local currentStack = lastEnteredItemSlot.ItemChangeableStats.CurrentStack_9_D443B69044D640B0989FD8A629801A49
        if currentStack <= DataHolder.StackToTake then
            LogDebug("TakeOne: CurrentStack: ",  currentStack)
            if CheatMode then
                local stackToAdd = (DataHolder.StackToTake + 1) - currentStack
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
        lastEnteredItemSlot:PickUpThisItemToCursor(true, DataHolder.StackToTake)
    end)
end

local function TakeHalf()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = DataHolder:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        local currentStack = lastEnteredItemSlot.ItemChangeableStats.CurrentStack_9_D443B69044D640B0989FD8A629801A49
        if currentStack > 2 then
            local half = currentStack / 2
            LogDebug("TakeHalf: CurrentStack: ", currentStack)
            LogDebug("TakeHalf: Value: ", half)
            lastEnteredItemSlot:PickUpThisItemToCursor(true, half)
        end
    end)
end

local function IncreaseStack()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = DataHolder:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        
    end)
end

local function DecreaseStack()
    ExecuteInGameThread(function()
        
    end)
end

local function OnMouseEnter(Context)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C

    LogDebug("[OnMouseEnter] called:")
    -- AFUtils.LogInventoryChangeableDataStruct(inventoryItemSlot.ItemChangeableStats)
    DataHolder:SetLastEnteredItemSlot(inventoryItemSlot)
    LogDebug("------------------------------")
end

local function OnMouseLeave(Context)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C

    LogDebug("[OnMouseLeave] called:")
    AFUtils.LogInventoryChangeableDataStruct(inventoryItemSlot.ItemChangeableStats)
    LogDebug("------------------------------")
end

local function PickUpThisItemToCursor(Context, DraggedBySplitStack, SplitStackSize)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C
    local draggedBySplitStack = DraggedBySplitStack:get()
    local splitStackSize = SplitStackSize:get()

    LogDebug("[PickUpThisItemToCursor] called:")
    LogDebug("DraggedBySplitStack:  ", draggedBySplitStack)
    LogDebug("SplitStackSize:  ", splitStackSize)
    -- AFUtils.LogInventoryChangeableDataStruct(inventoryItemSlot.ItemChangeableStats)
    DataHolder:SetLastPickUpItemSlot(inventoryItemSlot)
    LogDebug("------------------------------")
end

local function DropItemFromCursor(Context, DragDropOperation, Leftovers)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C
    -- local dragDropOperation = DragDropOperation:get()
    local leftovers = Leftovers:get()

    LogDebug("[DropItemFromCursor] called:")
    LogDebug("Leftovers:  ", leftovers)
    if leftovers <= 0 then
        DataHolder:Reset()
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
        -- RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:OnMouseLeave", OnMouseLeave)
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
    -- LogDebug("[ClientRestart] called:")
    HookOnce()
    -- LogDebug("------------------------------")
end)

-- Key Binds --
RegisterKeyBind(PickUpKey, TakeOne)
RegisterKeyBind(PickUpKey, TakeHalfModifiers, TakeHalf)
RegisterKeyBind(PickUpKey, IncreaseStackModifiers, IncreaseStack)
RegisterKeyBind(PickUpKey, DecreaseStackModifiers, DecreaseStack)

LogInfo("Mod loaded successfully")