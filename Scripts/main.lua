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
ModVersion = "1.1.5"
DebugMode = true
IsModEnabled = true

if not IsModEnabled then
    LogInfo("The mod is disabled through IsModEnabled")
    return
end

-- ToDos
-- Add hotkey to pickup all items in stack except one
-- Add hotkey or ability to transfer picked up items directly to the inventory

LogInfo("Starting mod initialization")

--- Get Durability from ChangeableData
---@param ChangeableData FAbiotic_InventoryChangeableDataStruct?
---@return number durability 
local function GetDurability(ChangeableData)
    if not ChangeableData then return 100 end
    return ChangeableData.CurrentItemDurability_4_24B4D0E64E496B43FB8D3CA2B9D161C8
end

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
        LogDebug("TakeOne: CurrentStack: ",  currentStack)
        if currentStack < Cache.StackToTake then
            LogDebug("TakeOne: Not enough items in stack, skip")
            return
        end
        if currentStack > 1 then
            lastEnteredItemSlot:PickUpThisItemToCursor(true, Cache.StackToTake)
        else
            lastEnteredItemSlot:PickUpThisItemToCursor(false, 1)
        end
    end)
end

local function TakeHalf()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = Cache:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        local currentStack = lastEnteredItemSlot.ItemChangeableStats.CurrentStack_9_D443B69044D640B0989FD8A629801A49
        
        LogDebug("TakeHalf: CurrentStack: ", currentStack)
        if currentStack > 1 then
            -- Calculate half of the remaining items after StackToTake is already taken
            local remainingAfterFirstPick = currentStack - Cache.StackToTake
            
            if remainingAfterFirstPick <= 0 then
                -- All items would be taken by first pick, take one less to leave at least 1
                LogDebug("TakeHalf: Remaining after first pick is 0 or less, clamping")
                Cache.StackToTake = math.max(1, currentStack - 1)
            else
                local halfOfRemaining = math.floor(remainingAfterFirstPick / 2)
                
                if Cache.StackToTake < halfOfRemaining then
                    -- First pick would take less than half of remaining, so take exactly half
                    LogDebug("TakeHalf: Taking half of remaining")
                    Cache.StackToTake = halfOfRemaining
                else
                    -- First pick already takes at least half, so add half of what's left after first
                    local additionalHalf = math.floor((remainingAfterFirstPick - Cache.StackToTake) / 2)
                    LogDebug("TakeHalf: Additional half needed")
                    Cache.StackToTake = Cache.StackToTake + additionalHalf
                end
            end
            
            -- Clamp to ensure we don't take more than available, leaving at least 1
            if Cache.StackToTake >= currentStack then
                Cache.StackToTake = currentStack - 1
                LogDebug("TakeHalf: Clamped StackToTake: ", Cache.StackToTake)
            end
            
            -- Ensure minimum of 1
            Cache.StackToTake = math.max(1, Cache.StackToTake)
            
            LogDebug("TakeHalf: Final StackToTake: ", Cache.StackToTake)
            lastEnteredItemSlot:PickUpThisItemToCursor(true, Cache.StackToTake)
        end
    end)
end

local function HalveStack()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = Cache:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        local currentStack = lastEnteredItemSlot.ItemChangeableStats.CurrentStack_9_D443B69044D640B0989FD8A629801A49
        LogDebug("HalveStack: currentStack: ", currentStack)
        
        -- Only halve if we have at least 2 items (halving 1 item leaves 0.5, which floors to 0)
        if currentStack >= 2 then
            local inventory, slotIndex, changeableData = AFUtils.GetInventoryAndSlotIndexFromItemSlot(lastEnteredItemSlot)
            if inventory then
                -- Calculate how many to subtract (half of current stack)
                local stackToSub = math.floor(currentStack / 2) * -1
                
                LogDebug("HalveStack: Call AddToItemStack: " .. stackToSub)
                AFUtils.AddToItemStack(inventory, slotIndex, stackToSub, GetDurability(changeableData))
            end
        end
    end)
end

local function IncreaseStack()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = Cache:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        LogDebug("IncreaseStack: triggered")
        local inventory, slotIndex, changeableData = AFUtils.GetInventoryAndSlotIndexFromItemSlot(lastEnteredItemSlot)
        if inventory then
            LogDebug("IncreaseStack: Call AddToItemStack")
            AFUtils.AddToItemStack(inventory, slotIndex, 1, GetDurability(changeableData))
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
            local inventory, slotIndex, changeableData = AFUtils.GetInventoryAndSlotIndexFromItemSlot(lastEnteredItemSlot)
            if inventory then
                LogDebug("DecreaseStack: Call AddToItemStack")
                AFUtils.AddToItemStack(inventory, slotIndex, -1, GetDurability(changeableData))
            end
        end
    end)
end

local function DoubleStack()
    ExecuteInGameThread(function()
        local lastEnteredItemSlot = Cache:GetLastEnteredItemSlot()
        if not lastEnteredItemSlot then return end

        LogDebug("DoubleStack: triggered")
        local inventory, slotIndex, changeableData = AFUtils.GetInventoryAndSlotIndexFromItemSlot(lastEnteredItemSlot)
        if inventory then
            local stackToAdd = lastEnteredItemSlot.ItemChangeableStats.CurrentStack_9_D443B69044D640B0989FD8A629801A49
            if stackToAdd < 1 then
                stackToAdd = 1
            end
            LogDebug("DoubleStack: Call AddToItemStack: " .. stackToAdd)
            AFUtils.AddToItemStack(inventory, slotIndex, stackToAdd, GetDurability(changeableData))
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

if IsKeyBindRegistered(PickUpKey, PickUpModifiers) then
    error("The TakeOne key and modifiers is already used for something else!")
end
if IsKeyBindRegistered(TakeHalfKey, TakeHalfModifiers) then
    error("The TakeHalf key and modifiers is already used for something else!")
end
if IsKeyBindRegistered(IncreaseStackKey, IncreaseStackModifiers) then
    error("The IncreaseStack key and modifiers is already used for something else!")
end
if IsKeyBindRegistered(DecreaseStackKey, DecreaseStackModifiers) then
    error("The DecreaseStack key and modifiers is already used for something else!")
end
if IsKeyBindRegistered(DoubleStackKey, DoubleStackModifiers) then
    error("The DoubleStack key and modifiers is already used for something else!")
end
if IsKeyBindRegistered(HalveStackKey, HalveStackModifiers) then
    error("The HalveStack key and modifiers is already used for something else!")
end

-- Hooks --
ExecuteInGameThread(function()
    LogInfo("Initializing hooks")
    LoadAsset("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C")
    RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:OnMouseEnter", OnMouseEnter)
    RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:OnMouseLeave", OnMouseLeave)
    RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:PickUpThisItemToCursor", PickUpThisItemToCursor)
    RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:DropItemFromCursor", DropItemFromCursor)
    LogInfo("Hooks initialized")
end)

-- Key Binds --
RegisterKeyBind(PickUpKey, PickUpModifiers, TakeOne)
RegisterKeyBind(TakeHalfKey, TakeHalfModifiers, TakeHalf)
RegisterKeyBind(IncreaseStackKey, IncreaseStackModifiers, IncreaseStack)
RegisterKeyBind(DecreaseStackKey, DecreaseStackModifiers, DecreaseStack)
RegisterKeyBind(DoubleStackKey, DoubleStackModifiers, DoubleStack)
RegisterKeyBind(HalveStackKey, HalveStackModifiers, HalveStack)

LogInfo("Mod loaded successfully")