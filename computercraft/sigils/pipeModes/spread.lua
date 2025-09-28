---Get the amount of items from the origin item stack that can be moved to the
---destination item stack.
---@param originStack table ItemDetail of the origin item stack
---@param destStack table ItemDetail of the destination item stack
---@param destItemLimit table Item limit of the destination item stack
---@return number Number Number of items that can be moved. 0 if destination full or unstackable.
local function getAmountStackable(originStack, destStack, destItemLimit)
  local isCompatibleItem = (
    destStack.name == originStack.name and
    destStack.nbt == nil and
    destStack.durability == nil
  )

  if isCompatibleItem then
    return math.min(destStack.maxCount - destStack.count, originStack.count, destItemLimit)
  else
    return 0
  end
end

---Get the transfer orders needed to spread items from the origin inventory throughout
---the destination inventory.
---
---This emulates the spreading behavior of Minecraft. For instance, if you drag
---a stack of items in your cursor into several slots on a chest, the stack is
---divided evenly, and each portion is added to the destination slots.
---The remainder remains in your cursor, in addition to any items that couldn't
---be fully transferred.
---
---This function uses slots in the origin inventory as the "cursor," which is
---why some remainder items stay in the origin inventory after a single pass.
---
---@param origin Group Origin group to transfer from
---@param destination Group Destination group to transfer to
---@param inventoryInfo table Inventory detail and item limit cache
---@param filter function Filter function that accepts the result of inventory.getItemDetail()
---@return TransferOrder[] transferOrders List of transfer orders
local function getTransferOrders (origin, destination, inventoryInfo, filter)
  local orders = {}

  for _, originSlot in pairs(inventoryInfo:GetSlotsWithMatchingItems(origin, filter)) do
    local originStack = inventoryInfo:GetItemDetail(originSlot)
    if originStack then
      local toTransfer = originStack.count
      local actualTransferred = 0

      local numDestinationSlots = math.min(#destination.slots, #destination.slots)
      local transferAmount = math.floor(toTransfer / numDestinationSlots) -- we'll try to transfer this many items to each destination slot
      if transferAmount == 0 then
        transferAmount = 1
      end

      for writeHead=1, numDestinationSlots do
        local destSlot = destination.slots[writeHead]
        local destStack = inventoryInfo:GetItemDetail(destSlot)
        local destItemLimit = inventoryInfo:GetItemLimit(destSlot)

        if destStack == nil or getAmountStackable(originStack, destStack, destItemLimit) > 0 then
          local transferLimit = transferAmount
          if destStack ~= nil then
            transferLimit = math.min(getAmountStackable(originStack, destStack, destItemLimit), transferAmount)
          end
          actualTransferred = actualTransferred + transferLimit

          table.insert(orders, {from=originSlot, to=destSlot, limit=transferLimit})
        end
      end
    end
  end

  return orders
end

return {
  getTransferOrders = getTransferOrders,
}