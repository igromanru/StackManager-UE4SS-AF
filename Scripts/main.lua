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

local LastItemCache = nil

local function TakeOne()
    
end

local function OnMouseEnter(Context)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C

    LogDebug("[OnMouseEnter] called:")
    AFUtils.LogInventoryItemSlot(inventoryItemSlot)
    LogDebug("------------------------------")
end

local function OnMouseLeave(Context)
    local inventoryItemSlot = Context:get() ---@type UW_InventoryItemSlot_C

    LogDebug("[OnMouseLeave] called:")
    AFUtils.LogInventoryItemSlot(inventoryItemSlot)
    LogDebug("------------------------------")
end

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