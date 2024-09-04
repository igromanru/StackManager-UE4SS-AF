
---@class DataHolder
local Cache = {
    StackToTake = 1
}

local LastEnteredItemSlot = nil ---@type UW_InventoryItemSlot_C?
local LastPickUpItemSlot = nil ---@type UW_InventoryItemSlot_C?

---@return UW_InventoryItemSlot_C?
function Cache:GetLastEnteredItemSlot()
    if LastEnteredItemSlot and LastEnteredItemSlot:IsValid() then
        return LastEnteredItemSlot
    end
    LastEnteredItemSlot = nil
    return nil
end

---@param ItemSlot UW_InventoryItemSlot_C|nil
function Cache:SetLastEnteredItemSlot(ItemSlot)
    if ItemSlot and ItemSlot:IsValid() and ItemSlot.ItemInSlot.ItemDataTable_18_BF1052F141F66A976F4844AB2B13062B.RowName ~= NAME_None then
        LastEnteredItemSlot = ItemSlot
    else
        LastEnteredItemSlot = nil
    end
end

---@param ItemSlot UW_InventoryItemSlot_C|nil
function Cache:SetLastPickUpItemSlot(ItemSlot)
    if ItemSlot and ItemSlot:IsValid() and ItemSlot.ItemInSlot.ItemDataTable_18_BF1052F141F66A976F4844AB2B13062B.RowName ~= NAME_None then
        LastPickUpItemSlot = ItemSlot
    else
        LastPickUpItemSlot = nil
    end
end

---@return UW_InventoryItemSlot_C?
function Cache:GetLastPickUpItemSlot()
    if LastPickUpItemSlot and LastPickUpItemSlot:IsValid() then
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
    LastEnteredItemSlot = nil
    LastPickUpItemSlot = nil
    self.StackToTake = 0
end

---@return boolean
function Cache:IsValid()
    return LastEnteredItemSlot ~= nil and LastPickUpItemSlot ~= nil
end

return Cache