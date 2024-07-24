local CacheMap = require('sigils.CacheMap')
local ItemDetailAndLimitCache = require('sigils.ItemDetailAndLimitCache')
local Concurrent = require('sigils.concurrent')
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

---Get slots in the given Group that match the filter.
---@param group Group Group to check for matching slots
---@param filter function Filter function accepting item details
---@param inventoryLists table Detailed inventory lists (as fulfilled by getDetailedInvList)
---@return Slot[] matchingSlots Slots with matching items
local function getSlotsWithMatchingItems (group, filter, inventoryLists)
  local matchingSlots = {}
  for i, slot in pairs(group.slots) do
    local list = inventoryLists[slot.periphId]
    if list ~= nil and list[slot.slot] and filter(list[slot.slot]) then
      table.insert(matchingSlots, slot)
    end
  end
  return matchingSlots
end


local function popBestPossibleSlot (possibleSlotsEmpty, possibleSlotsFull)
  return table.remove(possibleSlotsFull, 1) or table.remove(possibleSlotsEmpty, 1)
end

---Get a list of items in the given inventory peripheral, with all the details
---from getItemDetail.
---
---This runs all the getItemDetail() calls in parallel, so it should take about
---50 ms more or less for all of them, even if the inventory is really big.
---@param periphId string Peripheral ID of inventory
---@return table detailedInvList Detailed item list
local function getDetailedInvList (periphId, runner)
  runner = runner or Concurrent.create_runner(64)
  local detailedInvList = {} -- maps slot -> itemDetails
  local periph = peripheral.wrap(periphId)

  for slot, slotInfo in pairs(periph.list()) do
    runner.spawn(
      function ()
        detailedInvList[slot] = periph.getItemDetail(slot)
      end
    )
  end

  runner.run_until_done()
  return detailedInvList
end

local function getManyDetailedInvLists (periphs)
  local invLists = {} -- maps periphId -> detailed inventory list
  local runner = Concurrent.create_runner(64)

  for i,periphId in ipairs(periphs) do
    runner.spawn(
      function ()
        invLists[periphId] = getDetailedInvList(periphId)
      end
    )
  end

  runner.run_until_done()
  return invLists
end

local function getAllPeripheralIds (groups, missingPeriphs)
  local periphIdSet = {}
  for i, group in ipairs(groups) do
    for j, slot in ipairs(group.slots) do
      if missingPeriphs[slot.periphId] == nil then
        periphIdSet[slot.periphId] = true
      end
    end
  end

  local periphIdList = {}
  for periphId, _ in pairs(periphIdSet) do
    table.insert(periphIdList, periphId)
  end

  return periphIdList
end

---Get the transfer orders needed to transfer as many items as possible from the
---origin inventory to the destination
---@param origin Group Origin group to transfer from
---@param destination Group Destination group to transfer to
---@param missingPeriphs Table Set of missing peripherals by ID
---@param filter function Filter function that accepts the result of inventory.getItemDetail()
---@return TransferOrder[] transferOrders List of transfer orders
local function getTransferOrders (origin, destination, missingPeriphs, filter)
  local orders = {}

  local inventoryInfo = ItemDetailAndLimitCache.new()
  inventoryInfo:Fulfill({origin, destination})

  local inventoryLists = getManyDetailedInvLists(getAllPeripheralIds({origin, destination}, missingPeriphs))

  local possibleSlotsEmpty = inventoryInfo:GetEmptySlots(destination)
  local shouldTransfer = inventoryInfo:GetSlotsWithMatchingItems(origin, filter)
  Utils.reverse(shouldTransfer) -- reverse list so table.remove(shouldTransfer) pops the head of the queue

  local possibleSlotsFullByItem = CacheMap.new()

  while #shouldTransfer > 0 do
    local originSlot = table.remove(shouldTransfer)

    local originPeriphList = inventoryLists[originSlot.periphId]
    local originItem = originPeriphList[originSlot.slot]

    -- originSlot.remainderStackSize is only defined if we tried to transfer this stack before but couldn't transfer all of it
    local originStackSize = originSlot.remainderStackSize or inventoryInfo:GetNumExistingItemsAt(originSlot)

    -- get possible slots where we can stack more items into it
    local possibleSlotsFull = possibleSlotsFullByItem:Get(originItem.name, function ()
      return getSlotsWithMatchingItems(
        destination,
        function (item)
          return (item.name == originItem.name and
            item.nbt == nil and
            item.durability == nil and
            item.maxCount > item.count
          )
        end,
        inventoryLists
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