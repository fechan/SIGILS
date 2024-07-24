local CacheMap = require('sigils.CacheMap')
local ItemDetailAndLimitCache = require('sigils.ItemDetailAndLimitCache')
local Utils = require('sigils.utils')

---An inventory slot on a peripheral in the network
---@class Slot
---@field periphId string CC peripheral ID
---@field slot number Slot number on the peripheral

---A request to transfer `limit` items from the `from` slot to the `to` slot
---@class TransferOrder
---@field from Slot Origin slot
---@field to Slot Desitnation slot
---@field limit number Number of items to transfer

local function popBestPossibleSlot (possibleSlotsEmpty, possibleSlotsFull)
  return table.remove(possibleSlotsFull, 1) or table.remove(possibleSlotsEmpty, 1)
end

---Get the transfer orders needed to transfer as many items as possible from the
---origin inventory to the destination
---@param origin Group Origin group to transfer from
---@param destination Group Destination group to transfer to
---@param missingPeriphs table Set of missing peripherals by ID
---@param filter function Filter function that accepts the result of inventory.getItemDetail()
---@return TransferOrder[] transferOrders List of transfer orders
local function getTransferOrders (origin, destination, missingPeriphs, filter)
  local orders = {}

  local inventoryInfo = ItemDetailAndLimitCache.new(missingPeriphs)
  inventoryInfo:Fulfill({origin, destination})

  local possibleSlotsEmpty = inventoryInfo:GetEmptySlots(destination)
  local shouldTransfer = inventoryInfo:GetSlotsWithMatchingItems(origin, filter)
  Utils.reverse(shouldTransfer) -- reverse list so table.remove(shouldTransfer) pops the head of the queue

  local possibleSlotsFullByItem = CacheMap.new()

  while #shouldTransfer > 0 do
    local originSlot = table.remove(shouldTransfer)

    local originItem = inventoryInfo:GetItemDetail(originSlot)

    -- originSlot.remainderStackSize is only defined if we tried to transfer this stack before but couldn't transfer all of it
    local originStackSize = originSlot.remainderStackSize or inventoryInfo:GetNumExistingItemsAt(originSlot)

    -- get possible slots where we can stack more items into it
    local possibleSlotsFull = possibleSlotsFullByItem:Get(originItem.name, function ()
      return inventoryInfo:GetSlotsWithMatchingItems(
        destination,
        function (item)
          return (item.name == originItem.name and
            item.nbt == nil and
            item.durability == nil and
            item.maxCount > item.count
          )
        end
      )
    end)

    -- start calculating how many of the item we can transfer
    local possibleDestSlot = popBestPossibleSlot(possibleSlotsEmpty, possibleSlotsFull)

    if possibleDestSlot ~= nil then
      local destSlotStackLimit = inventoryInfo:GetItemLimit(possibleDestSlot)
      local numExistingItemsAtDest = inventoryInfo:GetNumExistingItemsAt(possibleDestSlot)

      local transferLimit = destSlotStackLimit - numExistingItemsAtDest

      -- can I transfer all of the origin stack?
      if originStackSize <= transferLimit then -- if yes, transfer the whole stack and move on
        table.insert(orders, {from=originSlot, to=possibleDestSlot, limit=originStackSize})
        if originStackSize + numExistingItemsAtDest < destSlotStackLimit then -- if the destination slot can still hold items, put it back in the queue
          table.insert(possibleSlotsFull, 1, possibleDestSlot)
        end
      else -- if no, transfer the transferLimit and add the remainder of the stack to shouldTransfer
        table.insert(orders, {from=originSlot, to=possibleDestSlot, limit=transferLimit})
        table.insert(shouldTransfer, {
          periphId=originSlot.periphId,
          slot=originSlot.slot,
          remainderStackSize=originStackSize-transferLimit
        })
      end
    end
  end

  return orders
end

return {
  getTransferOrders = getTransferOrders,
}