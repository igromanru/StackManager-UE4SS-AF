
---@class ItemSlot
---@field ItemInSlot FAbiotic_InventoryItemSlotStruct?
---@field ItemChangeableStats FAbiotic_InventoryChangeableDataStruct?
local ItemSlot = {
    ItemInSlot = nil,
    ItemChangeableStats = nil
}

function ItemSlot:Set(ItemInSlot, ItemChangeableStats)
    self.ItemInSlot = ItemInSlot
    self.ItemChangeableStats = ItemChangeableStats
end


function ItemSlot:Reset()
    self.ItemInSlot = nil
    self.ItemChangeableStats = nil
end

function ItemSlot:IsValid()
    return self.ItemInSlot and self.ItemChangeableStats
end

return ItemSlot