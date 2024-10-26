local ItemDetailAndLimitCache = require('sigils.ItemDetailAndLimitCache')

local function getTotalDestSlotsAvailableForOriginSlot(inventoryInfo, originSlot, emptySlotQueue)
  local originItem = inventoryInfo:GetItemDetail(originSlot)
  local possibleSlotsFull = inventoryInfo:GetSlotsWithMatchingItems(destination, function (item)
    return (item.name == originItem.name and
      item.nbt == nil and
      item.durability == nil and
      item.maxCount > item.count
    )
  end)

  local emptySlotsAvailable = #emptySlotQueue

  return emptySlotsAvailable + #possibleSlotsFull
end

local function getTransferOrders (origin, destination, missingPeriphs, filter)
  local orders = {}

  local inventoryInfo = ItemDetailAndLimitCache.new(missingPeriphs)
  inventoryInfo:Fulfill({origin, destination})

  local emptySlotQueue = inventoryInfo:GetEmptySlots()

  for _, originSlot in pairs(origin.slots) do
    local totalDestSlotsAvailable = getTotalDestSlotsAvailableForOriginSlot(
      inventoryInfo, originSlot, emptySlotQueue)

    if totalDestSlotsAvailable == 0 then break end

    local itemsPerDestSlot = inventoryInfo:GetNumExistingItemsAt(originSlot) / totalDestSlotsAvailable
    local originStackSize = inventoryInfo:GetNumExistingItemsAt(originSlot)

    -- reserve a certain number of slots equal to origin stack size // total available dest slots
    for i=1, math.floor(originStackSize / totalDestSlotsAvailable) do
      table.insert(order, {from=originSlot, to=possibleDestSlot, limit=originStackSize})
    end

    -- if there's a remainder, reserve another slot and transfer the remainder
    local itemsRemaining = itemsPerDestSlot % totalDestSlotsAvailable
    table.insert(order, {from=originSlot, to=possibleDestSlot, limit=originStackSize})
    if itemsRemaining then
      table.insert(order, {from=originSlot, to=possibleDestSlot, limit=itemsRemaining})
    end

  end

  return orders
end

return {
  getTransferOrders = getTransferOrders,
}