
---@class DataHolder
local Cache = {
    StackToTake = 1
}

local LastEnteredItemSlot = nil ---@type UW_InventoryItemSlot_C?
local LastPickUpItemSlot = nil ---@type UW_InventoryItemSlot_C?

---@return UW_InventoryItemSlot_C?
function Cache:GetLastEnteredItemSlot()
    if LastEnteredItemSlot and LastEnteredItemSlot:IsValid() and not LastEnteredItemSlot.Empty then
        return LastEnteredItemSlot
    end
    LastEnteredItemSlot = nil
    return nil
end

---@param ItemSlot UW_InventoryItemSlot_C|nil
function Cache:SetLastEnteredItemSlot(ItemSlot)
    if ItemSlot and ItemSlot:IsValid() then
        LastEnteredItemSlot = ItemSlot
    else
        LastEnteredItemSlot = nil
    end
end

---@param ItemSlot UW_InventoryItemSlot_C|nil
function Cache:SetLastPickUpItemSlot(ItemSlot)
    if ItemSlot and ItemSlot:IsValid() then
        LastPickUpItemSlot = ItemSlot
    else
        LastPickUpItemSlot = nil
    end
end

---@return UW_InventoryItemSlot_C?
function Cache:GetLastPickUpItemSlot()
    if LastPickUpItemSlot and LastPickUpItemSlot:IsValid() and not LastPickUpItemSlot.Empty then
        return LastPickUpItemSlot
    end
    LastPickUpItemSlot = nil
    return nil
end

---@return boolean
function Cache:IsSameSlot()
    local lastEnteredItemSlot = self:GetLastEnteredItemSlot()
    local lastPickUpItemSlot = self:GetLastPickUpItemSlot()
    return lastEnteredItemSlot ~= nil and lastPickUpItemSlot ~= nil and lastEnteredItemSlot:GetAddress() == lastPickUpItemSlot:GetAddress()
end

function Cache:Reset()
    LastPickUpItemSlot = nil
    self.StackToTake = 0
end

---@return boolean
function Cache:IsValid()
    return LastEnteredItemSlot ~= nil and LastPickUpItemSlot ~= nil
end

return Cache