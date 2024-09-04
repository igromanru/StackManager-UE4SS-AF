--[[
    Author: Igromanru
    Date: 04.09.2024
    Mod Name: Stack Manager
]]

-------------------------------------
-- Possible keys: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/key.md
-- See ModifierKey: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/modifierkey.md
-- ModifierKeys can be combined. e.g.: {ModifierKey.CONTROL, ModifierKey.ALT} = CTRL + ALT + L
local TakeOneKey = Key.Q
local TakeOneModifiers = {}
-------------------------------------

------------------------------
-- Don't change code below --
------------------------------
local AFUtils = require("AFUtils.AFUtils")
require("AFUtils.AFUtilsDebug")

ModName = "StackManager"
ModVersion = "1.0.0"
DebugMode = true
IsModEnabled = true

LogInfo("Starting mod initialization")

local LastInventoryItemSlot = nil ---@type UW_InventoryItemSlot_C?
local LastSlotIndex = -1
local PickedUpStack = 0

---@param InventoryItemSlot UW_InventoryItemSlot_C
---@param Leave boolean?
local function SetLastInventoryItemSlot(InventoryItemSlot, Leave)
    if not InventoryItemSlot then return end
    Leave = Leave == true

    if InventoryItemSlot.Empty or Leave then
        LastInventoryItemSlot = nil
    else
        LastInventoryItemSlot = InventoryItemSlot
    end
end

local function GetLastInventoryItemSlot()
    if LastInventoryItemSlot and LastInventoryItemSlot:IsValid() then
        return LastInventoryItemSlot
    end
    return nil
end


local function TakeOne()
    ExecuteInGameThread(function()
        local currentItemSlot = GetLastInventoryItemSlot()
        if not currentItemSlot then return end

        -- local currentStack = inventoryItemSlot.ItemChangeableStats.CurrentStack_9_D443B69044D640B0989FD8A629801A49
        currentItemSlot:PickUpThisItemToCursor(true, 1)
        currentItemSlot.RemoveGlowWhenHovered = false
        if currentItemSlot.ParentInventoryGrid:IsValid() then
            currentItemSlot.ParentInventoryGrid:HighlightSlot(currentItemSlot.SlotIndex, true)
        end
    end)
end

local function OnMouseEnter(Context)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C

    LogDebug("[OnMouseEnter] called:")
    SetLastInventoryItemSlot(inventoryItemSlot)
    -- AFUtils.LogInventoryItemSlot(inventoryItemSlot)
    AFUtils.LogInventoryChangeableDataStruct(inventoryItemSlot.ItemChangeableStats)
    LogDebug("------------------------------")
end

local function OnMouseLeave(Context)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C

    LogDebug("[OnMouseLeave] called:")
    SetLastInventoryItemSlot(inventoryItemSlot, true)
    AFUtils.LogInventoryChangeableDataStruct(inventoryItemSlot.ItemChangeableStats)
    LogDebug("------------------------------")
end

RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:OnMouseButtonUp", function(Context)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C

    LogDebug("[OnMouseButtonUp] called:")
    AFUtils.LogInventoryChangeableDataStruct(inventoryItemSlot.ItemInSlot.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313)
    LogDebug("------------------------------")
end)

local ClientRestart = "/Script/Engine.PlayerController:ClientRestart"
local ClientRestartPreId = nil
local ClientRestartPostId = nil
local WasHooked = false
local function HookOnce()
    if not WasHooked then
        RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:OnMouseEnter", OnMouseEnter)
        RegisterHook("/Game/Blueprints/Widgets/Inventory/W_InventoryItemSlot.W_InventoryItemSlot_C:OnMouseLeave", OnMouseLeave)
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
RegisterKeyBind(TakeOneKey, TakeOneModifiers, TakeOne)

LogInfo("Mod loaded successfully")