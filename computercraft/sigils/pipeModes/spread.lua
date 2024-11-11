local ItemDetailAndLimitCache = require('sigils.ItemDetailAndLimitCache')

---Get the amount of items from the origin item stack that can be moved to the
---destination item stack.
---@param originStack table ItemDetail of the origin item stack
---@param destStack table ItemDetail of the destination item stack
---@return number Number Number of items that can be moved. 0 if destination full or unstackable.
local function getAmountStackable(originStack, destStack)
  local isCompatibleItem = (
    destStack.name == originStack.name and
    destStack.nbt == nil and
    destStack.durability == nil and
    destStack.maxCount > originStack.count
  )

  if isCompatibleItem then
    return destStack.maxCount - originStack.count
  else
    return 0
  end
end

local function getTransferOrders (origin, destination, missingPeriphs, filter)
  local orders = {}

  local inventoryInfo = ItemDetailAndLimitCache.new(missingPeriphs)
  inventoryInfo:Fulfill({origin, destination})

  local emptySlotQueue = inventoryInfo:GetEmptySlots()

  for _, originSlot in pairs(origin.slots) do
    local originStack = inventoryInfo:GetItemDetail(originSlot) -- TODO: expecting this to be nil if the destSlot is empty. Is this true?
    if originStack then
      local toTransfer = originStack.count
      local actualTransferred = 0

      local numDestinationSlots = min(slot_count, #destination.slots)
      local transferAmount = floor(toTransfer / numDestinationSlots) -- we'll try to transfer this many items to each destination slot

      for writeHead=1, numDestinationSlots do
        local destSlot = destination.slots[writeHead]
        local destStack = inventoryInfo:GetItemDetail(destSlot) -- TODO: expecting this to be nil if the destSlot is empty. Is this true?

        if destStack or getAmountStackable(originStack, destStack) then
          local transferLimit = min(inventoryInfo:GetItemLimit(destSlot) - destStack.count, transferAmount)
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