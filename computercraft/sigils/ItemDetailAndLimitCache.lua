local Concurrent = require('sigils.concurrent')

---A class for storing itemDetail and itemLimits of slots in slot groups
---@class ItemDetailAndLimitCache
local ItemDetailAndLimitCache = {}

local function getSlotId (slot)
  return slot.periphId .. '/' .. slot.slot
end

---Create a new ItemDetailAndLimitCache
---@param missingPeriphs set Set of missing peripheral IDs
---@param initialMap table Initial map of slot IDs and their item limits/details
---@return ItemDetailAndLimitCache itemDetailAndLimitCache New cache
function ItemDetailAndLimitCache.new (missingPeriphs, initialMap)
  local o = {
    map = initialMap or {},
    missingPeriphs = missingPeriphs or {},
  }

  ---Return true if the slot is connected to the network
  ---(i.e. its peripheral is not missing)
  ---@param slot Slot slot to check for
  ---@return boolean isConnected True if connected
  function o:slotConnected (slot)
    return not o.missingPeriphs[slot.periphId]
  end

  ---Fulfills the item details for each slot in the given groups in parallel
  ---@param groups Group[] List of groups to fulfill item limits and details for
  function o:Fulfill(groups)
    local runner = Concurrent.create_runner(64)

    for _, group in pairs(groups) do
      for _, slot in pairs(group.slots) do
        if o:slotConnected(slot) then
          -- make a itemDetail and itemLimit data structure in the map for the slot if it's not there already
          local slotId = getSlotId(slot)
          if o.map[slotId] == nil then
            o.map[slotId] = {}
          end

          -- fulfill itemDetail
          runner.spawn(
            function ()
              local periph = peripheral.wrap(slot.periphId)
              if periph and o.map[slotId].itemDetail == nil then
                o.map[slotId].itemDetail = periph.getItemDetail(slot.slot)
              end
            end
          )

          -- fulfill itemLimit
          runner.spawn(
            function ()
              local periph = peripheral.wrap(slot.periphId)
              if periph and o.map[slotId].itemLimit == nil then
                o.map[slotId].itemLimit = periph.getItemLimit(slot.slot)
              end
            end
          )
        end
      end
    end

    runner.run_until_done()
  end

  ---Get the item limit of the given Slot
  ---(This is max number of items holdable by the slot, regardless of whether
  ---an item is in the slot)
  ---@param slot Slot Slot to get item limit for
  ---@return number itemLimit Slot item limit
  function o:GetItemLimit (slot)
    return o.map[getSlotId(slot)].itemLimit
  end

  ---Get the item detail of the given Slot, or nil if there's nothing in the Slot
  ---@param slot Slot Slot to get item details for
  ---@return table itemDetail Item details in slot
  function o:GetItemDetail (slot)
    return o.map[getSlotId(slot)].itemDetail
  end

  ---Get a Group's empty slots
  ---@param group Group Group to get empty slots of
  ---@return Slot[] emptySlots List of empty slots
  function o:GetEmptySlots (group)
    local emptySlots = {}

    for _, slot in pairs(group.slots) do
      if o:slotConnected(slot) and o:GetItemDetail(slot) == nil then
        table.insert(emptySlots, slot)
      end
    end

    return emptySlots
  end

  ---Get slots in the given Group that match the filter.
  ---@param group Group Group to check for matching slots
  ---@param filter function Filter function accepting item details
  ---@return Slot[] matchingSlots Slots with matching items
  function o:GetSlotsWithMatchingItems (group, filter)
    local matchingSlots = {}

    for _, slot in pairs(group.slots) do
      if o:slotConnected(slot) then
        local itemDetail = o:GetItemDetail(slot)
        if itemDetail and filter(itemDetail) then
          table.insert(matchingSlots, slot)
        end
      end
    end

    return matchingSlots
  end

  ---Get the number of items in the given slot
  ---@param slot Slot Slot to get number of items in
  ---@return number count Number of items in the slot
  function o:GetNumExistingItemsAt (slot)
    local itemDetail = o:GetItemDetail(slot)
    if itemDetail then
      return itemDetail.count
    end
    return 0
  end

  return o
end

return ItemDetailAndLimitCache